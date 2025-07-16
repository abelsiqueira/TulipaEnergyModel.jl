"""
Modular test examples using TestItems.jl

This file demonstrates advanced testing patterns including:
- @testsnippet for shared setup code
- @testmodule for utility functions
- @testitem for individual test cases
- Proper resource cleanup with try-finally blocks
"""

using TestItems

@testsnippet CommonSetup begin
    using DuckDB: DuckDB, DBInterface
    using TulipaIO

    const INPUT_FOLDER = joinpath(@__DIR__, "inputs")

    function setup_connection_and_read_data(folder_name)
        connection = DBInterface.connect(DuckDB.DB)
        dir = joinpath(INPUT_FOLDER, folder_name)
        TulipaIO.read_csv_folder(connection, dir)
        return connection
    end

    function cleanup_connection(connection)
        DBInterface.close!(connection)
        return
    end
end

@testmodule TestUtils begin
    using Test, JuMP

    export verify_objective_value, verify_feasible_solution, verify_solution_status

    function verify_objective_value(energy_problem, expected_value; rtol = 1e-8, atol = 1e-5)
        @test energy_problem.objective_value ≈ expected_value rtol=rtol atol=atol
        return
    end

    function verify_feasible_solution(energy_problem)
        @test JuMP.is_solved_and_feasible(energy_problem.model)
        return
    end

    function verify_solution_status(energy_problem, expected_status)
        @test JuMP.termination_status(energy_problem.model) == expected_status
        return
    end
end

@testitem "Basic EnergyProblem Creation" tags=[:unit, :fast] setup=[CommonSetup] begin
    connection = setup_connection_and_read_data("Tiny")

    try
        energy_problem = TulipaEnergyModel.EnergyProblem(connection)
        @test energy_problem isa TulipaEnergyModel.EnergyProblem
    finally
        cleanup_connection(connection)
    end
end

@testitem "Data Loading" tags=[:unit, :fast] setup=[CommonSetup] begin
    connection = setup_connection_and_read_data("Tiny")

    try
        @test connection isa DuckDB.DB

        tables = DuckDB.execute(connection, "SHOW TABLES") |> collect
        table_names = [row[1] for row in tables]

        @test "asset" in table_names
        @test "flow" in table_names
    finally
        cleanup_connection(connection)
    end
end

@testitem "Asset Data Validation" tags=[:unit, :fast, :validation] setup=[CommonSetup] begin
    connection = setup_connection_and_read_data("Tiny")

    try
        asset_data = DuckDB.execute(connection, "SELECT * FROM asset LIMIT 1") |> collect
        @test length(asset_data) > 0

        flow_data = DuckDB.execute(connection, "SELECT * FROM flow LIMIT 1") |> collect
        @test length(flow_data) > 0
    finally
        cleanup_connection(connection)
    end
end

@testitem "Tinier Case Study" tags=[:integration, :fast, :validation] setup=[CommonSetup] begin
    connection = setup_connection_and_read_data("Tinier")

    try
        TulipaEnergyModel.populate_with_defaults!(connection)
        energy_problem = TulipaEnergyModel.run_scenario(connection; show_log = false)

        @test energy_problem.objective_value ≈ 269238.43825 rtol=1e-8

        TulipaEnergyModel.populate_with_defaults!(connection)
        energy_problem = TulipaEnergyModel.run_scenario(connection; show_log = false)
        @test energy_problem.objective_value ≈ 269238.43825 rtol=1e-8
    finally
        cleanup_connection(connection)
    end
end
