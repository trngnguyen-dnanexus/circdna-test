// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from '../functions'

// TODO nf-core: If in doubt look at other nf-core/modules to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/software
//               You can also ask for help via your pull request or on the #modules channel on the nf-core Slack workspace:
//               https://nf-co.re/join

// TODO nf-core: A module file SHOULD only define input and output files as command-line parameters.
//               All other parameters MUST be provided as a string i.e. "options.args"
//               where "params.options" is a Groovy Map that MUST be provided via the addParams section of the including workflow.
//               Any parameters that need to be evaluated in the context of a particular sample
//               e.g. single-end/paired-end data MUST also be defined and evaluated appropriately.
// TODO nf-core: Software that can be piped together SHOULD be added to separate module files
//               unless there is a run-time, storage advantage in implementing in this way
//               e.g. it's ok to have a single module for bwa to output BAM instead of SAM:
//                 bwa mem | samtools view -B -T ref.fasta
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

params.options = [:]
options        = initOptions(params.options)

process AMPLICONARCHITECT_AMPLICONARCHITECT {
    tag "$meta.id"
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    // TODO nf-core: List required Conda package(s).
    //               Software MUST be pinned to channel (i.e. "bioconda"), version (i.e. "1.10").
    //               For Conda, the build (i.e. "h9402c20_2") must be EXCLUDED to support installation on different operating systems.
    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    //conda (params.enable_conda ? "conda-forge::python=2.7 bioconda::pysam=0.16.0.1 flask=1.1.2 cython=0.29.22 numpy=1.15.4 scipy=1.1.3 conda-forge::matplotlib=2.2.5" : null)
    conda (params.enable_conda ? "conda-forge::python=2.7 bioconda::pysam=0.17.0 flask=1.1.2 cython=0.29.15 numpy=1.16.5 scipy=1.2.1 conda-forge::matplotlib=2.2.5 mosek::mosek=8.0.60" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE"
    } else {
        container "quay.io/biocontainers/YOUR-TOOL-HERE"
    }

    input:
    tuple val(meta), path(bam), path(bai), path(bed)

    output:
    tuple val(meta), path("*"), emit: bam
    path "*.version.txt"          , emit: version
    tuple val(meta), path("*.log"), emit: log
    tuple val(meta), path("*cycles.txt"), optional: true, emit: cycles
    tuple val(meta), path("*graph.txt"), optional: true, emit: graph

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    AA_DATA_REPO=${params.aa_data_repo}
    MOSEKLM_LICENSE_FILE=${params.mosek_license_dir}
    # output=${params.outdir}/ampliconarchitect
    AmpliconArchitect.py --bam $bam --bed $bed --ref "GRCh38" --out "${prefix}"

    AmpliconArchitect.py --version > ${software}.version.txt
    """
}