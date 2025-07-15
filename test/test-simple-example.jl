using TestItems

@testitem "Simple Arithmetic" tags=[:basic] begin
    @test 1 + 1 == 2
    @test 2 * 3 == 6
    @test 10 / 2 == 5.0
end

@testitem "TulipaEnergyModel Module" tags=[:basic] begin
    @test TulipaEnergyModel isa Module
    @test hasmethod(TulipaEnergyModel.run_scenario, Tuple{Any})
    @test hasmethod(TulipaEnergyModel.EnergyProblem, Tuple{Any})
end

@testitem "Variable Operations" tags=[:basic] begin
    x = 5
    y = 3
    @test x + y == 8
    @test x * y == 15
    @test x > y
    @test x^2 == 25
    @test sqrt(x) ≈ 2.236067977499790 rtol=1e-10
end
