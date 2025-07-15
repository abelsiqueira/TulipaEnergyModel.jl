# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TulipaEnergyModel.jl is a Julia optimization model for electricity markets and coupling with other energy sectors (hydrogen, heat, natural gas). It determines optimal investment and operation decisions for various energy assets (producers, consumers, conversions, storages, transports).

## Key Commands

### Testing

- `julia --project=. -e "using Pkg; Pkg.test()"` - Run all tests
- `julia --project=test -e "using Pkg; Pkg.test()"` - Run tests in test environment
- `julia --project=test test/run_test_items.jl` - Run modular test items
- `julia --project=test test/run_test_items.jl --verbose` - Run test items with verbose output

### Development Setup

- `julia --project=. -e "using Pkg; Pkg.instantiate()"` - Install dependencies
- `julia --project=. -e "using Pkg; Pkg.develop()"` - Set up for development

### Code Quality

- `pre-commit run -a` - Run all linters and formatters
- `julia --project=. -e "using JuliaFormatter; format(\".\")"` - Format Julia code

### Documentation

- `julia --project=docs docs/make.jl` - Build documentation
- `julia --project=docs -e "using LiveServer; servedocs(launch_browser=true)"` - Live preview docs

### Benchmarking

- `julia --project=benchmark benchmark/benchmarks.jl` - Run benchmarks
- `julia --project=. utils/scripts/model-mps-update.jl` - Update MPS reference files
- `julia --project=. utils/scripts/model-mps-compare.jl` - Compare MPS files

## Architecture

### Core Structure

- **src/TulipaEnergyModel.jl**: Main module file with all imports and includes
- **src/structures.jl**: Core data structures and types
- **src/io.jl**: Input/output operations and data handling
- **src/create-model.jl**: JuMP model creation orchestration
- **src/solve-model.jl**: Model solving and solution handling

### Model Components

- **variables/**: JuMP variable definitions (flows, investments, storage, unit-commitment)
- **constraints/**: Constraint definitions organized by type (capacity, energy, transport, etc.)
- **expressions/**: JuMP expressions for multi-year modeling and storage
- **sql/**: SQL queries for constraint and variable creation

### Key Workflows

1. **Data Input**: CSV files → validation → internal structures
2. **Model Creation**: structures → JuMP variables/constraints → optimization model
3. **Solving**: model → solver (HiGHS default) → solution extraction
4. **Output**: solution → CSV files with results

### Input Data Structure

Test cases in `test/inputs/` follow this pattern:

- `asset*.csv`: Asset definitions (generators, storage, etc.)
- `flow*.csv`: Flow definitions between assets
- `profiles*.csv`: Time-varying parameters
- `rep-periods-*.csv`: Representative periods for temporal aggregation
- `timeframe-*.csv`: Time resolution definitions

## Development Guidelines

### Code Style

- Use `snake_case` for functions/variables, `CamelCase` for types
- Prefer `using Package: func` over bare `using Package`
- All `using` statements go in main module file
- Functions must explicitly `return` (even if returning nothing)

### Testing Requirements

- Maintain 100% test coverage
- Use `LocalCoverage.jl` to check coverage locally
- Test cases are in `test/inputs/` with various energy system scenarios
- **TestItemRunner.jl**: Modular testing framework using `@testitem`, `@testsnippet`, and `@testmodule`
  - Individual test execution with tagging system for filtering
  - Module isolation ensures each test runs in clean environment
  - Shared setup code via `@testsnippet` for common initialization patterns
  - Utility functions via `@testmodule` for reusable test helpers
  - Supports parallel execution and integrates with VS Code and command-line
  - Example files: `test/test-simple-example.jl`, `test/test-modular-example.jl`

### Model Validation

- MPS files in `benchmark/model-mps-folder/` serve as reference for model structure
- Run MPS comparison before committing changes that affect model formulation
- Update reference MPS files when model changes are intentional

### Dependencies

- **Optimization**: JuMP.jl with HiGHS.jl solver
- **Data**: CSV.jl, DuckDB.jl, TulipaIO.jl
- **Testing**: TestItems.jl, TestItemRunner.jl (test environment only)
- **Utilities**: TOML.jl, JSON.jl, TimerOutputs.jl

## Common Pitfalls

- Changes to constraint/variable definitions require MPS file updates
- Pre-commit hooks enforce formatting - install with `pre-commit install`
- Documentation builds require `Revise.jl` in global environment
- Representative periods modeling affects temporal resolution significantly
