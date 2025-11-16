using Coverage

println("\n" * "="^60)
println("Coverage Report for AbaqusReader.jl")
println("="^60)

coverage = process_folder("src")
covered_lines, total_lines = get_summary(coverage)
pct = round(100 * covered_lines / total_lines, digits=2)

println("\n📊 Overall Coverage: $pct% ($covered_lines / $total_lines lines)\n")
println("="^60)
println("File-by-file breakdown:")
println("="^60)

for c in sort(coverage, by=x->x.filename)
    if c.coverage !== nothing && length(c.coverage) > 0
        file_covered = count(x -> x !== nothing && x > 0, c.coverage)
        file_total = count(x -> x !== nothing, c.coverage)
        if file_total > 0
            file_pct = round(100 * file_covered / file_total, digits=1)
            rel_path = replace(c.filename, pwd() * "/" => "")
            status = file_pct >= 80 ? "✅" : file_pct >= 60 ? "⚠️ " : "❌"
            println("$status $file_pct% - $rel_path ($file_covered/$file_total)")
        end
    end
end

println("\n" * "="^60)
println("Legend: ✅ ≥80%  ⚠️  60-79%  ❌ <60%")
println("="^60 * "\n")
