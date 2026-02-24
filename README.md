# ACC RTV Tour Tester

Testing Real Time Tracking and Visibility (RTV) for RTV transports currently requires a manual, multi-tool workflow: verifying transport XML parameters, cross-referencing vehicle availability across Postman collections, manually constructing JSON payloads with geocoordinates, and juggling between TPW, Postman, and RTV interfaces. This process is error-prone, time-consuming, and inaccessible to team members unfamiliar with the API tooling.


The ACC RTV Tour Tester is a single-page web application that consolidates the entire RTV testing workflow into a guided, four-step process. Users paste a transport XML, the app validates it and extracts route data, assists with vehicle selection, provides an interactive map for tour construction, and submits the tour to the RTV Mock API — all from one interface.

## Prerequisites

- **Podman** (or Docker) installed
- **PowerShell** (to run `Start-RTVTourBuilder.ps1`)
- Network access to the RTV Mock API (e.g. VPN if required)

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/larkinmaxim/ACC_RTV_Tour_Tester.git
   ```
2. **Run** `Start-RTVTourBuilder.ps1` — builds the app image with Podman, may prompt for API credentials, then starts the container and serves the app on port 3110.
3. **Open the app:** [http://localhost:3110/index.html](http://localhost:3110/index.html)

---

## Usage Guide
A guided web application for creating and testing RTV (Real-Time Visibility) tours through a 4-step workflow.

### Step 0: Guide
Review the visual instructions showing the 4-step workflow.

### Step 1: Validate
1. Copy transport XML from TPW
2. Paste into the Tour Body field
3. Click **Validate**
4. Ensure all 5 checks pass (green badges)

### Step 2: Vehicles
1. Review occupied and available vehicles
2. Delete tours to free vehicles if needed
3. Click **Select** on an available vehicle
4. Paste the license plate in TPW → Allocate

### Step 3: Tour Map
1. Loading and unloading stations are auto-placed
2. Click the map to place 4 additional stops:
   - Approach to loading
   - Depart loading
   - Approach to unloading
   - Depart unloading
3. Click **Create Tour**

### Step 4: Status
1. Click **Current Status** to fetch tracking data
2. View real-time vehicle information
3. Use **Delete Tour** when testing is complete

---

## Configuration

The proxy forwards API requests to the Telemetry API:

- **Auth:** Basic authentication — credentials are **not** in code; you enter them when running the start script or set `RTV_API_USERNAME` and `RTV_API_PASSWORD` when starting the container.

---


## Project Structure

```
.
├── index.html          # Main application (single-page app)
├── proxy.js            # Express proxy + static file server
├── package.json        # Dependencies (Bun)
├── Dockerfile          # Container build instructions
└── Documentation/
    └── User-Guide.md   # Detailed user documentation
```

---

## Technical Details

- **Frontend:** Vanilla JavaScript, Leaflet.js for maps
- **Backend:** Express.js proxy server
- **Container:** Bun Alpine Linux
- **Port:** 3110 (proxy + static files)

---

## License

Internal tool for Transporeon ACC team.
