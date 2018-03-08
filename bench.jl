using GraphChallenge
using JLD

function precompile_run(T)
    static_partition_experiment(T, 50)
end

function bench(T, num_nodes, output_file)
    precompile_run(T)
    results = static_partition_experiment(T, num_nodes)
    jldopen(output_file, "w") do file
        write(file, "result", results)
    end
end
