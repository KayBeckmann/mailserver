# Zentrales Mail-Hub (getmail6 + Dovecot)

## Voraussetzungen
- Docker und Docker Compose (Plugin oder Standalone)
- Für VPS-Betrieb: Port 80 für Let's Encrypt erreichbar
- Benutzer und Passworthashes für Dovecot (`SHA512-CRYPT`)

## Ersteinrichtung
1. `.env` anpassen (insbesondere `FQDN`, `MAIL_UID`, `MAIL_GID`).
   - `CERT_MODE=home`: Self-Signed-Zertifikate werden beim Start des Dovecot-Containers automatisch erzeugt.
   - `CERT_MODE=vps`: Dovecot erwartet gültige Zertifikate unter `${CERTS_HOST_PATH}/live/${FQDN}/`.
   - `CERTBOT_EMAIL`, `CERTBOT_STAGING`, `CERTBOT_RENEW_INTERVAL` sind relevant, falls der Certbot-Container genutzt wird.
2. `make init` ausführen, damit die benötigten Ordner angelegt werden (`getmail/state`, `getmail/rc`, `certs/live/$FQDN`).
3. Benutzer in `dovecot/conf/users` eintragen. Passworthash erzeugen mit:
   ```sh
   doveadm pw -s SHA512-CRYPT
   ```
4. Zugriffsdaten für POP3S-Provider in `getmail/rc/*.rc` pflegen. Standardmäßig landet jede Quelle in einem eigenen IMAP-Ordner (`/mail/Maildir/.ProviderName/`). Wer alles in die INBOX mischen möchte, setzt in der jeweiligen RC-Datei `path = /mail/Maildir/`.
5. Container bauen und starten:
   ```sh
   docker compose build
   docker compose up -d
   ```

## Zertifikate
- **Heimnetz (`CERT_MODE=home`)**
  - `CERTS_HOST_PATH` zeigt standardmäßig auf `./certs`.
  - Beim Start erzeugt der Dovecot-Container automatisch ein Self-Signed-Zertifikat (`fullchain.pem`, `privkey.pem`) unter `./certs/live/${FQDN}/`, falls noch keines vorhanden ist.
  - Vertrauen muss auf allen Clients manuell eingerichtet werden (z. B. eigene CA verteilen).

- **VPS (`CERT_MODE=vps`)**
  - Setze `CERTS_HOST_PATH=/etc/letsencrypt` und `CERT_MODE=vps` in `.env`.
  - Starte zusätzlich den Certbot-Container (Profil `vps`):
    ```sh
    COMPOSE_PROFILES=vps docker compose up -d certbot
    ```
  - Der Container holt automatisch Let’s-Encrypt-Zertifikate per HTTP-01-Challenge (Port 80 muss öffentlich erreichbar sein) und erneuert sie regelmäßig.
  - Dovecot nutzt die Zertifikate aus demselben Host-Verzeichnis (`/etc/letsencrypt/live/${FQDN}/`).
  - Für Tests kann `CERTBOT_STAGING=true` gesetzt werden.

## Betrieb
- Dovecot stellt IMAPS auf Port 993 mit Pflicht-SSL bereit. Mailclient-Example:
  - Server: `FQDN` aus `.env`
  - Port: 993
  - Sicherheit: SSL/TLS
  - Benutzername/Passwort: gemäß `dovecot/conf/users`
- getmail6 läuft im eigenen Container und ruft alle 5 Minuten jede `.rc` unter `getmail/rc/` ab. Das State-Verzeichnis (`getmail/state/`) merkt sich, welche Mails bereits abgeholt wurden.
- Datensicherung: Das Docker-Volume `maildata` enthält alle Maildir-Daten. Regelmäßig sichern!

## Nützliche Kommandos
- `make build`, `make up`, `make down`, `make logs` für häufige Compose-Aktionen.
- VPS: `COMPOSE_PROFILES=vps make up` startet zusätzlich den Certbot-Container.
- `docker compose exec dovecot doveadm user '*@*'` zur Benutzerprüfung (bei Bedarf).
