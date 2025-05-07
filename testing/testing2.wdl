version 1.0

workflow testing2 {
    input {
        # Array[Int] chromosomes = range(1, 23)
        Int chromosome = 21
        Map[String, File] plink_files
        String path_to_plink = "/Bulk/Exome Sequences/Population level exome OQFE variants, PLINK format - final release/"
    }
    call echo_plink_files {
        input:
            plink_files = plink_files
    }
    output {
        String outputstr = echo_plink_files.out
    }
}
task echo_plink_files {
    input {
        Array[File] plink_files
    }
    command <<<
        echo "${plink_files}"
    >>>
    output {
        String out = read_string(stdout())
    }
}