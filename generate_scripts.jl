using GraphChallenge

const TYPES_OUTPUT_DIR = Dict(
    Array{Int64, 2} => "matrix",
    SparseMatrixCSC{Int64, Int64} => "sparse_matrix",
    InterblockEdgeCountStinger => "stinger",
    InterblockEdgeCountDictDict => "dictdict",
    InterblockEdgeCountVectorDict => "vectordict",
    InterblockEdgeCountSQLite => "sqlite",
    SparseUpdateIBEM => "sparse_update",
)

function create_directories(directories)
    curdir = dirname(@__FILE__)
    for dirname in directories
        dir = joinpath(curdir, dirname)
        if !isdir(dir)
            mkdir(dir)
        end
    end
end

function qsub_header(nthread, job, type_name, num_nodes, useremail="", queue="")
    header = """#PBS -N $(job)_$(num_nodes)_$(type_name)
    #PBS -l nodes=1:ppn=$(nthread)
    #PBS -l walltime=12:00:00
    #PBS -l mem=160gb
    #PBS -m abe
    #PBS -M $useremail
    #PBS -q $queue
    #PBS -j oe
    module load julia/0.6.2
    export JULIA_NUM_THREADS=$(nthread)
    """
    header
end

#Generate all the kronecker graphs
function runbench(nthreads, num_nodes, types; qsub=true, useremail="", queue="")
    #Create the directories
    create_directories(["input", "output", "scripts"])
    for dir in ("output", "scripts")
        create_directories(
            ["$dir/$(TYPES_OUTPUT_DIR[T])" for T in types]
        )
    end

    curdir = dirname(@__FILE__)
    outputdir = joinpath(curdir, "output")
    scriptdir = joinpath(curdir, "scripts")
    benchfile = joinpath(curdir, "bench.jl")
    masterscripthandle = open(joinpath(scriptdir, "master_script"), "w")
    for T in types
        for nthread in nthreads
            for n in num_nodes
                output_file = joinpath(outputdir, TYPES_OUTPUT_DIR[T], "$(TYPES_OUTPUT_DIR[T])_$(n)_$nthread")
                script = """#!/bin/bash
                $(if qsub qsub_header(nthread, "gc", TYPES_OUTPUT_DIR[T], n, useremail, queue) else "" end)
                julia -O3 --check-bounds=no -e 'include("$benchfile"); bench($T, $(n), "$(output_file)")'
                """
                open(joinpath(scriptdir, TYPES_OUTPUT_DIR[T], "$(TYPES_OUTPUT_DIR[T])_$n_$(nthread)"), "w") do f
                    write(f, script)
                end
                if qsub
                    run(`qsub $(joinpath(scriptdir, TYPES_OUTPUT_DIR[T], "$(TYPES_OUTPUT_DIR[T])_$n_$(nthread)"))`)
                else
                    write(masterscripthandle, """bash $(joinpath(scriptdir, TYPES_OUTPUT_DIR[T], "$(TYPES_OUTPUT_DIR[T])_$n"))\n""")
                end
            end
        end
    end
end
