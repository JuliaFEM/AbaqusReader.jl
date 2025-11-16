FROM julia:1.11

# Set working directory
WORKDIR /app

# Copy entire project (we're building from repo root)
COPY . /AbaqusReader

# Copy server from visualizer/backend  
COPY visualizer/backend/server.jl .

# Install dependencies and develop local package
RUN julia -e 'using Pkg; Pkg.add(["HTTP", "JSON3"]); Pkg.develop(path="/AbaqusReader")'

# Expose port
EXPOSE 8080

# Run server
CMD ["julia", "server.jl"]
