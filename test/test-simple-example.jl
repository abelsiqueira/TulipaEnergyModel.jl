using TestItems

@testitem "Simple Test" tags=[:basic] begin
    @test 1 + 1 == 2
end

@testitem "TulipaEnergyModel Import" tags=[:basic] begin
    # TulipaEnergyModel should be available by default
    @test TulipaEnergyModel isa Module
    @test hasmethod(TulipaEnergyModel.run_scenario, Tuple{Any})
end

@testitem "Basic Math Operations" tags=[:basic] begin
    x = 5
    y = 3
    @test x + y == 8
    @test x * y == 15
    @test x > y
end
