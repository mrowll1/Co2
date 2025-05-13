#!/bin/bash
# Author: Furkan Dincer
# Contact: f.dincer@juelich.de
# Usage: ./energy_co2_report.sh <jobid>

if [ -z "$1" ]; then
  echo "Usage: $0 <jobid>"
  exit 1
fi

JOBID="$1"
EMISSION_FACTOR=475  # grams CO₂ per kWh

# Get scientific compute step energy (.0)
SCIENTIFIC_JOULES=$(sacct -j "$JOBID" --format=JobID,ConsumedEnergyRaw --parsable2 --noheader | \
  grep "^${JOBID}\.0|" | cut -d'|' -f2)

# Get total job footprint energy (top-level job ID)
TOTAL_JOULES=$(sacct -j "$JOBID" --format=JobID,ConsumedEnergyRaw --parsable2 --noheader | \
  grep "^${JOBID}|" | grep -v '\.' | cut -d'|' -f2)

# Check both values
if [ -z "$SCIENTIFIC_JOULES" ]; then
  echo "Could not retrieve scientific compute energy for ${JOBID}.0"
  exit 1
fi

if [ -z "$TOTAL_JOULES" ]; then
  echo "Could not retrieve total energy for job $JOBID"
  exit 1
fi

# Convert to kWh
SCIENTIFIC_KWH=$(echo "scale=6; $SCIENTIFIC_JOULES / 3600000" | bc)
TOTAL_KWH=$(echo "scale=6; $TOTAL_JOULES / 3600000" | bc)

# CO₂ emissions
SCIENTIFIC_CO2=$(echo "$SCIENTIFIC_KWH * $EMISSION_FACTOR" | bc)
TOTAL_CO2=$(echo "$TOTAL_KWH * $EMISSION_FACTOR" | bc)

# Output
echo "--------------------ᓀ ᵥ ᓂ-----------------------"
echo " Job ID:                         $JOBID"
echo ""
echo " ▶ Scientific Compute Step (.0)"
echo "   Energy:                       $SCIENTIFIC_JOULES J"
echo "   Energy (kWh):                 $SCIENTIFIC_KWH kWh"
echo "   CO₂ Emission (scientific):    $SCIENTIFIC_CO2 grams"
echo ""
echo " ▶ Total Job Footprint"
echo "   Energy:                       $TOTAL_JOULES J"
echo "   Energy (kWh):                 $TOTAL_KWH kWh"
echo "   CO₂ Emission (total):         $TOTAL_CO2 grams"
echo "--------------------ᓀ ᵥ ᓂ-----------------------"
