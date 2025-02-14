process CLEANREADS {
  tag "$name"
  label 'process_high'

  input:
  tuple val(name), path(trimmed_reads) 

  output:
  tuple val(name), path("${name}{_1,_2}.clean.fastq.gz"), emit: cleaned_reads
  tuple val(name), path("${name}{_1,_2}.clean.fastq.gz"), emit: reads
  tuple val(name), path("${name}{_1,_2}.clean.fastq.gz"), emit: reads_files_minimap
  path "${name}.phix.stats.txt"                         , emit: phix_cleanning_stats
  path "${name}.adapters.stats.txt"                     , emit: adapter_cleanning_stats
  path "versions.yml"                                   , emit: versions


  script:
  """
  repair.sh in1=${trimmed_reads[0]} in2=${trimmed_reads[1]} out1=${name}.paired_1.fastq.gz out2=${name}.paired_2.fastq.gz
  bbduk.sh -Xmx"${task.memory.toGiga()}g" in1=${name}.paired_1.fastq.gz in2=${name}.paired_2.fastq.gz out1=${name}.rmadpt_1.fastq.gz out2=${name}.rmadpt_2.fastq.gz ref=/bbmap/resources/adapters.fa stats=${name}.adapters.stats.txt ktrim=r k=23 mink=11 hdist=1 tpe tbo
  bbduk.sh -Xmx"${task.memory.toGiga()}g" in1=${name}.rmadpt_1.fastq.gz in2=${name}.rmadpt_2.fastq.gz out1=${name}_1.clean.fastq.gz out2=${name}_2.clean.fastq.gz outm=${name}.matched_phix.fq ref=/bbmap/resources/phix174_ill.ref.fa.gz k=31 hdist=1 stats=${name}.phix.stats.txt
  
  cat <<-END_VERSIONS > versions.yml
  "${task.process}":
      bbmap: \$(bbversion.sh)
  END_VERSIONS

  """
}