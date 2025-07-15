#!/usr/bin/env julia

"""
Command-line runner for modular tests using TestItemRunner.jl

This script provides a comprehensive interface to run TestItems.jl-based tests
for TulipaEnergyModel.jl with advanced filtering capabilities.

Usage examples:
    julia --project=test test/run_test_items.jl                               # Run all test items
    julia --project=test test/run_test_items.jl --verbose                     # Run with verbose output
    julia --project=test test/run_test_items.jl --file test-simple-example.jl # Run specific file
    julia --project=test test/run_test_items.jl --tag basic                   # Run tests with 'basic' tag
    julia --project=test test/run_test_items.jl --name "Simple Arithmetic"    # Run specific test by name
    julia --project=test test/run_test_items.jl --pattern "Energy"            # Run test or files that match pattern
    julia --project=test test/run_test_items.jl --exclude slow                # Exclude tests with 'slow' tag
    julia --project=test test/run_test_items.jl --help                        # Show help
"""

using TestItemRunner

function main()
    args = parse_arguments()

    if args.help
        _print_help()
        return
    end

    println("Running TulipaEnergyModel.jl Test Items")
    println("="^50)

    if args.list
        _list_available_tests()
        return
    end

    filter_func = _create_filter(args)

    if isnothing(filter_func)
        @run_package_tests verbose = args.verbose
    else
        @run_package_tests verbose = args.verbose filter = filter_func
    end

    return
end

function parse_arguments()
    verbose = "--verbose" in ARGS || "-v" in ARGS
    help = "--help" in ARGS || "-h" in ARGS
    list = "--list" in ARGS || "-l" in ARGS

    # TODO: Refactor these into a function
    # Parse file filter
    file_filter = nothing
    file_idx = findfirst(x -> x == "--file", ARGS)
    if !isnothing(file_idx) && file_idx < length(ARGS)
        file_filter = ARGS[file_idx+1]
    end

    # Parse tag filter
    tag_filter = nothing
    tag_idx = findfirst(x -> x == "--tag", ARGS)
    if !isnothing(tag_idx) && tag_idx < length(ARGS)
        tag_filter = Symbol(ARGS[tag_idx+1])
    end

    # Parse exclude filter
    exclude_filter = nothing
    exclude_idx = findfirst(x -> x == "--exclude", ARGS)
    if !isnothing(exclude_idx) && exclude_idx < length(ARGS)
        exclude_filter = Symbol(ARGS[exclude_idx+1])
    end

    # Parse name filter
    name_filter = nothing
    name_idx = findfirst(x -> x == "--name", ARGS)
    if !isnothing(name_idx) && name_idx < length(ARGS)
        name_filter = ARGS[name_idx+1]
    end

    # Parse pattern filter
    pattern_filter = nothing
    pattern_idx = findfirst(x -> x == "--pattern", ARGS)
    if !isnothing(pattern_idx) && pattern_idx < length(ARGS)
        pattern_filter = ARGS[pattern_idx+1]
    end

    return (
        verbose = verbose,
        help = help,
        list = list,
        file = file_filter,
        tag = tag_filter,
        exclude = exclude_filter,
        name = name_filter,
        pattern = pattern_filter,
    )
end

function _create_filter(args)
    filters = []

    # File filter
    if !isnothing(args.file)
        push!(filters, test_item -> endswith(test_item.filename, args.file))
    end

    # Tag filter
    if !isnothing(args.tag)
        push!(filters, test_item -> args.tag in test_item.tags)
    end

    # Exclude filter
    if !isnothing(args.exclude)
        push!(filters, test_item -> !(args.exclude in test_item.tags))
    end

    # Name filter
    if !isnothing(args.name)
        push!(filters, test_item -> test_item.name == args.name)
    end

    # Pattern filter
    if !isnothing(args.pattern)
        push!(
            filters,
            test_item ->
                contains(test_item.name, args.pattern) ||
                contains(test_item.filename, args.pattern),
        )
    end

    if isempty(filters)
        return nothing
    end

    # Combine all filters with AND logic
    return test_item -> all(f(test_item) for f in filters)
end

function _list_available_tests()
    println("Available test items:")
    println("-"^30)

    # This is a simplified listing - in practice, TestItemRunner would need
    # to be extended to provide test discovery without running
    println("Files with test items:")
    test_files = filter(
        f -> endswith(f, ".jl") && startswith(basename(f), "test"),
        readdir("test"; join = true),
    )
    for file in test_files
        println("  • $(basename(file))")
    end

    # TODO: Don't hardcode tags here
    println("\nCommon tags: :basic, :model, :data, :validation, :case_study, :simple")
    println("\nUse --file, --tag, --name, --pattern, or --exclude to filter tests")

    return
end

function _print_help()
    println("""
    TestItemRunner for TulipaEnergyModel.jl

    Usage:
        julia --project=test run_test_items.jl [OPTIONS]

    Options:
        --verbose, -v           Show verbose output
        --help, -h              Show this help message
        --list, -l              List available test files and tags
        --file FILE             Run tests from specific file (e.g., test-simple-example.jl)
        --tag TAG               Run tests with specific tag (e.g., basic, model, data)
        --exclude TAG           Exclude tests with specific tag (e.g., slow, skipci)
        --name NAME             Run specific test by exact name
        --pattern PATTERN       Run tests matching pattern in name or filename

    Examples:
        # Run all tests
        julia --project=test run_test_items.jl

        # Run with verbose output
        julia --project=test run_test_items.jl --verbose

        # Run tests from specific file
        julia --project=test run_test_items.jl --file test-simple-example.jl

        # Run tests with specific tag
        julia --project=test run_test_items.jl --tag basic

        # Run specific test by name
        julia --project=test run_test_items.jl --name "Simple Arithmetic"

        # Exclude slow tests
        julia --project=test run_test_items.jl --exclude slow

        # Run tests matching pattern
        julia --project=test run_test_items.jl --pattern "Energy"

        # Combine filters (file + tag)
        julia --project=test run_test_items.jl --file test-modular-example.jl --tag basic

        # List available tests and tags
        julia --project=test run_test_items.jl --list

    Available Tags:
        :basic       - Basic functionality tests
        :model       - Model creation and validation tests
        :data        - Data loading and validation tests
        :validation  - Validation and verification tests
        :case_study  - Full case study tests
        :simple      - Simple/fast tests
    """) # TODO: Don't hardcode tags up here
    return
end

# Run only if this script is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
