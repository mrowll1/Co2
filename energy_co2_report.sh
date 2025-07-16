#!/bin/bash
# Author: Furkan Dincer
# Contact: f.dincer@juelich.de
# Description: Appends energy and CO₂ metrics for all available jobs into a .dat file, skipping duplicates.
#              Timestamp is the actual job START time (UTC) from SLURM.
#              Adjustable lookback time via LOOKBACK_DAYS variable.

LOOKBACK_DAYS=365  # Change this to control how many days to look back
EMISSION_FACTOR=174  # grams CO₂ per kWh
ENERGY_OUTPUT_DIR="OUTPUT DIRECTORY" #enter your directory to save the file here!
OUTPUT_FILE="$ENERGY_OUTPUT_DIR/energy_report.dat"
TEMP_FILE=$(mktemp)

echo "Ensuring output directory exists: $ENERGY_OUTPUT_DIR"
mkdir -p "$ENERGY_OUTPUT_DIR"

# Create header if file doesn't exist
if [ ! -f "$OUTPUT_FILE" ]; then
  printf "%-10s %12s %13s %18s %12s %13s %17s  %-20s %s\n" \
    "JobID" "Scientific_kJ" "Scientific_kWh" "Scientific_CO2_g" "Total_kJ" "Total_KWh" "Total_CO2_g" "Partition" "Timestamp_UTC" > "$OUTPUT_FILE"
fi

ALL_JOBS=$(sacct --format=JobID,State --noheader --starttime=$(date -d "$LOOKBACK_DAYS days ago" +%Y-%m-%d) | \
  grep -E "COMPLETED|FAILED|TIMEOUT" | awk '{print $1}' | grep -v '\.' | sort -u)

NEW_ENTRIES=0
SKIPPED_ENTRIES=0

for JOBID in $ALL_JOBS; do
  if awk -v id="$JOBID" '$1 == id {found=1} END {exit !found}' "$OUTPUT_FILE"; then
    ((SKIPPED_ENTRIES++))
    continue
  fi

  START_TIME=$(sacct -j "$JOBID" --format=Start,Partition --parsable2 --noheader | head -n 1 | cut -d'|' -f1)
  PARTITION=$(sacct -j "$JOBID" --format=Start,Partition --parsable2 --noheader | head -n 1 | cut -d'|' -f2)

  if [ -z "$START_TIME" ]; then
    echo "Skipping JobID $JOBID (no start time)"
    ((SKIPPED_ENTRIES++))
    continue
  fi

  TIMESTAMP=$(date -u -d "$START_TIME" +"%Y-%m-%dT%H:%M:%SZ")

  SCIENTIFIC_JOULES=$(sacct -j "$JOBID" --format=JobID,ConsumedEnergyRaw --parsable2 --noheader | \
    grep "^${JOBID}\." | cut -d'|' -f2 | paste -sd+ - | bc)
  TOTAL_JOULES=$(sacct -j "$JOBID" --format=JobID,ConsumedEnergyRaw --parsable2 --noheader | \
    grep "^${JOBID}|" | grep -v '\.' | cut -d'|' -f2)

  if [ -z "$SCIENTIFIC_JOULES" ] || [ -z "$TOTAL_JOULES" ] || [ "$SCIENTIFIC_JOULES" = "0" ] || [ "$TOTAL_JOULES" = "0" ]; then
    echo "Skipping JobID $JOBID (no valid energy data)"
    ((SKIPPED_ENTRIES++))
    continue
  fi

  echo "Processing JobID $JOBID"

  SCIENTIFIC_KJ=$(echo "scale=3; $SCIENTIFIC_JOULES / 1000" | bc)
  TOTAL_KJ=$(echo "scale=3; $TOTAL_JOULES / 1000" | bc)
  SCIENTIFIC_KWH=$(echo "scale=6; $SCIENTIFIC_JOULES / 3600000" | bc)
  TOTAL_KWH=$(echo "scale=6; $TOTAL_JOULES / 3600000" | bc)
  SCIENTIFIC_CO2=$(echo "$SCIENTIFIC_KWH * $EMISSION_FACTOR" | bc)
  TOTAL_CO2=$(echo "$TOTAL_KWH * $EMISSION_FACTOR" | bc)

  printf "%-10s %12s %13s %18s %12s %13s %17s  %-20s %s\n" \
    "$JOBID" "$SCIENTIFIC_KJ" "$SCIENTIFIC_KWH" "$SCIENTIFIC_CO2" "$TOTAL_KJ" "$TOTAL_KWH" "$TOTAL_CO2" "$PARTITION" "$TIMESTAMP" >> "$OUTPUT_FILE"

  ((NEW_ENTRIES++))
done

# Remove prior data (excluding header and TOTAL)
tail -n +2 "$OUTPUT_FILE" | grep -v "^TOTAL" | grep -v "^JobID" > "$TEMP_FILE"

read TOTAL_SKJ TOTAL_SKWH TOTAL_SCO2 TOTAL_KJ TOTAL_KWH TOTAL_CO2 <<< $(awk '
  BEGIN {SKJ=0; SKWH=0; SCO2=0; TKJ=0; TKWH=0; TCO2=0}
  NF >= 8 {
    SKJ  += $2;
    SKWH += $3;
    SCO2 += $4;
    TKJ  += $5;
    TKWH += $6;
    TCO2 += $7;
  }
  END {printf "%.3f %.6f %.6f %.3f %.6f %.6f", SKJ, SKWH, SCO2, TKJ, TKWH, TCO2}
' "$TEMP_FILE")

{
  printf "%-10s %12s %13s %18s %12s %13s %17s  %-20s %s\n" \
    "TOTAL" "$TOTAL_SKJ" "$TOTAL_SKWH" "$TOTAL_SCO2" "$TOTAL_KJ" "$TOTAL_KWH" "$TOTAL_CO2" "-" "-"
  printf "%-10s %12s %13s %18s %12s %13s %17s  %-20s %s\n" \
    "JobID" "Scientific_kJ" "Scientific_kWh" "Scientific_CO2_g" "Total_kJ" "Total_KWh" "Total_CO2_g" "Partition" "Timestamp_UTC"
  cat "$TEMP_FILE"
} > "$OUTPUT_FILE"

rm "$TEMP_FILE"

echo "✅ Done: $NEW_ENTRIES new entries added. Skipped $SKIPPED_ENTRIES. Lookback = $LOOKBACK_DAYS days."
