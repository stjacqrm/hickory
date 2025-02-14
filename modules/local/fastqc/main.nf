process FASTQC {
  tag "$name"
  label 'process_medium'

  input:
  tuple val(name), path(reads)

  output:
  tuple val(name), path("*.html"), emit: html
  tuple val(name), path("*.zip") , emit: zip
  path  "versions.yml"           , emit: versions
  
  script:
  """
  fastqc -q  ${reads}

  cat <<-END_VERSIONS > versions.yml
  "${task.process}":
      fastqc: \$( fastqc --version | sed -e "s/FastQC v//g" )
  END_VERSIONS
  """
}