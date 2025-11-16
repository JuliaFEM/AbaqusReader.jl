# AbaqusReader.jl Online Visualizer 🚀

> **Why did we build this?** JUST BECAUSE WE CAN. 😎💨

Interactive web-based 3D visualizer for ABAQUS `.inp` files. Drag, drop, visualize. No installation. No bullshit.

## What It Does

- 🎯 **Drag & drop** `.inp` files directly in your browser
- 🎨 **3D visualization** with Three.js (wireframe + solid mesh)
- 📊 **Mesh statistics** (nodes, elements, sets, surfaces)
- 🔬 **Full model parsing** (materials, properties, boundary conditions, load steps)
- 🐛 **Error reporting** with one-click GitHub issue creation
- 🌈 **Julia branding** with that beautiful purple-green gradient
- 🎭 **Auto-fade status** indicator that gets out of your way

## Why This Exists

Because parsing ABAQUS files shouldn't require:

- Installing ABAQUS ($$$$$)
- Opening a terminal
- Reading documentation
- Sacrificing your firstborn to the FEA gods

Just open a browser. Drop a file. See your mesh. That's it.

Also, we wanted to prove that Julia can do web stuff, and do it well.

## The Stack

**Frontend**: Vue.js 3 + Three.js r128 + Pure CSS (no build system because we're not masochists)  
**Backend**: Julia HTTP.jl + AbaqusReader.jl (the thing this whole repo is about)  
**Container**: Docker/Podman (because reproducibility matters)  
**Deployment**: Free tier everything (Railway + GitHub Pages)

## Quick Start

### Using Podman/Docker (Recommended)

```bash
# Build and run
podman-compose up

# or with Docker
docker-compose up
```

Open http://localhost:3000 and start dropping files.

### Manual Setup (If You're Into That)

**Backend**:

```bash
cd backend
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. server.jl  # Runs on :8080
```

**Frontend**:

```bash
cd frontend
python3 -m http.server 3000  # or any static server
```

## API

### `POST /parse`

Send `.inp` file content, get back JSON with nodes, elements, stats, and full model data.

### `GET /health`

Returns `{"status": "healthy"}` if the backend is alive. Used by the frontend to show that satisfying green dot.

## Design Philosophy

1. **No bullshit**: It either works or it tells you exactly why it doesn't
2. **Fast feedback**: Connection status fades away if everything is OK
3. **Julia colors**: Purple (#9558B2), Green (#389826), Blue (#4063D8) everywhere
4. **Mobile-friendly**: Because why not visualize FEM on your phone?
5. **Self-documenting**: Errors link directly to GitHub issues with context

## Deployment

The backend can run on any free-tier container hosting:

- **Railway.app** (500h/month free) ← Recommended
- **Render.com** (750h/month free)
- **Fly.io** (3 VMs free)

Frontend goes straight to **GitHub Pages** because it's just static files.

See the [Taiga wiki](https://tree.taiga.io/project/ahojukka5-abaqusreaderjl/wiki/online-visualizer) for detailed deployment instructions.

## Development

Frontend is pure HTML/JS/CSS with CDN dependencies. No webpack. No npm. No `node_modules` black hole.

Just edit `index.html` or `app.js` and refresh. Like it's 2010 again, but with Vue 3.

## Technical Highlights

- **Zero-based indexing conversion**: Julia (1-based) → JavaScript (0-based) done right
- **Vue reactivity safety**: `markRaw()` for all Three.js objects
- **Smart caching**: Connection status fades after 10s when healthy
- **Element topology abstraction**: Same mesh regardless of physics type (CPS3/CPE3/CAX3 → Tri3)

## License

MIT (same as AbaqusReader.jl)

---

**Status**: Production-ready  
**Coolness Factor**: 11/10  
**Lines of Code**: Less than you'd think  
**Dependencies**: Fewer than you'd expect  
**Deployment Cost**: $0/month  
**Reason for Existence**: Because we can. 😎
