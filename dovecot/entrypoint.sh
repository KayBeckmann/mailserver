#!/bin/sh
set -eu

if [ "$#" -eq 0 ]; then
  set -- dovecot -F
fi

MAIL_UID="${MAIL_UID:-1000}"
MAIL_GID="${MAIL_GID:-1000}"
CERT_MODE="${CERT_MODE:-home}"
FQDN="${FQDN:-mail.local}"
CERT_ROOT="/certs"
CERT_DIR="${CERT_ROOT}/live/${FQDN}"
KEY_FILE="${CERT_DIR}/privkey.pem"
CERT_FILE="${CERT_DIR}/fullchain.pem"
WAIT_INTERVAL="${CERT_WAIT_INTERVAL:-5}"

prepare_self_signed() {
  mkdir -p "${CERT_DIR}"

  if [ ! -f "${KEY_FILE}" ] || [ ! -f "${CERT_FILE}" ]; then
    echo "[dovecot] Generiere Self-Signed-Zertifikat für ${FQDN}" >&2
    openssl req -x509 -nodes -newkey rsa:4096 -days 825 \
      -keyout "${KEY_FILE}" \
      -out "${CERT_FILE}" \
      -subj "/CN=${FQDN}"
  fi

  chown "${MAIL_UID}:${MAIL_GID}" "${KEY_FILE}" "${CERT_FILE}" || true
  chmod 600 "${KEY_FILE}"
  chmod 644 "${CERT_FILE}"
}

wait_for_external_cert() {
  echo "[dovecot] Warte auf Zertifikate unter ${CERT_DIR}" >&2
  while [ ! -f "${KEY_FILE}" ] || [ ! -f "${CERT_FILE}" ]; do
    sleep "${WAIT_INTERVAL}"
  done
  echo "[dovecot] Zertifikate gefunden" >&2
}

if [ "${CERT_MODE}" = "home" ]; then
  prepare_self_signed
else
  wait_for_external_cert
fi

exec "$@"
