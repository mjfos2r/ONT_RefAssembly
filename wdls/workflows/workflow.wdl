version 1.0
import "../structs/Structs.wdl"
import "../tasks/Tasks.wdl" as Tasks

workflow ONT_RefAssemble {

    meta {
        description: "Generate reference guided assemblies of ONT reads using Rebaler"
    }
    parameter_meta {
        reads: "fastq of reads to assemble"
        reference: "reference genome to assemble against"

    }

    input {
        File merged_bam
        File reads
        File reference
    }

    # call our first task/workflow
    call Tasks.Assemble {
        input:
            reads = reads,
            reference = reference,
    }
    ## pass the output of first task into our second task/workflow.
    #call Tasks.DoradoAlign {
    #    input:
    #        input_file = Assemble.assembly,
    #}
#
    #call Tasks.DoradoPolish {
    #    input:
    #        input_file = FirstTask.output_file,
    #}

    output {
        File output_file = Assemble.assembly # WIP
    }
}