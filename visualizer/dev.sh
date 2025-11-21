#!/bin/bash
# Local development setup for AbaqusReader.jl visualizer
# Run this script to test frontend changes locally without Docker/Railway

set -e

echo "🚀 Starting AbaqusReader.jl visualizer in dev mode..."

# Check if Julia is available
if ! command -v julia &> /dev/null; then
    echo "❌ Julia not found. Please install Julia first."
    exit 1
fi

# Get the absolute path to the repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VISUALIZER_DIR="$REPO_ROOT/visualizer"

echo "📁 Repository root: $REPO_ROOT"

# Start backend in background
echo "🔧 Installing visualizer dependencies..."
cd "$VISUALIZER_DIR"
julia --project=. -e 'using Pkg; Pkg.instantiate()' 2>&1 | grep -v "Precompiling" || true

echo "🔧 Starting Julia backend on port 8080..."
julia --project=. "$VISUALIZER_DIR/src/AbaqusReaderAPI.jl" &
BACKEND_PID=$!

# Wait for backend to start
echo "⏳ Waiting for backend to start..."
sleep 3

# Check if backend is running
if ! kill -0 $BACKEND_PID 2>/dev/null; then
    echo "❌ Backend failed to start"
    exit 1
fi

echo "✅ Backend running (PID: $BACKEND_PID)"

# Start frontend
echo "🌐 Starting frontend on http://localhost:3000..."
cd "$VISUALIZER_DIR/frontend"

# Trap to kill background process on exit
cleanup() {
    echo ""
    echo "🛑 Stopping backend (PID: $BACKEND_PID)..."
    kill $BACKEND_PID 2>/dev/null || true
    exit 0
}
trap cleanup INT TERM EXIT

# Start simple HTTP server
if command -v python3 &> /dev/null; then
    echo "✨ Open http://localhost:3000 in your browser"
    echo "📝 Edit files in visualizer/frontend/ and refresh browser to see changes"
    echo "🛑 Press Ctrl+C to stop both servers"
    echo ""
    python3 -m http.server 3000
elif command -v python &> /dev/null; then
    echo "✨ Open http://localhost:3000 in your browser"
    echo "📝 Edit files in visualizer/frontend/ and refresh browser to see changes"
    echo "🛑 Press Ctrl+C to stop both servers"
    echo ""
    python -m SimpleHTTPServer 3000
else
    echo "❌ Python not found. Please install Python to run the frontend server."
    kill $BACKEND_PID
    exit 1
fi
