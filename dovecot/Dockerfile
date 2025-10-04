FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends dovecot-imapd dovecot-lmtpd ca-certificates libcap2-bin openssl \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1000 mailhub \
    && useradd --uid 1000 --gid 1000 --home /home/mailhub --create-home --shell /usr/sbin/nologin mailhub

RUN setcap 'cap_net_bind_service=+ep' /usr/sbin/dovecot

RUN mkdir -p /run/dovecot \
    && chown root:root /run/dovecot

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["/mail", "/etc/dovecot", "/certs"]

EXPOSE 993

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["dovecot", "-F"]
