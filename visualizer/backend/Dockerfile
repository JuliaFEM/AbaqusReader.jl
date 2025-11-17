FROM julia:1.11

# Install git-lfs for downloading test data files
RUN apt-get update && apt-get install -y git-lfs && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy entire project (including .git for LFS)
COPY . .

# Pull LFS files (testdata/*.inp)
RUN git lfs install && git lfs pull

# Change to backend directory for package operations
WORKDIR /app/visualizer/backend

# Install HTTP and JSON3 first, then develop AbaqusReader from repo root
RUN julia --project=. -e 'using Pkg; Pkg.add(["HTTP", "JSON3"]); Pkg.develop(path="/app")'

# Expose port
EXPOSE 8080

# Run server
CMD ["julia", "--project=.", "server.jl"]
