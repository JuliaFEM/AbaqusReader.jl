FROM julia:1.11

# Set working directory
WORKDIR /app

# Copy entire project
COPY . .

# Change to backend directory for package operations
WORKDIR /app/visualizer/backend

# Install HTTP and JSON3 first, then develop AbaqusReader from repo root
RUN julia --project=. -e 'using Pkg; Pkg.add(["HTTP", "JSON3"]); Pkg.develop(path="/app")'

# Expose port
EXPOSE 8080

# Run server
CMD ["julia", "--project=.", "server.jl"]
