#!/bin/bash
# build-dtbo.sh - Build dtbo.img for Helios-Kernel
# Creates dtbo.img from pineapple* DTBO files

set -e

OUT="/home/ahnaf/helios-kernel-out"
DTBO_DIR="$OUT/arch/arm64/boot/dts/qcom"
DTBO_OUT="/home/ahnaf/AnyKernel3/dtbo.img"

echo "Building dtbo.img for Helios-Kernel..."

# Create temp directory
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

mkdir -p "$TMP_DIR/dtbo_files"

# Find all pineapple*.dtbo files (exclude cliffs7 and other non-pineapple files)
echo "Collecting pineapple DTBO files..."
while IFS= read -r dtbo_file; do
    filename=$(basename "$dtbo_file")
    cp "$dtbo_file" "$TMP_DIR/dtbo_files/$filename"
done < <(find "$DTBO_DIR" -name "pineapple*.dtbo" -type f 2>/dev/null)

# Count collected files
DTBO_COUNT=$(ls "$TMP_DIR/dtbo_files" 2>/dev/null | wc -l)
if [ "$DTBO_COUNT" -eq 0 ]; then
    echo "ERROR: No pineapple DTBO files found!"
    exit 1
fi

echo "Found $DTBO_COUNT DTBO files"

# Create dtbo.img using Python
python3 << PYTHON_SCRIPT
import struct
import os
import sys
import glob

DTBO_MAGIC = 0x7b7ab1e
TMP_DIR = "$(echo $TMP_DIR)"
OUTPUT = "$DTBO_OUT"

# Get all dtbo files sorted
dtbo_files = sorted(glob.glob(f"{TMP_DIR}/dtbo_files/pineapple*.dtbo"))

if not dtbo_files:
    print("ERROR: No DTBO files found!")
    sys.exit(1)

print(f"Creating dtbo.img with {len(dtbo_files)} entries...")

# dtbo entry header (24 bytes)
header_size = 24

entries = []
for idx, filepath in enumerate(dtbo_files):
    with open(filepath, 'rb') as f:
        data = f.read()

    filename = os.path.basename(filepath)
    dt_size = len(data)
    total_size = header_size + dt_size
    aligned_size = (total_size + 7) & ~7

    entry = {
        'filename': filename,
        'data': data,
        'dt_size': dt_size,
        'total_size': total_size,
        'aligned_size': aligned_size,
        'dt_offset': header_size,
        'id': idx,
        'rev': 0,
        'flags': 0,
    }
    entries.append(entry)

# Calculate total image size
header_base = 8
image_size = header_base
for e in entries:
    image_size += e['aligned_size']

# Create the dtbo.img
with open(OUTPUT, 'wb') as f:
    # Write header (8 bytes)
    f.write(struct.pack('<I', len(entries)))  # dtbocnt
    f.write(struct.pack('<I', header_base))   # headersz

    # Write entries
    for e in entries:
        # Write header (24 bytes)
        f.write(struct.pack('<I', DTBO_MAGIC))       # magic
        f.write(struct.pack('<I', e['total_size']))  # total_size
        f.write(struct.pack('<I', e['dt_size']))     # dt_size
        f.write(struct.pack('<I', e['dt_offset']))   # dt_offset
        f.write(struct.pack('<I', e['id']))          # id
        f.write(struct.pack('<I', e['rev']))          # rev
        f.write(struct.pack('<I', e['flags']))       # flags
        f.write(struct.pack('<I', 0))                 # unused

        # Write FDT data
        f.write(e['data'])

        # Pad to aligned size
        padding = e['aligned_size'] - e['total_size']
        if padding > 0:
            f.write(b'\x00' * padding)

print(f"Created {OUTPUT} ({image_size} bytes)")
print(f"Entries: {len(entries)}")
PYTHON_SCRIPT

echo "dtbo.img build complete!"
echo "Output: $DTBO_OUT"
