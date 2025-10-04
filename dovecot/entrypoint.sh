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
CONFIG_SRC_DIR="/etc/dovecot"
CONFIG_RUNTIME_DIR="/tmp/dovecot-config"
AUTH_FILE_NAME="auth-passwdfile.conf.ext"
BASE_DIR="/run/dovecot"
MAIL_ROOT="/mail"

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

prepare_config() {
  rm -rf "${CONFIG_RUNTIME_DIR}"
  cp -r "${CONFIG_SRC_DIR}" "${CONFIG_RUNTIME_DIR}"

  sed -i "s|@FQDN@|${FQDN}|g" "${CONFIG_RUNTIME_DIR}/dovecot.conf"
  mkdir -p "${BASE_DIR}"
  chown root:root "${BASE_DIR}" || true
  chmod 755 "${BASE_DIR}" || true

  AUTH_FILE_PRIMARY="${CONFIG_RUNTIME_DIR}/${AUTH_FILE_NAME}"
  AUTH_FILE_IN_CONF="${CONFIG_RUNTIME_DIR}/conf.d/${AUTH_FILE_NAME}"

  if [ -f "${AUTH_FILE_PRIMARY}" ]; then
    sed -i "s|@MAIL_UID@|${MAIL_UID}|g" "${AUTH_FILE_PRIMARY}"
    sed -i "s|@MAIL_GID@|${MAIL_GID}|g" "${AUTH_FILE_PRIMARY}"
  fi

  if [ -f "${AUTH_FILE_IN_CONF}" ]; then
    sed -i "s|@MAIL_UID@|${MAIL_UID}|g" "${AUTH_FILE_IN_CONF}"
    sed -i "s|@MAIL_GID@|${MAIL_GID}|g" "${AUTH_FILE_IN_CONF}"
  fi

  if [ -f "${AUTH_FILE_PRIMARY}" ] && [ ! -f "${AUTH_FILE_IN_CONF}" ]; then
    cp "${AUTH_FILE_PRIMARY}" "${AUTH_FILE_IN_CONF}"
  fi
}

ensure_maildir() {
  mkdir -p "${MAIL_ROOT}/Maildir"
  chown -R "${MAIL_UID}:${MAIL_GID}" "${MAIL_ROOT}"
}

if [ "${CERT_MODE}" = "home" ]; then
  prepare_self_signed
else
  wait_for_external_cert
fi

ensure_maildir

prepare_config

if [ "$1" = "dovecot" ]; then
  set -- "$1" "-F" "-c" "${CONFIG_RUNTIME_DIR}/dovecot.conf"
fi

exec "$@"
