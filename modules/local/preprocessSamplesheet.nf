process PREPROCESS_SAMPLESHEET {
    label 'process_single'

    input:
    tuple val(instrument), val(sampleSheetFilename), val(directories)

    output:
    path("samplesheet.csv"), emit: samplesheet

    when:
    task.ext.when == null || task.ext.when

    script:

    """
    champlain.R -i ${instrument} -s ${sampleSheetFilename} -o samplesheet.csv -d ${directories}
    """
}

