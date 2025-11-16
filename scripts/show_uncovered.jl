#!/usr/bin/env julia

# Show uncovered lines from a specific file
# Usage: julia --project=. scripts/show_uncovered.jl <filename>

using Coverage

function main()
    if length(ARGS) < 1
        println("Usage: julia --project=. scripts/show_uncovered.jl <filename>")
        println()
        println("Example:")
        println("  julia --project=. scripts/show_uncovered.jl src/model/sections.jl")
        exit(1)
    end

    filename = ARGS[1]

    # Make sure file exists
    if !isfile(filename)
        println("Error: File not found: $filename")
        exit(1)
    end

    # Process coverage
    coverage_results = process_folder("src")

    # Find coverage for this file
    file_cov_data = nothing
    for fc in coverage_results
        if fc.filename == filename
            file_cov_data = fc.coverage
            break
        end
    end

    if file_cov_data === nothing
        println("Error: No coverage data found for $filename")
        println("Make sure to run tests with coverage first:")
        println("  julia --project=. -e 'using Pkg; Pkg.test(coverage=true)'")
        exit(1)
    end

    # Find uncovered lines
    uncovered_lines = findall(x -> x === 0, file_cov_data)

    if isempty(uncovered_lines)
        println("🎉 All lines in $filename are covered!")
        exit(0)
    end

    # Read the source file
    source_lines = readlines(filename)

    # Calculate statistics
    covered_lines = count(x -> x !== nothing && x > 0, file_cov_data)
    total_lines = count(x -> x !== nothing, file_cov_data)
    coverage_pct = round(100 * covered_lines / total_lines, digits=1)

    println("=" ^ 80)
    println("Uncovered Lines in $filename")
    println("=" ^ 80)
    println()
    println("Coverage: $(coverage_pct)% ($covered_lines/$total_lines lines)")
    println("Uncovered: $(length(uncovered_lines)) line(s)")
    println()
    println("=" ^ 80)
    println()

    # Show uncovered lines with context
    for line_num in uncovered_lines
        # Show 2 lines of context before and after
        start_line = max(1, line_num - 2)
        end_line = min(length(source_lines), line_num + 2)
        
        println("Lines $start_line-$end_line (uncovered: $line_num):")
        println("─" ^ 80)
        
        for i in start_line:end_line
            marker = i == line_num ? "❌" : "  "
            line_marker = lpad(i, 4)
            println("$marker $line_marker │ $(source_lines[i])")
        end
        
        println()
    end

    println("=" ^ 80)
    println("💡 Add tests to cover these $(length(uncovered_lines)) line(s)")
    println("=" ^ 80)
end

main()
