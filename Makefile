ifneq (,$(wildcard .env))
include .env
export $(shell sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' .env)
endif

.PHONY: init build up down logs

init:
	mkdir -p getmail/state
	mkdir -p getmail/rc
	mkdir -p certs/live/$(FQDN)

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f
