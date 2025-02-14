process TRIMM {
  tag "$name"
  label 'process_high'

  input:
  tuple val(name), path(read_files_trimming)

  output:
  tuple val(name), path("${name}_trimmed{_1,_2}.fastq.gz"), emit: trimmed_reads
  path "${name}.trim.stats.txt"                           , emit: trimmomatic_stats
  path "versions.yml"                                     , emit: versions


  script:
  """
  java -jar /Trimmomatic-0.39/trimmomatic-0.39.jar PE -threads ${task.cpus} ${read_files_trimming} -baseout ${name}.fastq.gz SLIDINGWINDOW:${params.windowsize}:${params.qualitytrimscore} MINLEN:${params.minlength} 2> ${name}.trim.stats.txt
  mv ${name}*1P.fastq.gz ${name}_trimmed_1.fastq.gz
  mv ${name}*2P.fastq.gz ${name}_trimmed_2.fastq.gz

  cat <<-END_VERSIONS > versions.yml
  "${task.process}":
      trimmomatic: \$(trimmomatic -version)
  END_VERSIONS
  """
}