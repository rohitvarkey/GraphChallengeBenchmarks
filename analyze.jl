using CSV, DataFrames, Query, StatPlots
import PyPlot

pyplot()

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

function create_plots(df)
    plots = []
        threads = sort(unique(df[:threads]))
        for thread in threads
            filtered_df = df |>
                @filter(_.threads == thread) |>
                @orderby_descending(-_.num_nodes)
        p = @df filtered_df plot(:num_nodes, :time, group=:Name, scale=:log10, marker=:auto, title="Threads = $thread", legend = :bottomright, legendfontsize = 8)
        push!(plots, p)
    end
    final_plot = plot(plots..., size = (1200, 800))
    savefig(final_plot, "thread_times.png")
    final_plot
end


function create_scaling_plots(df)
    plots = []
    for (T, t_name) in GraphChallenge.BACKEND_NAMES
        filtered_df = df |>
            @filter(_.Name == t_name) |>
            @orderby_descending(-_.threads)
        single_thread_runs = @from i in filtered_df begin
               @where i.threads == 1
               @orderby i.num_nodes
               @select i.num_nodes => i.time
               @collect
        end
        scaling_numbers = @from i in filtered_df begin
               @select i.num_nodes => i.time
               @collect
        end
        if isempty(filtered_df)
            continue
        end
        p = @df filtered_df plot(:threads, :time, group=:num_nodes, scale=:log10, marker=:auto, title="Type = $(t_name)", legend = :topleft)
        push!(plots, p)
    end
    final_plot = plot(plots..., size = (1200, 800))
    savefig(final_plot, "thread_scaling.png")
    final_plot
end
