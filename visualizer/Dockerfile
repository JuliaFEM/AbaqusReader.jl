FROM julia:1.12.1 AS builder

# Install git and git-lfs for downloading test data
RUN apt-get update && \
    apt-get install -y git git-lfs curl && \
    git lfs install --skip-repo && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy source files
COPY . /app/AbaqusReader.jl

WORKDIR /app/AbaqusReader.jl

# Check if testdata files are LFS pointers and download them if needed
RUN echo "Checking testdata files..." && \
    if head -1 testdata/3d_beam.inp | grep -q "version https://git-lfs.github.com"; then \
        echo "Files are LFS pointers - downloading from GitHub..." && \
        cd testdata && \
        for file in *.inp; do \
            echo "Downloading $file..." && \
            pointer_oid=$(grep "oid sha256:" "$file" | cut -d: -f2) && \
            curl -L "https://media.githubusercontent.com/media/ahojukka5/AbaqusReader.jl/master/testdata/$file" -o "$file.tmp" && \
            mv "$file.tmp" "$file"; \
        done && \
        cd .. && \
        echo "LFS files downloaded successfully"; \
    else \
        echo "Files are already checked out"; \
    fi && \
    ls -lh testdata/*.inp

# Final stage
FROM julia:1.12.1

WORKDIR /app

# Copy the repo with actual testdata files from builder
COPY --from=builder /app/AbaqusReader.jl /app/AbaqusReader.jl

WORKDIR /app/AbaqusReader.jl

# Verify testdata
RUN echo "Verifying testdata files in final image..." && \
    ls -lh testdata/*.inp && \
    head -2 testdata/3d_beam.inp

# Instantiate dependencies for visualizer
RUN julia --project=visualizer -e 'using Pkg; Pkg.develop(path="/app/AbaqusReader.jl"); Pkg.instantiate(); Pkg.precompile()'

# Expose default port
EXPOSE 8080

# Start the Julia server
CMD ["julia", "--project=visualizer", "-e", "import AbaqusReaderAPI; AbaqusReaderAPI.start()"]
