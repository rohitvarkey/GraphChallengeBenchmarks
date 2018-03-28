using GraphChallenge
using DataFrames
using CSV
import Base.Threads

function precompile_run(T)
    static_partition_experiment(T, 50)
end

function bench(T, num_nodes, output_file, seed = 0)
    precompile_run(T)
    srand(seed)
    p, m, t = static_partition_experiment(T, num_nodes)
    df = convert(DataFrame, [m])
    df[:threads] = [Threads.nthreads()]
    CSV.write(output_file, df)
    p, m, t
end
