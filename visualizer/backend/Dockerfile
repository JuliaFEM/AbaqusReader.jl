FROM julia:1.11

# Set working directory
WORKDIR /app

# Copy entire project
COPY . .

# Install dependencies and develop local package
RUN julia -e 'using Pkg; Pkg.add(["HTTP", "JSON3"]); Pkg.develop(path="/app")'

# Expose port
EXPOSE 8080

# Run server from its location
CMD ["julia", "visualizer/backend/server.jl"]
