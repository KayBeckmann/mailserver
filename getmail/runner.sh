#!/bin/bash
set -euo pipefail

shopt -s nullglob

mkdir -p /getmail/state

log() {
  printf '%s [getmail] %s\n' "$(date -Iseconds)" "$1"
}

SLEEP_SECONDS="${SLEEP_SECONDS:-300}"
MAIL_UID="${MAIL_UID:-1000}"
MAIL_GID="${MAIL_GID:-1000}"

ensure_maildir() {
  target="$1"
  if [ -z "$target" ]; then
    return
  fi

  case "$target" in
    */)
      target="${target%/}"
      ;;
  esac

  case "$target" in
    /mail/*)
      ;;
    *)
      log "Überspringe unerwarteten Zielpfad ${target}"
      return
      ;;
  esac

  new_setup=false
  if [ ! -d "$target" ]; then
    new_setup=true
  elif [ ! -d "$target/cur" ] || [ ! -d "$target/new" ] || [ ! -d "$target/tmp" ]; then
    new_setup=true
  fi

  mkdir -p "$target" || return
  mkdir -p "$target/cur" "$target/new" "$target/tmp" || return
  if [ "$new_setup" = true ]; then
    log "Maildir vorbereitet: ${target}"
  fi
  chown -R "${MAIL_UID}:${MAIL_GID}" "$target" || true
}

ensure_maildir "/mail/Maildir"

while true; do
  rc_files=(/getmail/rc/*.rc)

  if [ ${#rc_files[@]} -eq 0 ]; then
    log "Keine .rc-Dateien in /getmail/rc gefunden; warte."
  else
    for rc in "${rc_files[@]}"; do
      name=$(basename "$rc")

      dest_path=$(awk -F'=' '/^[[:space:]]*path[[:space:]]*=/{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}' "$rc") || dest_path=""
      if [ -n "$dest_path" ]; then
        ensure_maildir "$dest_path"
      fi

      if getmail --getmaildir /getmail/state --rcfile "$rc" --quiet; then
        log "Abruf erfolgreich für ${name}"
      else
        log "Fehler beim Abruf für ${name}" >&2
      fi
    done
  fi

  sleep "$SLEEP_SECONDS"
done
