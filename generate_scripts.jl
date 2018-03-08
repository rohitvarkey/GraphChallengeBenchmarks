using GraphChallenge

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
    header = """#PBS -N $(job)_$(type_name)_$(num_nodes)
    #PBS -l nodes=1:ppn=$(nthread)
    #PBS -l walltime=12:00:00
    #PBS -l mem=160gb
    #PBS -m abe
    #PBS -M $useremail
    #PBS -q $queue
    #PBS -j oe
    module load gcc/5.3.0
    module load julia/6.2.0
    export JULIA_NUM_THREADS=$(nthread)
    """
    header
end

#Generate all the kronecker graphs
function runbench(nthreads, num_nodes, types; qsub=true, useremail="", queue="")
    #Create the directories
    create_directories(["input", "output", "scripts"])
    types_output_dir = Dict(
        Array{Int64, 2} => "matrix",
        InterblockEdgeCountStinger => "stinger",
        InterblockEdgeCountDictDict => "dictdict",
        InterblockEdgeCountVectorDict => "vectordict",
        InterblockEdgeCountSQLite => "sqlite"
    )
    for dir in ("output", "scripts")
        create_directories(
            ["$dir/$(types_output_dir[T])" for T in types]
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
                output_file = joinpath(outputdir, types_output_dir[T], "$(types_output_dir[T])_$n")
                script = """#!/bin/bash
                $(if qsub qsub_header(nthread, "gc", T, n, useremail, queue) else "" end)
                julia -O3 --check-bounds=no -e 'include("$benchfile"); bench($T, $(n), "$(output_file)")'
                """
                open(joinpath(scriptdir, types_output_dir[T], "$(types_output_dir[T])_$n"), "w") do f
                    write(f, script)
                end
                #=
                if qsub
                    run(`qsub $(joinpath(scriptdir, types_output_dir[T], "$(types_output_dir[T])_$n"))`)
                else
                    write(masterscripthandle, """bash $(joinpath(scriptdir, types_output_dir[T], "$(types_output_dir[T])_$n"))\n""")
                end
                =#
            end
        end
    end
end
