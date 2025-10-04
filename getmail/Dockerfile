FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates bash \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1000 getmail \
    && useradd --uid 1000 --gid 1000 --system --home /mail --shell /usr/sbin/nologin getmail

WORKDIR /mail

RUN pip install --no-cache-dir getmail6

COPY runner.sh /usr/local/bin/runner.sh
RUN chmod +x /usr/local/bin/runner.sh

VOLUME ["/mail", "/getmail/rc", "/getmail/state"]

USER getmail

CMD ["/usr/local/bin/runner.sh"]
