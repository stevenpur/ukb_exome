version 1.0

workflow exome_qc {
    input {
        Array[File] plink_files
        File ukb_exome_90pct10dp_variants
    }

    # First, organize files by chromosome
    call organize_files {
        input:
            all_files = plink_files
    }

    # Now process each chromosome's files
    scatter (chr_files in organize_files.chromosome_file_sets) {
        call filter_90pct10dp {
            input:
                plink_bed = chr_files.bed,
                plink_bim = chr_files.bim,
                plink_fam = chr_files.fam,
                exclude_variants = ukb_exome_90pct10dp_variants
        }
    }

    output {
        Array[File] filtered_beds = filter_90pct10dp.filtered_bed
        Array[File] filtered_bims = filter_90pct10dp.filtered_bim
        Array[File] filtered_fams = filter_90pct10dp.filtered_fam
    }
}

task organize_files {
    input {
        Array[File] all_files
    }

    command <<<
        # Create a directory for organized files
        mkdir -p organized

        # Process each file
        for file in ~{sep=' ' all_files}; do
            # Extract chromosome number from filename (assuming format contains _c{NUMBER}_)
            chr=$(basename "$file" | grep -o 'c[0-9]\+' | grep -o '[0-9]\+')
            if [ ! -z "$chr" ]; then
                # Create chromosome directory if it doesn't exist
                mkdir -p "organized/chr$chr"
                # Create symlinks to files based on extension
                if [[ "$file" == *.bed ]]; then
                    ln -s "$file" "organized/chr$chr/data.bed"
                elif [[ "$file" == *.bim ]]; then
                    ln -s "$file" "organized/chr$chr/data.bim"
                elif [[ "$file" == *.fam ]]; then
                    ln -s "$file" "organized/chr$chr/data.fam"
                fi
            fi
        done

        # Create JSON output
        echo "{" > file_sets.json
        echo "  \"file_sets\": [" >> file_sets.json
        first=true
        for chr_dir in organized/chr*; do
            if [ -d "$chr_dir" ]; then
                if [ "$first" = true ]; then
                    first=false
                else
                    echo "," >> file_sets.json
                fi
                echo "    {" >> file_sets.json
                echo "      \"bed\": \"$chr_dir/data.bed\"," >> file_sets.json
                echo "      \"bim\": \"$chr_dir/data.bim\"," >> file_sets.json
                echo "      \"fam\": \"$chr_dir/data.fam\"" >> file_sets.json
                echo "    }" >> file_sets.json
            fi
        done
        echo "  ]" >> file_sets.json
        echo "}" >> file_sets.json
    >>>

    output {
        Array[Object] chromosome_file_sets = read_json("file_sets.json").file_sets
    }

    runtime {
        docker: "ubuntu:20.04"
        memory: "2G"
        cpu: "1"
    }
}

task filter_90pct10dp {
    input {
        File plink_bed
        File plink_bim
        File plink_fam
        File exclude_variants
    }

    command <<<
        # Extract prefix by removing .bed suffix while keeping path
        bed_path="~{plink_bed}"
        exclude_variants_path="~{exclude_variants}"
        prefix="${bed_path%.bed}"
        plink --bfile "${prefix}" \
              --exclude "${exclude_variants_path}" \
              --keep-allele-order \
              --make-bed \
              --out "filtered"
    >>>

    output {
        File filtered_bed = "filtered.bed"
        File filtered_bim = "filtered.bim"
        File filtered_fam = "filtered.fam"
    }

    runtime {
        docker: "quay.io/biocontainers/plink:1.90b6.21--h516909a_0"
        memory: "8G"
        cpu: "4"
    }
}