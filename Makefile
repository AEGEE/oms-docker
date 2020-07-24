# ARE ALL COMMANDS IDEMPOTENT??? (do i want them to be?)

include .env
export $(shell sed 's/=.*//' .env)

.PHONY: default init build start bootstrap refresh live_refresh list debug config monitor stop down restart hard_restart \
          nuke_dev clean_docker_dangling_images clean_docker_images clean prune listen_frontend rebuild_frontend rebuild_core \
	  rebuild_events rebuild_statutory rebuild_mailer bump install-agents remove-agents backup_core backup_events \
	  backup_discounts backup_gsuite-wrapper backup_statping backup_statistics backup_security backup_shortener backup_survey

default:
	@echo 'Most common options are bootstrap, start, monitor, live_refresh, restart, nuke_dev, clean (cleans untagged/unnamed images)'

init: #check recursive & make secrets, change pw, change .env file
	./helper.sh -v --init

build: #docker-compose build
	./helper.sh -v --build

start: #docker-compose up -d
	./helper.sh --start

bootstrap: init bump build start

refresh:  build

live_refresh:  # docker-compose up -d --build (CD TARGET)
	./helper.sh --refresh

list: #docker-compose ps
	./helper.sh -v --list

debug:
	./helper.sh -v --debug

config: debug

monitor: #by default it logs everything, to log some containers only, add the name
	./helper.sh --monitor

stop: # docker-compose stop
	./helper.sh --stop

down: # docker-compose down
	./helper.sh --down

restart:
	./helper.sh --down

hard_restart: nuke_dev restart

nuke_dev:   #docker-compose down -v #TODO if needed: make this nuke take into account the .env like in deploy
	./helper.sh --nuke

# Cleanup
clean_docker_dangling_images:
	docker rmi $(shell docker images -qf "dangling=true")

clean_docker_images:
	docker rmi $(shell docker images -q)

clean: clean_docker_images clean_docker_dangling_images

prune: clean
	docker system prune

###How to remove all containers:
#  docker rm $(docker ps -aq)
###How to kill/stop and remove all containers:
#  docker rm $(docker {kill|stop} $(docker ps -aq))

# Development
listen_frontend:
	cd frontend && npm run build -- --watch

rebuild_frontend:
	./helper.sh --docker -- up -d --build --force-recreate frontend

rebuild_core:
	./helper.sh --docker -- up -d --build --force-recreate core

rebuild_events:
	./helper.sh --docker -- up -d --build --force-recreate events

rebuild_statutory:
	./helper.sh --docker -- up -d --build --force-recreate statutory

rebuild_mailer:
	./helper.sh --docker -- up -d --build --force-recreate mailer

bump:
	./helper.sh --bump $(module)

# Monitors
install-agents:
	docker-compose -f oms-global/docker/docker-compose.yml -f oms-monitor-agents/docker/docker-compose.yml up -d

remove-agents:
	docker-compose -f oms-monitor-agents/docker/docker-compose.yml down

# Backups
backup_core:
	./helper.sh --execute postgres-core -- pg_dump 'postgresql://postgres:$${PW_POSTGRES}@localhost/core' --inserts > core.sql.backup-$(shell date +%Y-%m-%dT%H:%M)

backup_events:
	./helper.sh --execute postgres-events -- pg_dump 'postgresql://postgres:$${PW_POSTGRES}@localhost/events' --inserts > events.sql.backup-$(shell date +%Y-%m-%dT%H:%M)

backup_statutory:
	./helper.sh --execute postgres-statutory -- pg_dump 'postgresql://postgres:$${PW_POSTGRES}@localhost/statutory' --inserts > statutory.sql.backup-$(shell date +%Y-%m-%dT%H:%M)

backup_discounts:
	./helper.sh --execute postgres-discounts -- pg_dump 'postgresql://postgres:$${PW_POSTGRES}@localhost/discounts' --inserts > discounts.sql.backup-$(shell date +%Y-%m-%dT%H:%M)

backup_gsuite-wrapper:
	echo "TODO: redis"

backup_statping:
	docker run --volumes-from=myaegee_statping_1 --entrypoint=/bin/bash nouchka/sqlite3 sqlite3 /app/statup.db ".backup '/app/statup.db.backup'" && docker cp myaegee_statping_1:/app/statup.db.backup "/opt/MyAEGEE/statup.db.backup-$(shell date +%Y-%m-%dT%H:%M)"

backup_statistics:
	echo "TODO: prometheus volume (not all of the data is important!)"

backup_security:
	./helper.sh --execute maria-bitwarden -- mysqldump -h"localhost" -u"warden" -p"$${PW_BITWARDEN}" bitwarden' > bitwarden_dump.sql.backup-$(shell date +%Y-%m-%dT%H:%M)

backup_shortener:
	./helper.sh --execute maria-yourls -- mysqldump -h"localhost" -u"yourls" -p"$${PW_YOURLS}" yourls' > yourls_dump.sql.backup-$(shell date +%Y-%m-%dT%H:%M)

backup_survey:
	./helper.sh --execute postgres-limesurvey -- pg_dump 'postgresql://postgres:$${PW_POSTGRES}@localhost/limesurvey' --inserts > limesurvey.sql.backup-$(shell date +%Y-%m-%dT%H:%M)
