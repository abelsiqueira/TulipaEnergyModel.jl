#!/usr/bin/env julia

"""
Example script showing how to run modular tests with TestItemRunner.jl

Usage examples:
    julia --project=test run_test_items.jl                    # Run all test items
    julia --project=test run_test_items.jl --verbose          # Run with verbose output
    julia --project=test run_test_items.jl --help             # Show help
"""

using TestItemRunner
using Pkg

function main()
    # Simple argument parsing
    verbose = "--verbose" in ARGS
    show_help = "--help" in ARGS || "-h" in ARGS

    if show_help
        println("""
        TestItemRunner for TulipaEnergyModel.jl

        Usage:
            julia --project=test run_test_items.jl [OPTIONS]

        Options:
            --verbose    Show verbose output
            --help, -h   Show this help message

        Examples:
            julia --project=test run_test_items.jl
            julia --project=test run_test_items.jl --verbose
        """)
        return
    end

    println("Running TulipaEnergyModel.jl Test Items")
    println("=" ^ 50)

    # Run all test items
    @run_package_tests verbose=verbose
end

# Run only if this script is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
