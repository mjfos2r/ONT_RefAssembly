version 1.0
import "../structs/Structs.wdl"
import "../tasks/Rebaler.wdl" as REBALER
import "../tasks/Dorado.wdl" as DORADO
import "ONT_FixBamHeader.wdl" as FixBAM
import "../tasks/Quast.wdl" as QUAST

workflow ONT_RefAssemble {

    meta {
        description: "Generate reference guided assemblies of ONT reads using Rebaler"
    }
    parameter_meta {
        reads: "fastq of reads to assemble"
        reference: "reference genome to assemble against"

    }

    input {
        String sample_id
        File? merged_bam
        File? sanitized_bam_in
        File reads
        File reference_fa
        File reference_gff
        String args
    }

    # First things first, we need to make sure the bam header for our merged bam is sanitized. this is very important.
    Boolean have_sanitized = defined(sanitized_bam_in)
    Boolean have_merged = defined(merged_bam)

    # if neither are provided, fail out.
    if (!have_sanitized && !have_merged) {
        call Fail as FailNone { input: msg = "Must provide either sanitized_bam or merged_bam to proceed. Please check your inputs and try again!" }
    }

    # if only merged is provided, clean this bam file.
    # also coerce merged bam since the type checker is complaining.
    if (!have_sanitized && have_merged) { call FixBAM.ONT_FixBamHeaderRG as FixBAM { input: input_bam = select_first([merged_bam]) } }

    # Pick the sanitized bam to output back to the DataTable:
    File sanitized_bam_final = select_first([sanitized_bam_in, FixBAM.sanitized_bam])

    # call our first task/workflow
    call REBALER.Assemble {
        input:
            reads = reads,
            reference = reference_fa,
    }

    call DORADO.Dorado {
        input:
            reads = sanitized_bam_final,
            draft_asm = Assemble.assembly,
            sample_id = sample_id
    }

    # Make an Array[File] so our raw and polished assemblies are both in the final quast report.
    Array[File] assemblies = [ Assemble.assembly, Dorado.polished ]

    # now run quast on em
    call QUAST.Quast {
        input:
            assemblies = assemblies,
            reference_fa = reference_fa,
            reference_gff = reference_gff,
            reads = reads
    }

    output {
        File rebaler_assembly_raw = Assemble.assembly
        File rebaler_assembly_polished = Dorado.polished
        File rebaler_quast_data = Quast.data
        File rebaler_quast_icarus = Quast.icarus
        File rebaler_quast_report = Quast.report
        File sanitized_bam = sanitized_bam_final
    }
}

task Fail {
    input { String msg }
    command <<<
        echo "~{msg}" 1>&2
        exit 1
    >>>
}