# ACC RTV Tour Tester — User Guide

This guide walks you through the four-step workflow for creating and testing RTV tours with the ACC RTV Tour Tester.

## Quick Start

1. **Clone the repository**
2. **Run** `Start-RTVTourBuilder.ps1` (PowerShell)
3. **Open the app:** [http://localhost:3110/index.html](http://localhost:3110/index.html)

When the script starts, it may prompt for RTV Mock API credentials; the app will not work without network access to the API.

---

## Prerequisites

- **PowerShell** (to run `Start-RTVTourBuilder.ps1`)
- **VPN/Network** access to the RTV Mock API
- **TPW** (Transport Planning Workbench) access
- A valid **transport XML** from TPW

---

## Step 1: Validate


1. Paste the full transport XML into the **Tour Body** field.
2. Click **Validate**.
3. The app runs 5 checks (shown as horizontal badges):

| Check | What it verifies |
|---|---|
| **RTV Enabled** | Transport has RTV tracking turned on |
| **Carrier 313520 Assigned** | Carrier ID matches 313520 |
| **Loading Station Found** | Loading station name and city are present |
| **Loading Window Active** | `until_date` is today and `until_time` is in the future |
| **Last Unloading in Future** | Unloading date has not passed |

4. All checks must pass (green). If any fail, fix the transport in TPW and re-paste.
5. The header shows **Transport** number, **Company**, and **Route** once validated.
6. Click **Next** to proceed.

---

## Step 2: Vehicles

1. The app loads all vehicles from the RTV Mock API.
2. **Occupied Vehicles** — vehicles with active tours. Use **Delete** to free one if needed.
3. **Available Vehicles** — pick one by clicking **Select**.
4. The selected license plate is **copied to your clipboard** automatically.
5. Go to **TPW → Accepted Transports → Allocate** and paste the license plate.
6. Click **Next** when allocation in TPW is done.

---

## Step 3: Tour Map

1. The map shows the loading and unloading stations (stops 2 and 5, locked).
2. You need to place **4 stops** by clicking on the map:
   - **Stop 1** — Approach to loading (before the loading station)
   - **Stop 3** — Depart loading (after the loading station)
   - **Stop 4** — Approach to unloading (before the unloading station)
   - **Stop 6** — Depart unloading (after the unloading station)
3. Place stops in a logical route order along the road.
4. Use the **x** button on a stop card to remove and re-place it.
5. Once all stops are placed, the **JSON Payload** preview updates.
6. Click **Create Tour** to submit.
7. The button turns green with "Tour Created" on success.
8. Click **Next** to go to the Status Monitor.

---

## Step 4: Status

1. Click **Current Status** to fetch live tracking data.
2. Each tracked vehicle shows a card with: position, ETA, speed, fuel, etc.
3. Use **Delete Tour** on any card to remove the tour once testing is complete.
4. Click **Back** to return to the Tour Map.

---


