#!/bin/bash
# Run cleanup-recordings.sh and send result to Telegram via NanoClaw IPC

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IPC_DIR="$SCRIPT_DIR/../data/ipc/telegram_main/messages"
CHAT_JID="tg:8606148166"

mkdir -p "$IPC_DIR"

OUTPUT=$("$SCRIPT_DIR/cleanup-recordings.sh" --confirm 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  STATUS="✅ Recordings cleanup succeeded"
else
  STATUS="❌ Recordings cleanup failed (exit $EXIT_CODE)"
fi

# On success show the head (cutoff + what was removed); on failure show the
# tail, where the guard's WARNING and remediation hint live.
if [ $EXIT_CODE -eq 0 ]; then
  SUMMARY=$(echo "$OUTPUT" | head -20)
else
  SUMMARY=$(echo "$OUTPUT" | tail -20)
fi

MESSAGE="$STATUS

$SUMMARY"

# Write IPC message file
TIMESTAMP=$(python3 -c 'import time; print(int(time.time() * 1000))')
MSG_FILE="$IPC_DIR/cleanup-$TIMESTAMP.json"
printf '%s' "{\"type\":\"message\",\"chatJid\":\"$CHAT_JID\",\"text\":$(printf '%s' "$MESSAGE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')}" > "$MSG_FILE"
