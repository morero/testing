#!/bin/bash

set -euo pipefail
 
TIMEOUT="3m"
YSQL_CMD="/home/yugabyte/bin/ysqlsh"
DB_SERVER="yb-tservers"

_waitUntilHealthy() {
    declare -a YSQL_CONNINFO
    YSQL_CONNINFO+=("${1}" -h "${2}" -c "\\conninfo")

    printf "YSQL: %s\n" "${YSQL_CONNINFO[@]}"

    while ! "${YSQL_CONNINFO[@]}"; do
        sleep 10s
    done
}

_checkDatabase() {
    timeout "${TIMEOUT}" bash -c "_waitUntilHealthy ${YSQL_CMD} ${DB_SERVER}"
}

_createDatabase() {
    local DB_NAME="${1}"
    declare -a YSQL_CREATE_DB
    YSQL_CREATE_DB+=("${YSQL_CMD}" -h "${DB_SERVER}" -c "CREATE DATABASE ${DB_NAME};")
    printf "YSQL: %s\n" "${YSQL_CREATE_DB[@]}"

    if ! "${YSQL_CREATE_DB[@]}"; then
        printf "could not create database: %s\n" "${DB_NAME}"
        exit 1
    else
        printf "created database: %s\n" "${DB_NAME}"
    fi
}

_main() {
#    export -f _waitUntilHealthy

#    if ! _checkDatabase; then
#        printf "timeout while waiting for database\n"
#        exit 1
#    fi

#    printf "database is ready\n"

 #   _createDatabase gitea
}

_main "$@"
