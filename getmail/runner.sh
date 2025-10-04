#!/bin/bash
set -euo pipefail

shopt -s nullglob

mkdir -p /getmail/state

log() {
  printf '%s [getmail] %s\n' "$(date -Iseconds)" "$1"
}

SLEEP_SECONDS="${SLEEP_SECONDS:-300}"

while true; do
  rc_files=(/getmail/rc/*.rc)

  if [ ${#rc_files[@]} -eq 0 ]; then
    log "Keine .rc-Dateien in /getmail/rc gefunden; warte."
  else
    for rc in "${rc_files[@]}"; do
      name=$(basename "$rc")
      if getmail --getmaildir /getmail/state --rcfile "$rc" --quiet; then
        log "Abruf erfolgreich für ${name}"
      else
        log "Fehler beim Abruf für ${name}" >&2
      fi
    done
  fi

  sleep "$SLEEP_SECONDS"
done
