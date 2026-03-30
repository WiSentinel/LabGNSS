# LabGNSS
GNSS lab code | WiSentinel @ PoliTo

## Code Modifications: Gradual Spoofing Implementation

This repository modifies the standard static GNSS spoofing approach into a dynamic, gradual drift to bypass kinematic anomaly detection (e.g., RAIM). The updates are implemented across three files.

### 1. `GNSS lab code/opensource/ProcessGnssMeasScript.m` (Main Script)
* **Added Configuration Parameters:** Introduced `spoof.mode` (`'instant'` or `'gradual'`) and `spoof.t_duration` (drift time in epochs/seconds) to the initial settings.
* **Injected Trajectory Generation:** Added a call to `ApplyGradualSpoof()` immediately after computing the true initial PVT solution. This generates the drift path matrix before the raw measurements are altered.

### 2. `GNSS lab code/opensource/library/ApplyGradualSpoof.m` (New Function)
* **Linear Interpolation (LERP):** Computes a time-varying trajectory between the true starting position and the target spoofed position. 
* **Matrix Generation:** Converts the static single-point target into an N x 3 matrix of LLA coordinates, where each row corresponds to the receiver's location at a specific epoch.
* **Velocity Control:** Uses `t_duration` to calculate the spatial step size per epoch, ensuring the simulated velocity remains realistic and avoids triggering velocity spike flags.

### 3. `GNSS lab code/opensource/library/compute_spoofSatRanges.m` (Measurement Domain)
* **Dynamic Coordinate Indexing:** Replaced the static ECEF position variable with a dynamic index. The loop now extracts the specific row from the trajectory matrix for each epoch.
* **Vectorized Range Updates:** Modified the `Lla2Xyz` transformation and geometric range calculations to update per epoch. This ensures the injected pseudorange offsets perfectly match the moving trajectory at any given second.

---

## Spoofing Configuration Parameters

* **`spoof.active`**: `1` to run the spoofing attack, `0` to process clean data.
* **`spoof.mode`**: `'instant'` (jumps to target in 1 epoch) or `'gradual'` (drifts smoothly over time).
* **`spoof.delay`**: Artificial time delay [s] introduced to the spoofed signals.
* **`spoof.t_start`**: The exact epoch/second when the attack begins.
* **`spoof.t_duration`**: Total time [epochs/s] to travel from the true position to the target. (Ignored if mode is `'instant'`).
* **`spoof.target_position`**: The final destination in LLA coordinates `[Lat, Lon, Alt]`.
