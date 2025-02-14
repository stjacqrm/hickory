//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    VALIDATE INPUTS
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowHickory.initialise(params, log)

// Check input path parameters to see if they exist
def checkPathParamList = [ 
    params.input, params.multiqc_config
]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//   CONFIG FILES
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    IMPORT LOCAL MODULES/SUBWORKFLOWS
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
include { INPUT_CHECK       } from '../subworkflows/local/input_check'
include { CENTROID          } from '../modules/local/centroid/main'
include { CLEANREADS        } from '../modules/local/cleanreads/main'
include { GENERATE_REPORT   } from '../modules/local/generate_report/main'
include { PREPROCESS        } from '../modules/local/preprocess/main'
include { REFERENCE_MAPPING } from '../modules/local/reference_mapping/main'
include { SAM_FILES         } from '../modules/local/sam_files/main'
include { TRIMM             } from '../modules/local/trimm/main'
include { SHOVILL           } from '../modules/local/shovill/main'
include { FASTQC            } from '../modules/local/fastqc/main'


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    IMPORT NF-CORE MODULES/SUBWORKFLOWS
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
include { MULTIQC                     } from '../modules/nf-core/modules/multiqc/main'
include { QUAST                       } from '../modules/nf-core/modules/quast/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/modules/custom/dumpsoftwareversions/main'

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    RUN MAIN WORKFLOW
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// Info required for completion email and summary
def multiqc_report = []

workflow HICKORY {

    ch_ref_minimap = Channel.empty()
    ch_versions = Channel.empty()

    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    INPUT_CHECK (ch_input)
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    // MODULE: Run preprocess
    PREPROCESS (INPUT_CHECK.out.reads)

    // MODULE: Run trimm
    TRIMM (PREPROCESS.out.read_files_trimming)
    ch_versions = ch_versions.mix(TRIMM.out.versions.first())

    // MODULE: Run cleanreads
    CLEANREADS (TRIMM.out.trimmed_reads)
    ch_versions = ch_versions.mix(CLEANREADS.out.versions.first())

    // MODULE: Run FastQC
    FASTQC (CLEANREADS.out.reads)
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    // MODULE: Run Shovill
    SHOVILL (CLEANREADS.out.cleaned_reads)
    ch_versions = ch_versions.mix(SHOVILL.out.versions.first())

    // MODULE: Run centroid
    CENTROID (SHOVILL.out.contigs.collect().ifEmpty([]))
    ch_versions = ch_versions.mix(CENTROID.out.versions.first())

    // MODULE: Run sam_files
    //ref_minimap = centroid.out.ref_minimap
    SAM_FILES (CLEANREADS.out.reads_files_minimap.combine(CENTROID.out.ref_minimap))
    ch_versions = ch_versions.mix(SAM_FILES.out.versions.first())

    // MODULE: Run reference_mapping
    REFERENCE_MAPPING (SAM_FILES.out.sam_percent)
    ch_versions = ch_versions.mix(REFERENCE_MAPPING.out.versions.first())

    // MODULE: Run generate_report
    GENERATE_REPORT (REFERENCE_MAPPING.out.samtools_cvg_tsvs.collect())

    CUSTOM_DUMPSOFTWAREVERSIONS (ch_versions.unique().collectFile(name: 'collated_versions.yml'))

    // MODULE: MultiQC
    workflow_summary    = WorkflowHickory.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(Channel.from(ch_multiqc_config))
    ch_multiqc_files = ch_multiqc_files.mix(ch_multiqc_custom_config.collect().ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))

    MULTIQC (ch_multiqc_files.collect())
    multiqc_report = MULTIQC.out.report.toList()
    ch_versions    = ch_versions.mix(MULTIQC.out.versions)
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    COMPLETION EMAIL AND SUMMARY
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    THE END
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

