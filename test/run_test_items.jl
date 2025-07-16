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
    julia --project=test test/run_test_items.jl --update-tags                 # Update tags TOML file from test files
    julia --project=test test/run_test_items.jl --help                        # Show help
"""

using TestItemRunner
using TOML

# Path to the tags configuration file
const TAGS_FILE = joinpath(@__DIR__, "testitem-tags.toml")

"""
    load_tags()

Load tags from the TOML configuration file.
Returns a dictionary with tag symbols as keys and descriptions as values.
"""
function load_tags()
    if !isfile(TAGS_FILE)
        return Dict{Symbol,String}()
    end

    toml_data = TOML.parsefile(TAGS_FILE)
    tags_dict = Dict{Symbol,String}()

    if haskey(toml_data, "tags")
        for (key, value) in toml_data["tags"]
            tags_dict[Symbol(key)] = value
        end
    end

    return tags_dict
end

"""
    save_tags(tags_dict)

Save tags dictionary to the TOML configuration file using TOML.print.
"""
function save_tags(tags_dict)
    # Convert Symbol keys to strings for TOML
    string_dict = Dict("tags" => Dict(string(k) => v for (k, v) in tags_dict))

    open(TAGS_FILE, "w") do io
        return TOML.print(io, string_dict)
    end
    return
end

# Load tags from TOML file
const TAGS_DATA = load_tags()

"""
    discover_tags_from_files()

Walk through test files and discover tags used in @testitem declarations.
Returns a dictionary mapping tag symbols to their usage count.
"""
function discover_tags_from_files()
    tag_counts = Dict{Symbol,Int}()
    test_dir = @__DIR__

    # Only look at .jl files in the test directory (no subdirectories needed)
    for file in readdir(test_dir)
        !endswith(file, ".jl") && continue

        filepath = joinpath(test_dir, file)
        content = read(filepath, String)

        # Early exit if no @testitem in file
        !contains(content, "@testitem") && continue
        !contains(content, "tags=") && continue

        # Parse tags from @testitem lines
        for line in split(content, '\n')
            contains(line, "@testitem") || continue
            contains(line, "tags=") || continue

            # Extract tags: @testitem "name" tags=[:basic, :model]
            tag_match = match(r"tags=\[(.*?)\]", line)
            tag_match === nothing && continue

            # Parse individual tags
            for tag_part in split(tag_match.captures[1], ',')
                tag_clean = strip(tag_part)
                startswith(tag_clean, ':') || continue

                tag_symbol = Symbol(tag_clean[2:end])
                tag_counts[tag_symbol] = get(tag_counts, tag_symbol, 0) + 1
            end
        end
    end

    return tag_counts
end

"""
    update_tags_toml_file()

Update the TOML file with discovered tags, adding missing ones with "MISSING_TAG_ERROR".
"""
function update_tags_toml_file()
    discovered_tags = discover_tags_from_files()
    isempty(discovered_tags) && (println("No tags discovered"); return false)

    # Load current tags from TOML file
    current_tags = load_tags()

    # Find tags that need to be added
    new_tags_added = 0
    for tag in keys(discovered_tags)
        if !haskey(current_tags, tag)
            current_tags[tag] = "MISSING_TAG_ERROR"
            new_tags_added += 1
        end
    end

    # Save updated tags back to TOML file
    save_tags(current_tags)

    if new_tags_added > 0
        println("Added $new_tags_added new tags to TOML file with MISSING_TAG_ERROR")
        return true
    else
        println("TOML tags file is up to date")
        return false
    end
end

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

    if args.update_tags
        _update_and_show_tags()
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

# TODO: Document this function
function parse_arguments()
    # TODO: Raise error if argument if not valid
    verbose = "--verbose" in ARGS || "-v" in ARGS
    help = "--help" in ARGS || "-h" in ARGS
    list = "--list" in ARGS || "-l" in ARGS
    update_tags = "--update-tags" in ARGS

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
        update_tags = update_tags,
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

"""
    _update_and_show_tags()

Update the TAGS constant with discovered tags and display usage information.
"""
function _update_and_show_tags()
    println("Scanning test files and updating tags...")
    tag_counts = discover_tags_from_files()

    if isempty(tag_counts)
        println("No tags found in test files.")
        return
    end

    println("\nDiscovered tags with usage counts:")
    println("-"^40)

    # Sort by tag name
    for tag in sort(collect(keys(tag_counts)))
        count = tag_counts[tag]
        description = get(TAGS_DATA, tag, "No description")
        println("  :$tag (used $count times) - $description")
    end

    println("\nTotal unique tags: $(length(tag_counts))")

    # Automatically update the TOML file with discovered tags
    println("\nUpdating tags in TOML file...")
    updated = update_tags_toml_file()

    if updated
        println(
            "✓ TOML file updated successfully. You may need to restart Julia to see the changes.",
        )
    else
        println("✓ No updates needed - tags are already up to date.")
    end

    return
end

function _list_available_tests()
    println("Available test items:")
    println("-"^30)

    # This is a simplified listing - in practice, TestItemRunner would need
    # to be extended to provide test discovery without running
    println("Files with test items:")
    test_files = filter( # TODO: This filter doesn't check for testitem specific content
        f -> endswith(f, ".jl") && startswith(basename(f), "test"),
        readdir("test"; join = true),
    )
    for file in test_files
        println("  • $(basename(file))")
    end

    println("\nCommon tags: $(join(sort(collect(keys(TAGS_DATA))), ", "))")
    println("\nUse --file, --tag, --name, --pattern, or --exclude to filter tests")

    return
end

function _print_help()
    println(
        """
        TestItemRunner for TulipaEnergyModel.jl

        Usage:
            julia --project=test run_test_items.jl [OPTIONS]

        Options:
            --verbose, -v           Show verbose output
            --help, -h              Show this help message
            --list, -l              List available test files and tags
            --update-tags           Update tags TOML file and show tag usage counts
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

            # Update tags TOML file from test files
            julia --project=test run_test_items.jl --update-tags

        Available Tags:
    $(join(["        :$tag - $(get(TAGS_DATA, tag, "No description"))" for tag in sort(collect(keys(TAGS_DATA)))], "\n"))
        """,
    )
    return
end

# Run only if this script is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
