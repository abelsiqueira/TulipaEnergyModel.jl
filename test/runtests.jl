using CSV: CSV
using DataFrames: DataFrames, DataFrame
using DuckDB: DuckDB, DBInterface
using GLPK: GLPK
using HiGHS: HiGHS
using JuMP: JuMP
using MathOptInterface: MathOptInterface
using Test: Test, @test, @testset, @test_throws, @test_logs
using TOML: TOML
using TulipaEnergyModel: TulipaEnergyModel
using TulipaIO: TulipaIO

# Folders names
const INPUT_FOLDER = joinpath(@__DIR__, "inputs")
const OUTPUT_FOLDER = joinpath(@__DIR__, "outputs")
if !isdir(OUTPUT_FOLDER)
    mkdir(OUTPUT_FOLDER)
end

include("utils.jl")

#=
Don't add your tests to runtests.jl. Instead, create files named

    test-title-for-my-test.jl

The file will be automatically included inside a `@testset` with title "Title For My Test".
=#
for (root, dirs, files) in walkdir(@__DIR__)
    for file in files
        if isnothing(match(r"^test-.*\.jl$", file))
            continue
        end
        title = titlecase(replace(splitext(file[6:end])[1], "-" => " "))
        @testset "$title" begin
            # include(file)
        end
    end
end

# Other general tests that don't need their own file
# @testset "Ensuring benchmark loads" begin
#     include(joinpath(@__DIR__, "..", "benchmark", "benchmarks.jl"))
#     @test SUITE !== nothing
# end
#
# @testset "Ensuring data can be read and create the internal structures" begin
#     connection = DBInterface.connect(DuckDB.DB)
#     _read_csv_folder(connection, joinpath(@__DIR__, "../benchmark/EU/"))
#     TulipaEnergyModel.create_internal_tables!(connection)
# end

@testset "Ensuring model.lp stays the same" begin
    model_lp_folder = joinpath(@__DIR__, "..", "benchmark", "model-lp-folder")
    contextualize(str, i, n = 3) = begin
        imin = max(1, i - n)
        imax = min(length(str), i + n)
        str[imin:imax]
    end
    for folder in readdir("inputs"; join = true)
        isdir(folder) || continue
        existing_lp = joinpath(model_lp_folder, basename(folder) * ".lp")
        @assert isfile(existing_lp)

        con = DBInterface.connect(DuckDB.DB)
        schemas = TulipaEnergyModel.schema_per_table_name
        TulipaIO.read_csv_folder(con, folder; schemas)
        TulipaEnergyModel.run_scenario(con; write_lp_file = true, show_log = false)

        new_lp = joinpath(@__DIR__, "model.lp")
        @assert isfile(new_lp)

        zipped_lines = zip(readlines(existing_lp), readlines(new_lp))
        for (i, (existing_line, new_line)) in enumerate(zipped_lines)
            unmatched = findall(collect(existing_line) .!= collect(new_line))
            if length(unmatched) > 0
                @warn unmatched existing_line[unmatched] new_line[unmatched]
                j = unmatched[1]
                @warn "Context of first unmatched" contextualize(existing_line, j) contextualize(
                    new_line,
                    j,
                )
            end
            @test existing_line == new_line
        end
    end
end
