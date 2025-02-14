process CENTROID {
  tag {"Determining Reference Genome"}
  label 'process_high'
  
  input:
  path(contigs)

  output:
  path("*_centroid_ref.fasta"), emit: centroid_out
  path("*_centroid_ref.fasta"), emit: ref_minimap
  path "versions.yml"         , emit: versions

  script:
  """
  mkdir assemblies
  mv *.fasta ./assemblies
  centroid.py ./assemblies
  ref=\$(cat centroid_out.txt | awk -F. '{print \$1}')
  ln ./assemblies/\${ref}.fasta ./\${ref}_centroid_ref.fasta

  cat <<-END_VERSIONS > versions.yml
  "${task.process}":
      centroid: 1.0.0
  END_VERSIONS
  """
}