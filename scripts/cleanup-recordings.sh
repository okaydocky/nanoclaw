#!/bin/bash
# Cleanup old Frigate recordings — always dry run first, requires --confirm to delete

RECORDINGS_DIR="/Volumes/media/frigate/recordings"
RETENTION_DAYS=100  # buffer above Frigate's 90-day retention (orphan/backstop sweep)

if [ ! -d "$RECORDINGS_DIR" ]; then
  echo "ERROR: $RECORDINGS_DIR not found"
  exit 1
fi

CUTOFF=$(date -v -${RETENTION_DAYS}d +%Y-%m-%d)

echo "Cutoff date: $CUTOFF (keeping $RETENTION_DAYS days)"
echo ""

# Find directories older than cutoff.
# Match ONLY strict YYYY-MM-DD folders so non-date entries (@eaDir, .DS_Store,
# exports, etc.) are never selected for deletion.
OLD_DIRS=$(ls "$RECORDINGS_DIR" | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' | sort | awk -v cutoff="$CUTOFF" '$1 < cutoff')

if [ -z "$OLD_DIRS" ]; then
  echo "Nothing to delete — all recordings are within the retention window."
  exit 0
fi

COUNT=$(echo "$OLD_DIRS" | wc -l | tr -d ' ')
echo "DRY RUN — would delete $COUNT directories:"
echo "$OLD_DIRS"
echo ""

if [ "$1" != "--confirm" ]; then
  echo "Run with --confirm to actually delete."
  exit 0
fi

echo "Deleting..."
echo "$OLD_DIRS" | while read -r dir; do
  [ -z "$dir" ] && continue
  echo "  Removing $dir..."
  # rm -rf removes the whole date folder in one pass: recording files, Synology
  # @eaDir metadata, and the now-empty folder itself. The :? guards abort if
  # either variable is empty so the parent dir can never be targeted.
  rm -rf "${RECORDINGS_DIR:?}/${dir:?}"
done
echo "Done."
