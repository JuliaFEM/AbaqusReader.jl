FROM julia:1.12.1

# Install git-lfs
RUN apt-get update && apt-get install -y git-lfs && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the entire AbaqusReader.jl repo into the container
COPY . /app/AbaqusReader.jl

# Activate git-lfs and pull files (if .git present)
WORKDIR /app/AbaqusReader.jl
RUN git lfs install && git lfs pull || echo "LFS pull failed, continuing..."

# Instantiate dependencies for visualizer
RUN julia --project=visualizer -e 'using Pkg; Pkg.develop(path="/app/AbaqusReader.jl"); Pkg.instantiate(); Pkg.precompile()'

# Expose default port
EXPOSE 8080

# Start the Julia server from the copied repo with correct project
CMD ["julia", "--project=visualizer", "-e", "import AbaqusReaderAPI; AbaqusReaderAPI.start()"]
