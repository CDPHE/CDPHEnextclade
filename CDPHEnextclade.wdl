version 1.0

workflow CDPHEnextclade {

    input {
        File multifasta
        String sample_id
        String out_dir
        File covid_genome
        File covid_gff
    }

    call nextclade {
        input:
            multifasta = multifasta,
            ref = covid_genome,
            gff = covid_gff,
            sample_id = sample_id
    }

    call transfer {
      input:
          out_dir = out_dir,
          nextclade_json = nextclade.nextclade_json,
          auspice_json = nextclade.auspice_json,
          nextclade_csv = nextclade.nextclade_csv
    }

    output {
        String nextclade_version = nextclade.nextclade_version
        File nextclade_json = nextclade.nextclade_json
        File auspice_json = nextclade.auspice_json
        File nextclade_csv = nextclade.nextclade_csv
    }
}

task nextclade {

    input {
        File multifasta
        File ref
        File gff
        String sample_id
    }

    command {
        nextclade --version > VERSION
        nextclade --input-fasta ${multifasta} --input-root-seq ${ref} --input-gene-map ${gff} --output-json ${sample_id}_nextclade.json --output-csv ${sample_id}_nextclade.csv --output-tree ${sample_id}_nextclade.auspice.json
    }

    output {
        String nextclade_version = read_string("VERSION")
        File nextclade_json = "${sample_id}_nextclade.json"
        File auspice_json = "${sample_id}_nextclade.auspice.json"
        File nextclade_csv = "${sample_id}_nextclade.csv"
    }

    runtime {
        docker: "nextstrain/nextclade"
        memory: "16 GB"
        cpu: 4
        disks: "local-disk 200 HDD"
    }
}

task transfer {
    input {
        String out_dir
        File auspice_json
        File nextclade_csv
        File nextclade_json
    }

    String outdir = sub(out_dir, "/$", "")

    command <<<

        gsutil -m cp ~{nextclade_json} ~{outdir}/nextclade_out/
        gsutil -m cp ~{auspice_json} ~{outdir}/nextclade_out/
        gsutil -m cp ~{nextclade_csv} ~{outdir}/nextclade_out/

    >>>

    runtime {
        docker: "theiagen/utility:1.0"
        memory: "16 GB"
        cpu: 4
        disks: "local-disk 10 SSD"
    }
}
