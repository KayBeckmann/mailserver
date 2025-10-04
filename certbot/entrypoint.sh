#!/bin/sh
set -eu

FQDN="${FQDN:?FQDN muss gesetzt sein}"
CERTBOT_EMAIL="${CERTBOT_EMAIL:?CERTBOT_EMAIL muss gesetzt sein}"
CERTBOT_STAGING="${CERTBOT_STAGING:-false}"
CERTBOT_RENEW_INTERVAL="${CERTBOT_RENEW_INTERVAL:-43200}"
CERTBOT_EXTRA_ARGS=""

if [ "${CERTBOT_STAGING}" = "true" ]; then
  CERTBOT_EXTRA_ARGS="${CERTBOT_EXTRA_ARGS} --staging"
fi

CERT_PATH="/etc/letsencrypt/live/${FQDN}"

obtain_certificate() {
  echo "[certbot] Fordere Zertifikat für ${FQDN} an" >&2
  certbot certonly --standalone --preferred-challenges http \
    --non-interactive --agree-tos \
    --email "${CERTBOT_EMAIL}" \
    -d "${FQDN}" ${CERTBOT_EXTRA_ARGS}
}

if [ ! -f "${CERT_PATH}/privkey.pem" ] || [ ! -f "${CERT_PATH}/fullchain.pem" ]; then
  obtain_certificate
else
  echo "[certbot] Bestehendes Zertifikat gefunden; starte Erneuerungsschleife" >&2
fi

while true; do
  certbot renew --standalone --preferred-challenges http ${CERTBOT_EXTRA_ARGS} || true
  sleep "${CERTBOT_RENEW_INTERVAL}"
done
