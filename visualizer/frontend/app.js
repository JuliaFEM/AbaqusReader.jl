const { createApp, markRaw } = Vue;

createApp({
    data() {
        return {
            dragging: false,
            loading: false,
            error: null,
            errorDetails: null,
            meshData: null,
            modelData: null,
            fileName: null,
            scene: null,
            camera: null,
            renderer: null,
            controls: null,
            mesh: null,
            solidMesh: null,
            pointsMesh: null,
            apiUrl: 'http://localhost:8081',
            connected: false,
            checking: false,
            infoCollapsed: false,
            statusFading: false,
            fadeTimeout: null
        };
    },

    mounted() {
        this.initThreeJS();
        // Check connection after a short delay to ensure everything is loaded
        setTimeout(() => this.checkConnection(), 500);
        window.addEventListener('resize', this.onWindowResize);
        // Check connection every 5 seconds
        this.connectionInterval = setInterval(() => this.checkConnection(), 5000);
    },

    beforeUnmount() {
        window.removeEventListener('resize', this.onWindowResize);
        if (this.connectionInterval) {
            clearInterval(this.connectionInterval);
        }
        if (this.fadeTimeout) {
            clearTimeout(this.fadeTimeout);
        }
        if (this.renderer) {
            this.renderer.dispose();
        }
    },

    methods: {
        initThreeJS() {
            const container = this.$refs.canvasContainer;

            // Scene - wrapped with markRaw to prevent Vue reactivity
            this.scene = markRaw(new THREE.Scene());
            this.scene.background = new THREE.Color(0x0a0a0a);  // Very dark background

            // Camera
            this.camera = markRaw(new THREE.PerspectiveCamera(
                75,
                container.clientWidth / container.clientHeight,
                0.1,
                10000
            ));
            this.camera.position.set(50, 50, 50);

            // Renderer
            this.renderer = markRaw(new THREE.WebGLRenderer({ antialias: true }));
            this.renderer.setSize(container.clientWidth, container.clientHeight);
            container.appendChild(this.renderer.domElement);

            // Controls
            this.controls = markRaw(new THREE.OrbitControls(this.camera, this.renderer.domElement));
            this.controls.enableDamping = true;
            this.controls.dampingFactor = 0.05;

            // Lights
            const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
            this.scene.add(ambientLight);

            const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
            directionalLight.position.set(1, 1, 1);
            this.scene.add(directionalLight);

            // Grid
            const gridHelper = new THREE.GridHelper(100, 20, 0x888888, 0xdddddd);
            this.scene.add(gridHelper);

            // Axes
            const axesHelper = new THREE.AxesHelper(20);
            this.scene.add(axesHelper);

            // Animation loop
            this.animate();
        },

        animate() {
            requestAnimationFrame(this.animate.bind(this));
            this.controls.update();
            this.renderer.render(this.scene, this.camera);
        },

        onWindowResize() {
            const container = this.$refs.canvasContainer;
            this.camera.aspect = container.clientWidth / container.clientHeight;
            this.camera.updateProjectionMatrix();
            this.renderer.setSize(container.clientWidth, container.clientHeight);
        },

        async checkConnection() {
            this.checking = true;
            // Clear any existing fade timeout and show status
            if (this.fadeTimeout) {
                clearTimeout(this.fadeTimeout);
                this.fadeTimeout = null;
            }
            this.statusFading = false;

            console.log('Checking connection to:', this.apiUrl + '/health');
            try {
                const controller = new AbortController();
                const timeoutId = setTimeout(() => controller.abort(), 3000);

                const response = await fetch(`${this.apiUrl}/health`, {
                    method: 'GET',
                    signal: controller.signal
                });

                clearTimeout(timeoutId);
                const data = await response.json();
                console.log('Health check response:', data);
                this.connected = data.status === 'healthy';
                console.log('Connected:', this.connected);

                // If connected, fade out after 10 seconds
                if (this.connected) {
                    this.fadeTimeout = setTimeout(() => {
                        this.statusFading = true;
                    }, 10000);
                }
            } catch (err) {
                console.log('Connection check failed:', err.message);
                this.connected = false;
            } finally {
                this.checking = false;
            }
        },

        handleDrop(e) {
            this.dragging = false;
            e.preventDefault();
            const files = e.dataTransfer?.files;
            if (files && files.length > 0) {
                this.processFile(files[0]);
            }
        },

        handleFileSelect(e) {
            const files = e.target?.files;
            if (files && files.length > 0) {
                this.processFile(files[0]);
            }
        },

        async processFile(file) {
            if (!file.name.endsWith('.inp')) {
                this.error = 'Please select an ABAQUS .inp file';
                return;
            }

            this.fileName = file.name;
            this.loading = true;
            this.error = null;
            this.errorDetails = null;

            try {
                const content = await file.text();
                await this.parseFile(content);
            } catch (err) {
                this.error = 'Failed to read file: ' + err.message;
                this.loading = false;
            }
        },

        async parseFile(content) {
            try {
                const response = await fetch(`${this.apiUrl}/parse`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'text/plain',
                    },
                    body: content
                });

                const data = await response.json();

                if (data.success) {
                    this.meshData = data;
                    this.modelData = data.model || null;
                    // Force Vue to update before visualizing
                    this.$nextTick(() => {
                        this.visualizeMesh(data);
                    });
                } else {
                    this.error = data.error || 'Unknown error occurred';
                    this.errorDetails = data.error_details || null;
                }
            } catch (err) {
                this.error = 'Failed to connect to backend: ' + err.message;
                this.errorDetails = 'Make sure the backend server is running at ' + this.apiUrl;
            } finally {
                this.loading = false;
            }
        },

        visualizeMesh(data) {
            console.log('visualizeMesh called with data:', data);
            console.log('Nodes:', data.nodes.length, 'Elements:', data.elements.length);

            // Remove old meshes
            if (this.mesh) {
                this.scene.remove(this.mesh);
                this.mesh.geometry.dispose();
                this.mesh.material.dispose();
                this.mesh = null;
            }
            if (this.solidMesh) {
                this.scene.remove(this.solidMesh);
                this.solidMesh.geometry.dispose();
                this.solidMesh.material.dispose();
                this.solidMesh = null;
            }
            if (this.pointsMesh) {
                this.scene.remove(this.pointsMesh);
                this.pointsMesh.geometry.dispose();
                this.pointsMesh.material.dispose();
                this.pointsMesh = null;
            }

            const nodes = data.nodes;
            const elements = data.elements;

            if (nodes.length === 0) {
                this.error = 'No nodes found in mesh';
                return;
            }

            console.log('Creating geometry...');

            // Create geometry
            const geometry = new THREE.BufferGeometry();

            // Vertices
            const vertices = [];
            nodes.forEach(node => {
                vertices.push(node[0], node[1], node[2] || 0);
            });
            geometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3));

            // Edges (wireframe)
            const edges = [];
            const edgeSet = new Set();

            elements.forEach(elem => {
                // Create edges for each element
                for (let i = 0; i < elem.length; i++) {
                    const v1 = elem[i];
                    const v2 = elem[(i + 1) % elem.length];
                    const edge = v1 < v2 ? `${v1}-${v2}` : `${v2}-${v1}`;
                    if (!edgeSet.has(edge)) {
                        edgeSet.add(edge);
                        edges.push(v1, v2);
                    }
                }
            });

            const edgeGeometry = new THREE.BufferGeometry();
            edgeGeometry.setAttribute('position', geometry.getAttribute('position'));
            edgeGeometry.setIndex(edges);

            // Create solid faces with semi-transparent material
            const solidMaterial = new THREE.MeshPhongMaterial({
                color: 0x9558B2,  // Julia purple
                opacity: 0.7,
                transparent: true,
                side: THREE.DoubleSide,
                flatShading: true
            });

            // Create mesh from elements as faces
            const faceIndices = [];
            elements.forEach(elem => {
                // Triangulate faces (simple fan triangulation from first vertex)
                for (let i = 1; i < elem.length - 1; i++) {
                    faceIndices.push(elem[0], elem[i], elem[i + 1]);
                }
            });

            const faceGeometry = new THREE.BufferGeometry();
            faceGeometry.setAttribute('position', geometry.getAttribute('position'));
            faceGeometry.setIndex(faceIndices);
            faceGeometry.computeVertexNormals();

            const solidMesh = markRaw(new THREE.Mesh(faceGeometry, solidMaterial));
            this.solidMesh = solidMesh;
            this.scene.add(solidMesh);
            console.log('Added solid mesh to scene');

            // Create wireframe edges
            const edgeMaterial = new THREE.LineBasicMaterial({
                color: 0x389826,  // Julia green
                linewidth: 2
            });

            // Create mesh - wrapped with markRaw
            this.mesh = markRaw(new THREE.LineSegments(edgeGeometry, edgeMaterial));
            this.scene.add(this.mesh);
            console.log('Added wireframe to scene');

            // Add points for nodes
            const pointsMaterial = new THREE.PointsMaterial({
                color: 0xCB3C33,  // Julia red
                size: 3,
                sizeAttenuation: false
            });
            const points = markRaw(new THREE.Points(geometry, pointsMaterial));
            this.pointsMesh = points;
            this.scene.add(points);
            console.log('Added points to scene');

            // Center and fit camera
            geometry.computeBoundingBox();
            const bbox = geometry.boundingBox;
            const center = new THREE.Vector3();
            bbox.getCenter(center);

            const size = new THREE.Vector3();
            bbox.getSize(size);
            const maxDim = Math.max(size.x, size.y, size.z);

            this.camera.position.set(
                center.x + maxDim * 1.5,
                center.y + maxDim * 1.5,
                center.z + maxDim * 1.5
            );

            this.controls.target.copy(center);
            this.controls.update();

            // Force immediate render
            console.log('Forcing render...');
            this.renderer.render(this.scene, this.camera);
            console.log('Render complete!');
        },

        reset() {
            this.meshData = null;
            this.modelData = null;
            this.fileName = null;
            this.error = null;
            this.errorDetails = null;

            // Remove all mesh objects
            if (this.mesh) {
                this.scene.remove(this.mesh);
                this.mesh.geometry.dispose();
                this.mesh.material.dispose();
                this.mesh = null;
            }
            if (this.solidMesh) {
                this.scene.remove(this.solidMesh);
                this.solidMesh.geometry.dispose();
                this.solidMesh.material.dispose();
                this.solidMesh = null;
            }
            if (this.pointsMesh) {
                this.scene.remove(this.pointsMesh);
                this.pointsMesh.geometry.dispose();
                this.pointsMesh.material.dispose();
                this.pointsMesh = null;
            }
        },

        reportIssue() {
            const title = encodeURIComponent(`Parsing error: ${this.fileName || 'Unknown file'}`);
            const body = encodeURIComponent(
                `## Problem\n\nFailed to parse ABAQUS input file.\n\n` +
                `**File:** ${this.fileName}\n\n` +
                `**Error:** ${this.error}\n\n` +
                `## Steps to Reproduce\n\n` +
                `1. Upload the attached .inp file to the online visualizer\n` +
                `2. Parsing fails with the error above\n\n` +
                `## Additional Context\n\n` +
                `Please attach your .inp file to help us fix this issue.\n`
            );
            window.open(
                `https://github.com/ahojukka5/AbaqusReader.jl/issues/new?title=${title}&body=${body}`,
                '_blank'
            );
        }
    }
}).mount('#app');
