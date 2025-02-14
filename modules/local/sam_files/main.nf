process SAM_FILES {
  tag "$name"
  label 'process_medium'

  input:
  tuple val(name), path(reads_files_minimap), path(ref_minimap)

  output:
  tuple val(name), path("${name}.sam"), emit: sam_percent
  path "versions.yml"                 , emit: versions


  script:
  """
  minimap2 -ax sr ${ref_minimap} ${reads_files_minimap[0]} ${reads_files_minimap[1]} > ${name}.sam

  cat <<-END_VERSIONS > versions.yml
  "${task.process}":
      minimap2: \$(minimap2 --version 2>&1)
  END_VERSIONS

  """
}