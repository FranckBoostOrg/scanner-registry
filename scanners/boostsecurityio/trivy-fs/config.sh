#!/bin/bash

BOOST_CONFIG_FILE=${BOOST_CONFIG_FILE:-boost.yaml}

# Launching the setup util container
docker run -d --entrypoint tail --mount type=bind,src=$(pwd),dst=/woorkdir --mount type=bind,src=$(echo ~),dst=/root --workdir /workdir --name setup_utils python:3 -f /dev/null
docker exec setup_utils apt-get update

# Local config parse
config_parser() {
    if [ -f "boost.yml" ]
    then
        docker exec setup_utils apt-get install -y jq
        docker exec setup_utils python -m pip install yq
        docker exec setup_utils yq --raw-output '. | to_entries[] | "BOOST_" + .key + "=" + (.value | tostring)' boost.yml > .boost_env
        set -a
        source .boost_env
        set +a
    fi
}

# Java setup
java_gradle_setup() {
    if [ "$(find . -name "gradle.lockfile" | wc -l)" != "0" ]
    then
        # Gradle lockfile found nothing to do
        return 0
    fi
    if [ "$(find . -path "./gradle/verification-metadata.xml" | wc -l)" != "1" ]
    then 
        # Gradle verification-metadata not found nothing to do
        return 0
    fi
    docker exec setup_utils apt-get install -y jq
    docker exec setup_utils python -m pip install yq
    docker exec setup_utils xq --raw-output '.["verification-metadata"].components[][] | .["@group"] + ":" + .["@name"] + ":" + .["@version"]' ./gradle/verification-metadata.xml > gradle.lockfile
}

java_setup() {
    java_gradle_setup
}

# Python setup
pip_setup() {
    requirements_files="$(find . -name "requirements.txt" | wc -l)"
    if [ "$(echo $requirements_files | wc -l)" == "0"]
    then
        # No requirements.txt nothing to do
        return
    fi
    if [ ! -z "$BOOST_PIP_INDEX_URL" ] && [ ! -z "$BOOST_FORCE_SCAN" ]
    then
        # No PIP_INDEX_URL nor BOOST_FORCE_SCAN --> nothing to do
        return
    fi
    docker exec setup_utils python -m pip install pipenv --user
    docker exec setup_utils python -m pip install pipenv --user
}

if [ "$(find . -name "requirement.xt" | wc -l)" != "0" && $BOOST_FORCE_SCAN ]
then
    DOCKER_OPTS="--entrypoint bash --workdir /tmp"
    DOCKER_OPTS="$DOCKER_OPTS --mount type=bind,src=$(pwd),dst=/tmp"
    DOCKER_OPTS="$DOCKER_OPTS --mount type=bind,src=$(echo ~),dst=/root"
    DOCKER_OPTS="$DOCKER_OPTS -e BOOST_PIP_INDEX_URL=$PIP_INDEX_URL"

    CMD="pip install pipenv --user && export PIP_INDEX_URL=$BOOST_PIP_INDEX_URL"
    CMD="$CMD "'~'"/.local/bin/pipenv install -r requirements.txt"
    docker run $DOCKER_OPTS python:3 -c "$CMD"
fi

config_parser
java_setup

docker container rm -f setup_utils