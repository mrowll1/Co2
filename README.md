# energy_co2_report.sh

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

Tested on: **JURECA (JSC)**

---

## 🚀 Usage

```bash
chmod +x energy_co2_report.sh
./energy_co2_report.sh <SLURM_JOB_ID>
