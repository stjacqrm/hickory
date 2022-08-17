process PREPROCESS {
  tag {"Preprocessing Reads"}

  input:
  tuple val(name), path(reads)

  output:
  tuple val(name), path("${name}_*.fastq.gz"), emit: reads                 //fastqc
  tuple val(name), path("${name}_*.fastq.gz"), emit: read_files_trimming   //trimm

  script:
 
    file=new File("${reads[0]}")
    name = file.name.split("\\_", 2)[0]

    """
    mv ${reads[0]} ${name}_R1.fastq.gz
    mv ${reads[1]} ${name}_R2.fastq.gz
    """
}