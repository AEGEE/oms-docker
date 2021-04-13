#!/bin/bash
# THIS IS RUN ON THE GUEST MACHINE

# Structure: now everything here will be a target of makefile.
# Then helper.sh will be called by the target with correct parameter for
# the shell script

# with this file you can:

# CATEGORY: DEV
# bump the version of the oms submodules and commit (currently not there)
bump_repo ()
{
    git submodule foreach "git checkout master && git pull"
    git add "$(git submodule status | grep '^+' |  awk '{ print $2 }')"
    #if something is staged, do the following two lines
    git diff --cached --quiet
    #shellcheck disable=SC2181
    if (( "$?" )); then
        git checkout -b "bump-submodules-$(date '+%d-%m')-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 4)"
        git commit -m "chore(bump): Bump version of the submodules via make bump"
    fi
}

bump_single_module ()
{
    cd "${1}" || { echo "no folder ${1}!" && exit 189 ; }
    git checkout master && git pull
    cd ..
    git add "${1}"
    #if something is staged, do the following two lines
    git diff --cached --quiet
    #shellcheck disable=SC2181
    if (( "$?" )); then
        git checkout -b "bump-submodules-$(date '+%d-%m')-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 4)"
        git commit -m "chore(bump): Bump version of the submodule via make bump module=${1}"
    fi
}

# bump the version of the oms submodules and do not commit
bump_nocommit ()
{
    git submodule foreach "git checkout master && git pull"
}

#CATEGORY: DEPLOY
# 'create first secrets' is in start.sh
# FIRST DEPLOYMENT
init_boot ()
{
  if [[ ! -f .init ]]; then
    #always check if the repo is "complete"
    git submodule update --init

    docker network inspect OMS &>/dev/null || (echo -e "[MyAEGEE] Creating 'OMS' docker network" && docker network create OMS)

    touch "${DIR}"/secrets/acme.json # to avoid making it think it's a folder
    chmod 600 "${DIR}"/secrets/acme.json # Traefik doesn't let ACME challenge go through otherwise

    touch "${DIR}"/gateways/docker/traefik/traefik.toml # to avoid making it think it's a folder
    if [[ "${MYAEGEE_ENV}" != "development" ]]; then
      envsubst < "${DIR}"/gateways/docker/traefik/traefik.toml.template > "${DIR}"/gateways/docker/traefik/traefik.toml
    else
      cat "${DIR}"/gateways/docker/traefik/traefik.toml.dev > "${DIR}"/gateways/docker/traefik/traefik.toml
    fi

    echo -e "\n[Deployment] Setting secrets\n"
    bash "${DIR}"/vagrant-post-script/generate_secrets.sh

    echo "manual things still to do (if applicable use-case): "
    echo "  init cachet files (oms-status/docker/setup.sh)"
    echo "  init grafana config with the slack token (vim monitor/docker/config/gf-provisioning/notifiers/conf.yml)"
    echo "  init prometheus scraping config with the basic auth (vim monitor/docker/config/prometheus.yml)"
    touch .init
  else
    echo "already initialised"
  fi
}

# change passwords (calls an external script)
# ONLY ON FIRST DEPLOYMENT
pw_changer ()
{
    echo -e "\n[Deployment] Setting passwords\n"
    bash "${DIR}"/password-setter.sh
}

# wrapper for the compose mess (ACCEPTS PARAMETERS)
compose_wrapper ()
{ #TO DO: put hostname check and do not accept the nuke and stop in production
    service_string=$(printenv ENABLED_SERVICES)
    # shellcheck disable=SC2206
    services=( ${service_string//:/ } )
    command=( docker-compose -f "${DIR}/base-docker-compose.yml" )
    for s in "${services[@]}"; do
        if [[ -f "${DIR}/${s}/docker/docker-compose.yml" ]]; then
            if [[ "${MYAEGEE_ENV}" == "production" ]]; then
              command+=( -f "${DIR}/${s}/docker/docker-compose.yml" )
            else
              command+=( -f "${DIR}/${s}/docker/docker-compose.yml" -f "${DIR}/${s}/docker/docker-compose.dev.yml" )
            fi
        else
            echo -e "[MyAEGEE] WARNING: No docker file found for ${s} (full path ${DIR}/${s}/docker/docker-compose.yml)"
        fi
    done
    command+=( "${@}" )
    if ( $verbose ); then
        echo -e "\n[MyAEGEE] Full command:\n${command[*]}\n"
    fi
    "${command[@]}"
    return $?
}

# edit the env file before launching
# FIRST DEPLOYMENT
edit_env_file ()
{
    EDITOR=$(env | grep EDITOR | grep -oe '[^=]*$');
    export EDITOR;
    if [ -z "${EDITOR}" ]; then
      echo "[Deployment] no EDITOR variable, setting it to vim"
      export EDITOR="vim";
    fi
    if ( ! ${NON_INTERACTIVE} ); then
        #Ask if one wants to tweak the .env before starting it up
        echo "Do you wish to edit .env file? (write the number)"
        select yn in "Yes" "No"; do
        case $yn in
            Yes ) "${EDITOR}" "${DIR}"/.env; break;;
            No ) break;;
        esac
        done
    fi
}

# https://unix.stackexchange.com/questions/82598/how-do-i-write-a-retry-logic-in-script-to-keep-retrying-to-run-it-upto-5-times
function retry {
  local n=1
  local max=120
  local delay=1
  while true; do
    # shellcheck disable=SC2015
    {
      docker inspect --format '{{json .State.Health.Status }}' "${1}" | grep 'healthy'
    } && break || {
      if [[ ${n} -lt ${max} ]]; then
        ((n++))
        echo "Command failed. Attempt ${n}/${max}."
        sleep ${delay};
      else
        fail "The command has failed after ${n} attempts."
      fi
    }
  done
}

# HUMAN INTERVENTION NEEDED: register in .env your services
## Export all environment variables from .env to this script in case we need them some time
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# https://stackoverflow.com/questions/19331497/set-environment-variables-from-file-of-key-value-pairs
if [[ $(uname) == "Linux" ]]; then
# shellcheck disable=SC2046
  export $(grep -v '^#' "${DIR}/.env" | xargs -d '\n')
else #macos
# shellcheck disable=SC2046
  export $(grep -v '^#' "${DIR}/.env" | gxargs -d '\n')
fi
if [[ "${MYAEGEE_ENV}" != "production" && "${MYAEGEE_ENV}" != "development" ]]; then
  echo "Error: MYAEGEE_ENV can only be 'production' or 'development'"
  exit 1
fi

HOSTNAME="$(hostname)"
export HOSTNAME

# Entry: check if the number of arguments is max 2 (one for the target one for the verbose)
init=false;
build=false;
start=false;
refresh=false;
monitor=false;
stop=false;
down=false;
restart=false;
nuke=false;
bump=false;
bumpmodules=false;
execute=false;
debug=false;
list=false;
pull=false;
wait_until_healthy=false;
verbose=false;
docker=false;
command_num=0;
declare -a arguments # = EMPTY ARRAY
if [[ "$#" -ge 1 ]]; then

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --init) init=true; ((command_num++)); shift ;;
            --build) build=true; ((command_num++)); shift ;;
            --start) start=true; ((command_num++)); shift ;;
            --refresh) refresh=true; ((command_num++)); shift ;;
            --monitor) monitor=true; ((command_num++)); shift ;;
            --stop) stop=true; ((command_num++)); shift ;;
            --down) down=true; ((command_num++)); shift ;;
            --restart) restart=true; ((command_num++)); shift ;;
            --nuke) nuke=true; ((command_num++)); shift ;;
            --bump) bump=true; ((command_num++)); shift ;;
            --bumpmodules) bumpmodules=true; ((command_num++)); shift ;;
            --execute) execute=true; ((command_num++)); shift ;;
            --debug) debug=true; ((command_num++)); shift ;;
            --list) list=true; ((command_num++)); shift ;;
            --pull) pull=true; ((command_num++)); shift ;;
            --wait-until-healthy) wait_until_healthy=true; ((command_num++)); shift ;;
            --docker) docker=true; ((command_num++)); shift ;;
            -v) verbose=true; shift ;;

            --) shift ; arguments+=("${@}"); break ;;

            -*) echo "unknown option: ${1}" 2>&1;
                echo "Usage: helper.sh {--init|--build|--start|--refresh|--monitor|--stop|--down|--restart|--nuke|--execute|--bump|--pull|--wait-until-healthy|--docker} [-v]"; exit 1;;
            *) arguments+=("${1}"); shift;;

        esac
    done

else
    echo "Too few parameters"; exit 1
    echo "Usage: helper.sh {--init|--build|--start|--refresh|--monitor|--stop|--down|--restart|--nuke|--execute|--bump|--docker} [-v]"; exit 1
fi

# shellcheck disable=SC2004
if (( ${command_num} > 1 )); then
    echo "Too many commands! Only one command per time"
    echo "Usage: helper.sh {--init|--build|--start|--refresh|--monitor|--stop|--down|--restart|--nuke|--execute|--bump|--docker} [-v]"; exit 1
fi

# FIRST DEPLOYMENT
#TODO: implement the interactive part
if ( $init ); then
    init_boot && NON_INTERACTIVE=true; edit_env_file && pw_changer
fi

# build it for the first time
# FIRST DEPLOYMENT
if ( $build ); then
    compose_wrapper config > current-config.yml && compose_wrapper build
    exit $?
fi

#pull all, or pull single container
if ( $pull ); then
    compose_wrapper pull "${arguments[@]}"
    exit $?
fi

#start all, or start single container
if ( $start ); then
    compose_wrapper config > current-config.yml && compose_wrapper up -d "${arguments[@]}"
    exit $?
fi

#rebuild all, or rebuild single container
if ( $refresh ); then #THIS IS AN UPGRADING, i.e. CD pipeline target
    compose_wrapper config > current-config.yml && compose_wrapper up -d --build "${arguments[@]}"
    exit $?
fi


# execute command
#compose_wrapper exec #and additional args: the name of the container and the command
#FIXME: with the make target, arguments cannot be specified via cli

if ( $execute ); then
    compose_wrapper exec "${arguments[@]}"
    exit $?
fi

# cheap way to bypass all the safety introduced till now...
if ( $docker ); then
    compose_wrapper "${arguments[@]}"
    exit $?
fi

#
#DEV/UTILS
#

#Brings the submodules to master and commits
if ( $bump ); then
    if [ -z "${arguments[*]}" ]; then
      bump_repo
    else
      bump_single_module "${arguments[*]}"
    fi
fi

#Brings the submodules to master, no commit. Launched by operator
if ( $bumpmodules ); then
    bump_nocommit
fi

#Shows compiled docker-compose manifests
if ( $debug ); then
    compose_wrapper config | tee would-be-config.yml
    exit $?
fi

if ( $list ); then
    compose_wrapper ps
    exit $?
fi

#You can see everything, or pass a container name and monitors only that
#FIXME: with the make target, it cannot follow specific logs (passed as
#  arg to make; only possible via direct invoking of ./helper.sh)
if ( $monitor ); then
    compose_wrapper logs -f --tail=100 "${arguments[@]}"
    exit $?
fi

if ( $wait_until_healthy ); then
    CONTAINER_ID=$(compose_wrapper ps -q "${arguments[@]}")
    echo "Container ID: ${CONTAINER_ID}"
    retry "${CONTAINER_ID}"
fi

#
# DANGER ZONE
#

if ( $stop ); then
  if [[ -n "${arguments[*]}" ]]; then #IF NOT EMPTY, continue: we only want this command to be used for a single container
    compose_wrapper stop "${arguments[@]}" #TODO: improve robustness. if there is rubbish it is still not empty
    exit $?
  fi
  echo "'Stop' must only be used with a container name"
  exit 0
fi

if ( $down ); then
  if [[ -n "${arguments[*]}" ]]; then #IF NOT EMPTY, continue: we only want this command to be used for a single container
    compose_wrapper down "${arguments[@]}" #TODO: improve robustness. if there is rubbish it is still not empty
    exit $?
  fi
  echo "'Down' must only be used with a container name"
  exit 0
fi

if ( $restart ); then
  if [[ -n "${arguments[*]}" ]]; then #IF NOT EMPTY, continue: we only want this command to be used for a single container
    compose_wrapper restart "${arguments[*]}"  #TODO: improve robustness. if there is rubbish it is still not empty
    exit $?
  fi
  echo "'Restart' must only be used with a container name"
  exit 0
fi

if ( $nuke ); then
  if [[ "$(hostname)" == *prod* ]]; then
    echo "DUUUDE you can't kill production" && exit 1;
  else
      compose_wrapper down -v
      exit $?
  fi
fi

#return 0;
