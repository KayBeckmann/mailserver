ifneq (,$(wildcard .env))
include .env
export $(shell sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' .env)
endif

COMPOSE_PROFILES ?=

.PHONY: init build up down logs

init:
	mkdir -p getmail/state
	mkdir -p getmail/rc
	mkdir -p certs/live/$(FQDN)

build:
	COMPOSE_PROFILES=$(COMPOSE_PROFILES) docker compose build

up:
	COMPOSE_PROFILES=$(COMPOSE_PROFILES) docker compose up -d

down:
	COMPOSE_PROFILES=$(COMPOSE_PROFILES) docker compose down

logs:
	COMPOSE_PROFILES=$(COMPOSE_PROFILES) docker compose logs -f
