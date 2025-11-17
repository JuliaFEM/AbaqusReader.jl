FROM julia:1.11

# Install git-lfs
RUN apt-get update && apt-get install -y git-lfs && rm -rf /var/lib/apt/lists/*

# Set working directory (Railway clones repo here)
WORKDIR /app

# Pull LFS files (Railway provides .git directory)
RUN git lfs install && git lfs pull || echo "LFS pull failed, continuing..."

# Copy backend code
COPY visualizer/backend/ visualizer/backend/

# Verify test files were pulled
RUN [ -d testdata ] && ls -lh testdata/ || echo "No testdata directory"

# Change to backend directory
WORKDIR /app/visualizer/backend

# Install Julia dependencies
RUN julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Expose port
EXPOSE 8080

# Run server
CMD ["julia", "--project=.", "server.jl"]
