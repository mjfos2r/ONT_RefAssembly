version 1.0
import "../structs/Structs.wdl"

task Assemble {
    meta {
        # task-level metadata can go here
        description: "Assemble reads to a specified reference genome using Rebaler."
    }

    parameter_meta {
        # metadata about each input/output parameter can go here
        reads: "fastq file of reads to assemble."
        reference: "fasta file of reference genome to assemble against."
    }

    input {
        String sample_id
        File reads
        File reference
        RuntimeAttr? runtime_attr_override
    }

    # other "private" declarations can be made here
    Int disk_size = 365 + 2 * ceil(size(reads, "GB"))

    command <<<
        set -euo pipefail
        shopt -s failglob

        NPROC=$(cat /proc/cpuinfo | awk '/^processor/{print}' | wc -l)

        filename="$(basename ~{reads})"

        if [[ "~{reads}" == *.gz ]]; then
            zcat "~{reads}" > reads.fq
        else
            mv "~{reads}" reads.fq
        fi

        mkdir outdir
        echo "Beginning rebaler assembly."
        echo "Using ~{reference} as reference."
        echo "outputting consensus to ${outpath}"
        rebaler -t "$NPROC" ~{reference} reads.fq > "~{sample_id}_rebaler.fasta"
        echo "Finished rebaler assembly."

    >>>

    output {
        File assembly = "~{sample_id}_rebaler.fasta"
    }
    RuntimeAttr default_attr = object {
        cpu_cores:          16,
        mem_gb:             64,
        disk_gb:            disk_size,
        boot_disk_gb:       50,
        preemptible_tries:  0,
        max_retries:        1,
        docker:             "mjfos2r/rebaler:latest"
    }
    RuntimeAttr runtime_attr = select_first([runtime_attr_override, default_attr])
    runtime {
        cpu:                    select_first([runtime_attr.cpu_cores,         default_attr.cpu_cores])
        memory:                 select_first([runtime_attr.mem_gb,            default_attr.mem_gb]) + " GiB"
        disks: "local-disk " +  select_first([runtime_attr.disk_gb,           default_attr.disk_gb]) + " SSD"
        bootDiskSizeGb:         select_first([runtime_attr.boot_disk_gb,      default_attr.boot_disk_gb])
        preemptible:            select_first([runtime_attr.preemptible_tries, default_attr.preemptible_tries])
        maxRetries:             select_first([runtime_attr.max_retries,       default_attr.max_retries])
        docker:                 select_first([runtime_attr.docker,            default_attr.docker])
    }
}