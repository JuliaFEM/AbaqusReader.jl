#!/usr/bin/env julia

# Find uncovered lines in source files
# This script helps identify which lines need additional test coverage

using Coverage

println("="^80)
println("Finding Uncovered Lines in Source Code")
println("="^80)
println()

# Process all source files
coverage_results = process_folder("src")

# Group by file and find uncovered lines
uncovered_by_file = Dict{String,Vector{Int}}()

for file_cov in coverage_results
    # Extract filename and coverage data
    filename = file_cov.filename
    cov_data = file_cov.coverage

    # Find lines with 0 coverage (uncovered)
    uncovered_lines = findall(x -> x === 0, cov_data)

    if !isempty(uncovered_lines)
        uncovered_by_file[filename] = uncovered_lines
    end
end

# Sort files by number of uncovered lines (worst first)
sorted_files = sort(collect(uncovered_by_file), by=x -> length(x[2]), rev=true)

if isempty(sorted_files)
    println("🎉 Perfect! All lines are covered!")
    exit(0)
end

println("Files with uncovered lines (sorted by count):")
println()

let total_uncovered = 0
    for (file, lines) in sorted_files
        total_uncovered += length(lines)

        # Calculate coverage percentage for this file
        file_cov = findfirst(x -> x.filename == file, coverage_results)
        all_cov = coverage_results[file_cov].coverage
        covered_lines = count(x -> x !== nothing && x > 0, all_cov)
        total_lines = count(x -> x !== nothing, all_cov)
        coverage_pct = total_lines > 0 ? round(100 * covered_lines / total_lines, digits=1) : 0.0

        println("📄 $file ($(coverage_pct)% covered)")
        println("   Uncovered lines: $(length(lines)) line(s)")

        # Show line numbers in a readable format
        if length(lines) <= 20
            println("   Lines: ", join(lines, ", "))
        else
            println("   Lines: ", join(lines[1:10], ", "), " ... ", join(lines[end-9:end], ", "))
        end
        println()
    end

    println("="^80)
    println("Total uncovered lines: $total_uncovered")
    println("="^80)
end
println()
println("💡 Tip: To see the actual code, use:")
println("   julia --project=. scripts/show_uncovered.jl <filename>")
