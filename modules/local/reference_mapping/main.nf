process REFERENCE_MAPPING{
  tag "$name"
      
  input:
  tuple val(name),path(sam_percent)

  output:
  path "${name}.samtools.cvg.tsv"    , emit: samtools_cvg_tsvs
  path "${name}.sorted.bam"          , emit: sorted_bam
  path "${name}.sorted.bam.bai"      , emit: sorted_bam_bai
  path "versions.yml"                , emit: versions


  script:
  """
  samtools view -S -b ${name}.sam -o ${name}.bam
  samtools sort ${name}.bam > ${name}.sorted.bam
  samtools index ${name}.sorted.bam
  samtools flagstat ${name}.sorted.bam
  samtools coverage ${name}.sorted.bam -o ${name}.samtools.cvg.tsv

  cat <<-END_VERSIONS > versions.yml
  "${task.process}":
      samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
  END_VERSIONS

  """
}