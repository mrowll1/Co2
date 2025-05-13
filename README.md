# energy_co2_report.sh

Author: **Furkan Dincer**  
Contact: [f.dincer@juelich.de](mailto:f.dincer@juelich.de)  
Affiliation: Jülich Supercomputing Centre (JSC)

---

A Bash script to calculate the energy consumption and estimated CO₂ emissions of an HPC job on SLURM-managed systems (e.g., JURECA at JSC).  
It separates **scientific compute energy** from the **total job footprint**, enabling accurate sustainability metrics for research workloads.

---

## 🔍 What It Does

This script retrieves job-level energy consumption from SLURM’s accounting system using `sacct`, and computes:

- ⚡ **Scientific Compute Energy** — from the main compute step (usually `.0`)
- 🌍 **Total Job Footprint Energy** — includes all setup, wrapper, and retry steps
- ♻️ **Estimated CO₂ emissions** — using a user-defined CO₂ per kWh factor (default: 475 g CO₂/kWh)

---

## 📦 Requirements

- SLURM with energy accounting enabled
- The following SLURM tools must be available:
  - `sacct`
- Shell tools:
  - `grep`, `cut`, `bc`

Tested on: **JURECA (JSC)** both gpu and cpu!

---

## 🚀 Usage

Just copy the file where ever you want and run with the job ID in the system you want to check. Only important thing is the job ID.

```bash
chmod +x energy_co2_report.sh
./energy_co2_report.sh <SLURM_JOB_ID>

## 📋 Example Output

--------------------ᓀ ᵥ ᓂ-----------------------
 Job ID:                         13657864

 ▶ Scientific Compute Step (.0)
   Energy:                       6291420 J
   Energy (kWh):                 1.747616 kWh
   CO₂ Emission (scientific):    830.117600 grams

 ▶ Total Job Footprint
   Energy:                       18596590 J
   Energy (kWh):                 5.165719 kWh
   CO₂ Emission (total):         2453.716525 grams
--------------------ᓀ ᵥ ᓂ-----------------------
