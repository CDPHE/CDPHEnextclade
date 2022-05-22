version 1.0

workflow CDPHEnextclade {

    input {
        File multifasta
        String sample_id
        String out_dir
    }

    call nextclade {
        input:
            multifasta = multifasta,
            sample_id = sample_id
    }
    
    call pangolin {
        input:
            multifasta = multifasta,
            sample_id = sample_id
    }

    call transfer {
      input:
          out_dir = out_dir,
          nextclade_json = nextclade.nextclade_json,
          auspice_json = nextclade.auspice_json,
          nextclade_csv = nextclade.nextclade_csv,
          pangolin_lineage = pangolin.lineage
    }

    output {
        String nextclade_version = nextclade.nextclade_version
        File nextclade_json = nextclade.nextclade_json
        File auspice_json = nextclade.auspice_json
        File nextclade_csv = nextclade.nextclade_csv
        String pangolin_version = pangolin.pangolin_version
        File pangolin_lineage = pangolin.lineage
    }
}

task nextclade {

    input {
        File multifasta
        String sample_id
    }

    command {

        nextclade --version > VERSION
        nextclade dataset get --name='sars-cov-2' --reference='MN908947' --output-dir='data/sars-cov-2'
        nextclade run --input-fasta ${multifasta} --input-dataset data/sars-cov-2 --output-json ${sample_id}_nextclade.json --output-csv ${sample_id}_nextclade.csv --output-tree ${sample_id}_nextclade.auspice.json
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
        disks: "local-disk 500 HDD"
    }
}

task pangolin {

    input {
        File multifasta
        String sample_id
    }

    command {
        pangolin --version > VERSION
        pangolin --skip-scorpio --outfile ${sample_id}_pangolin_lineage_report.csv ${multifasta}
    }

    output {
        String pangolin_version = read_string("VERSION")
        File lineage = "${sample_id}_pangolin_lineage_report.csv"
    }

    runtime {
        docker: "staphb/pangolin"
        memory: "16 GB"
        cpu: 4
        disks: "local-disk 500 HDD"
    }
}

task transfer {
    input {
        String out_dir
        File auspice_json
        File nextclade_csv
        File nextclade_json
        File pangolin_lineage
    }

    String outdir = sub(out_dir, "/$", "")

    command <<<

        gsutil -m cp ~{nextclade_json} ~{outdir}/nextclade_out/
        gsutil -m cp ~{auspice_json} ~{outdir}/nextclade_out/
        gsutil -m cp ~{nextclade_csv} ~{outdir}/nextclade_out/
        gsutil -m cp ~{pangolin_lineage} ~{outdir}/pangolin_out/

    >>>

    runtime {
        docker: "theiagen/utility:1.0"
        memory: "16 GB"
        cpu: 4
        disks: "local-disk 100 SSD"
    }
}
