"""
Case study tests using TestItems.jl

This file contains comprehensive test cases for different energy system scenarios,
converted from traditional @testset format to modular @testitem format for better
test organization and execution control.
"""

using TestItems

@testsnippet CaseStudySetup begin
    using DuckDB: DuckDB, DBInterface
    using TulipaIO
    using JuMP
    using HiGHS: HiGHS
    using GLPK: GLPK
    using Test: Test, @test, @testset, @test_throws, @test_logs
    using TulipaEnergyModel: TulipaEnergyModel

    const INPUT_FOLDER = joinpath(@__DIR__, "inputs")

    function test_objective_value(energy_problem, expected_value; rtol = 1e-8, atol = 1e-5)
        @test energy_problem.objective_value ≈ expected_value rtol = rtol atol = atol
        return
    end

    function test_feasible_solution(energy_problem)
        @test JuMP.is_solved_and_feasible(energy_problem.model)
        return
    end

    function _read_csv_folder(connection, input_dir)
        schemas = TulipaEnergyModel.schema_per_table_name
        return TulipaIO.read_csv_folder(connection, input_dir; schemas)
    end
end

@testitem "Norse Case Study" tags = [:integration, :slow, :optimization] setup = [CaseStudySetup] begin
    dir = joinpath(INPUT_FOLDER, "Norse")
    parameters_dict = Dict(
        HiGHS.Optimizer => Dict("mip_rel_gap" => 0.01, "output_flag" => false),
        # TODO: Find a different way to test parameters of GLPK
        # Removing because it's finding bad bases (ill-conditioned) randomly
        # GLPK.Optimizer => Dict("mip_gap" => 0.01, "msg_lev" => 0, "presolve" => GLPK.GLP_ON),
    )

    for (optimizer, optimizer_parameters) in parameters_dict
        connection = DBInterface.connect(DuckDB.DB)
        _read_csv_folder(connection, dir)
        energy_problem = TulipaEnergyModel.run_scenario(
            connection;
            optimizer,
            optimizer_parameters,
            show_log = false,
        )
        test_feasible_solution(energy_problem)
    end
end

@testitem "Tiny Case Study" tags = [:integration, :fast, :optimization, :validation] setup =
    [CaseStudySetup] begin
    dir = joinpath(INPUT_FOLDER, "Tiny")
    optimizer_list = [HiGHS.Optimizer, GLPK.Optimizer]

    for optimizer in optimizer_list
        connection = DBInterface.connect(DuckDB.DB)
        _read_csv_folder(connection, dir)
        energy_problem = TulipaEnergyModel.run_scenario(connection; optimizer, show_log = false)
        test_objective_value(energy_problem, 269238.43825; rtol = 1e-8)

        # Test that populate_with_defaults shouldn't change the solution
        TulipaEnergyModel.populate_with_defaults!(connection)
        energy_problem = TulipaEnergyModel.run_scenario(connection; optimizer, show_log = false)
        test_objective_value(energy_problem, 269238.43825; rtol = 1e-8)
    end
end

@testitem "Tinier Case Study" tags = [:integration, :fast, :validation] setup = [CaseStudySetup] begin
    dir = joinpath(INPUT_FOLDER, "Tinier")
    connection = DBInterface.connect(DuckDB.DB)

    TulipaIO.read_csv_folder(connection, dir)
    TulipaEnergyModel.populate_with_defaults!(connection)
    energy_problem = TulipaEnergyModel.run_scenario(connection; show_log = false)
    test_objective_value(energy_problem, 269238.43825; rtol = 1e-8)

    # Test that populate_with_defaults shouldn't change the solution
    TulipaEnergyModel.populate_with_defaults!(connection)
    energy_problem = TulipaEnergyModel.run_scenario(connection; show_log = false)
    test_objective_value(energy_problem, 269238.43825; rtol = 1e-8)
end

@testitem "Storage Assets Case Study" tags = [:integration, :fast, :storage, :validation] setup =
    [CaseStudySetup] begin
    dir = joinpath(INPUT_FOLDER, "Storage")
    connection = DBInterface.connect(DuckDB.DB)

    _read_csv_folder(connection, dir)
    energy_problem = TulipaEnergyModel.run_scenario(connection; show_log = false)
    test_objective_value(energy_problem, 2542.234377; atol = 1e-5)

    # Test that populate_with_defaults shouldn't change the solution
    TulipaEnergyModel.populate_with_defaults!(connection)
    energy_problem = TulipaEnergyModel.run_scenario(connection; show_log = false)
    test_objective_value(energy_problem, 2542.234377; atol = 1e-5)
end

@testitem "UC ramping Case Study" tags =
    [:integration, :fast, :unit_commitment, :ramping, :validation] setup = [CaseStudySetup] begin
    dir = joinpath(INPUT_FOLDER, "UC-ramping")
    optimizer = HiGHS.Optimizer
    optimizer_parameters =
        Dict("output_flag" => false, "mip_rel_gap" => 0.0, "mip_feasibility_tolerance" => 1e-5)
    connection = DBInterface.connect(DuckDB.DB)

    _read_csv_folder(connection, dir)
    energy_problem = TulipaEnergyModel.run_scenario(
        connection;
        optimizer,
        optimizer_parameters,
        show_log = false,
    )
    test_objective_value(energy_problem, 293074.923309; atol = 1e-5)

    # Test that populate_with_defaults shouldn't change the solution
    TulipaEnergyModel.populate_with_defaults!(connection)
    energy_problem = TulipaEnergyModel.run_scenario(
        connection;
        optimizer,
        optimizer_parameters,
        show_log = false,
    )
    test_objective_value(energy_problem, 293074.923309; atol = 1e-5)
end

@testitem "Tiny Variable Resolution Case Study" tags = [:integration, :fast, :temporal, :validation] setup =
    [CaseStudySetup] begin
    dir = joinpath(INPUT_FOLDER, "Variable Resolution")
    connection = DBInterface.connect(DuckDB.DB)

    _read_csv_folder(connection, dir)
    energy_problem = TulipaEnergyModel.run_scenario(connection; show_log = false)
    test_objective_value(energy_problem, 28.45872; atol = 1e-5)

    # Test that populate_with_defaults shouldn't change the solution
    TulipaEnergyModel.populate_with_defaults!(connection)
    energy_problem = TulipaEnergyModel.run_scenario(connection; show_log = false)
    test_objective_value(energy_problem, 28.45872; atol = 1e-5)
end

@testitem "Multi-year Case Study" tags = [:integration, :fast, :multi_year, :validation] setup =
    [CaseStudySetup] begin
    dir = joinpath(INPUT_FOLDER, "Multi-year Investments")
    connection = DBInterface.connect(DuckDB.DB)

    _read_csv_folder(connection, dir)
    energy_problem = TulipaEnergyModel.run_scenario(
        connection;
        model_parameters_file = joinpath(@__DIR__, "inputs", "model-parameters-example.toml"),
        show_log = false,
    )
    test_objective_value(energy_problem, 3458577.01472; atol = 1e-5)

    # Test that populate_with_defaults shouldn't change the solution
    TulipaEnergyModel.populate_with_defaults!(connection)
    energy_problem = TulipaEnergyModel.run_scenario(
        connection;
        model_parameters_file = joinpath(@__DIR__, "inputs", "model-parameters-example.toml"),
        show_log = false,
    )
    test_objective_value(energy_problem, 3458577.01472; atol = 1e-5)
end

@testitem "Power Flow Case Study" tags = [:integration, :fast, :power_flow, :validation] setup =
    [CaseStudySetup] begin
    dir = joinpath(INPUT_FOLDER, "Power-flow")
    connection = DBInterface.connect(DuckDB.DB)

    _read_csv_folder(connection, dir)
    energy_problem = TulipaEnergyModel.run_scenario(connection; show_log = false)
    test_objective_value(energy_problem, 417486.99986; atol = 1e-5)

    # Test that populate_with_defaults shouldn't change the solution
    TulipaEnergyModel.populate_with_defaults!(connection)
    energy_problem = TulipaEnergyModel.run_scenario(connection; show_log = false)
    test_objective_value(energy_problem, 417486.99986; atol = 1e-5)
end

@testitem "Multiple Inputs Multiple Outputs Case Study" tags = [:integration, :fast, :validation] setup =
    [CaseStudySetup] begin
    dir = joinpath(INPUT_FOLDER, "MIMO")
    connection = DBInterface.connect(DuckDB.DB)

    _read_csv_folder(connection, dir)
    energy_problem = TulipaEnergyModel.run_scenario(connection; show_log = false)
    test_objective_value(energy_problem, 102936.724257; atol = 1e-5)

    # Test that populate_with_defaults shouldn't change the solution
    TulipaEnergyModel.populate_with_defaults!(connection)
    energy_problem = TulipaEnergyModel.run_scenario(connection; show_log = false)
    test_objective_value(energy_problem, 102936.724257; atol = 1e-5)
end

@testitem "Infeasible Case Study" tags = [:integration, :fast, :validation] setup = [CaseStudySetup] begin
    dir = joinpath(INPUT_FOLDER, "Tiny")
    connection = DBInterface.connect(DuckDB.DB)

    _read_csv_folder(connection, dir)
    DuckDB.execute( # Make it infeasible
        connection,
        "UPDATE asset_milestone
            SET peak_demand = -1
            WHERE
                asset = 'demand'
                AND milestone_year = 2030
        ",
    )
    energy_problem = TulipaEnergyModel.EnergyProblem(connection)
    TulipaEnergyModel.create_model!(energy_problem)
    @test_logs (:warn, "Model status different from optimal") TulipaEnergyModel.solve_model!(
        energy_problem;
    )
    @test energy_problem.termination_status == JuMP.INFEASIBLE
    io = IOBuffer()
    print(io, energy_problem)
    @test split(String(take!(io))) ==
          split(read("io-outputs/energy-problem-model-infeasible.txt", String))

    # Test that export solution warning is present in logs
    output_folder = mktempdir()
    @test_logs (:warn, "The energy problem has not been solved yet. Skipping export solution.") match_mode =
        :any TulipaEnergyModel.run_scenario(connection; output_folder, show_log = false)
end
