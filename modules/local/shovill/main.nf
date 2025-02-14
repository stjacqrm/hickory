process SHOVILL {
    tag "$name"
    label 'process_high'

    input:
    tuple val(name), path(cleaned_reads)

    output:
    tuple val(name), path("shovill.corrections")                   , emit: corrections
    tuple val(name), path("shovill.log")                           , emit: log
    tuple val(name), path("{skesa,spades,megahit,velvet}.fasta")   , emit: raw_contigs
    tuple val(name), path("contigs.{fastg,gfa,LastGraph}")         , optional:true, emit: gfa
    path("${name}.fasta")                                          , emit: contigs
    path "versions.yml"                                            , emit: versions


    """
    shovill --cpus ${task.cpus} --ram ${task.memory.toGiga()}  --outdir . --R1 ${cleaned_reads[0]} --R2 ${cleaned_reads[1]} --force
    mv contigs.fa ${name}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        shovill: \$(echo \$(shovill --version 2>&1) | sed 's/^.*shovill //')
    END_VERSIONS
    """
}
