using CSV, DataFrames

include("generate_scripts.jl")

function type_stats(T::DataType)
    output_dir = "output/$(TYPES_OUTPUT_DIR[T])/"
    dfs = [CSV.read(joinpath(output_dir, f)) for f in readdir(output_dir)]
    vcat(dfs...)
end


function collect_stats(types = keys(TYPES_OUTPUT_DIR))
    dfs = [type_stats(T) for T in types]
    vcat(dfs...)
end
