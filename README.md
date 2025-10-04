# Zentrales Mail-Hub (getmail6 + Dovecot)

## Voraussetzungen
- Docker und Docker Compose (Plugin oder Standalone)
- Zertifikate im gewünschten Pfad (`./certs` im Heimnetz oder `/etc/letsencrypt` auf dem VPS)
- Benutzer und Passworthashes für Dovecot (`SHA512-CRYPT`)

## Ersteinrichtung
1. `.env` anpassen (insbesondere `FQDN`, `MAIL_UID`, `MAIL_GID`, `CERTS_HOST_PATH`).
2. `make init` ausführen, damit die benötigten Ordner angelegt werden (`getmail/state`, `getmail/rc`, `certs/live/$FQDN`).
3. Zertifikate in `${CERTS_HOST_PATH}/live/${FQDN}/` bereitstellen (`fullchain.pem`, `privkey.pem`).
4. Benutzer in `dovecot/conf/users` eintragen. Passworthash erzeugen mit:
   ```sh
   doveadm pw -s SHA512-CRYPT
   ```
5. Zugriffsdaten für POP3S-Provider in `getmail/rc/*.rc` pflegen. Standardmäßig landet jede Quelle in einem eigenen IMAP-Ordner (`/mail/Maildir/.ProviderName/`). Wer alles in die INBOX mischen möchte, setzt in der jeweiligen RC-Datei `path = /mail/Maildir/`.
6. Container bauen und starten:
   ```sh
   docker compose build
   docker compose up -d
   ```

## Betrieb
- Dovecot stellt IMAPS auf Port 993 mit Pflicht-SSL bereit. Mailclient-Example:
  - Server: `FQDN` aus `.env`
  - Port: 993
  - Sicherheit: SSL/TLS
  - Benutzername/Passwort: gemäß `dovecot/conf/users`
- getmail6 läuft im eigenen Container und ruft alle 5 Minuten jede `.rc` unter `getmail/rc/` ab. Das State-Verzeichnis (`getmail/state/`) merkt sich, welche Mails bereits abgeholt wurden.
- Unterschied Heimnetz vs. VPS:
  - Heimnetz: Self-Signed-/CA-Zertifikate unter `./certs/live/${FQDN}/`.
  - VPS mit Let’s Encrypt: `CERTS_HOST_PATH=/etc/letsencrypt` in `.env` setzen und Host-Verzeichnis einbinden.
- Datensicherung: Das Docker-Volume `maildata` enthält alle Maildir-Daten. Regelmäßig sichern!

## Nützliche Kommandos
- `make build`, `make up`, `make down`, `make logs` für häufige Compose-Aktionen.
- `docker compose exec dovecot doveadm user '*@*'` zur Benutzerprüfung (bei Bedarf).
