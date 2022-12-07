#!/bin/bash

set -euo pipefail

HARBOR_PASSWORD="${1:?}"
TEKTON_TOKEN="${2:?}"
HARBOR_USER="ertia"
HARBOR_API="http://registry-harbor-core.registry/api/v2.0"
BASIC_AUTH=$(printf "%s:%s" "${HARBOR_USER}" "${HARBOR_PASSWORD}" | base64)
HARBOR_BASIC_AUTH="Authorization: Basic ${BASIC_AUTH}"

HEADER_ACCEPT="Accept: application/json"
HEADER_CONTENT_TYPE="Content-Type: application/json"

_generate_random_password() {
    local LENGTH="${1:-"48"}"
    local TYPE="${2:-"A-Za-z0-9"}"

    printf "%s" "$(< /dev/urandom tr -dc "${TYPE}" | head -c"${LENGTH}")"
}

_log() {
    local LEVEL="${1:?}"
    local MESSAGE="${2:?}"
    local JSON_MESSAGE="${3:-"NO"}"

    local JQ_MESSAGE_ARG
    if [[ "${JSON_MESSAGE}" == "JSON" ]]; then
        JQ_MESSAGE_ARG="--argjson"
    else
        JQ_MESSAGE_ARG="--arg"
    fi

    jq --compact-output --null-input \
        --arg l "${LEVEL}" \
        "${JQ_MESSAGE_ARG}" m "${MESSAGE}" \
        '{
            "@timestamp": now|strftime("%Y-%m-%dT%H:%M:%S%z"),
            "level": $l,
            "message": $m
        }'
}

_request() {
    local API_PATH="${1:?}"
    local DATA="${2:-"N/A"}"
    local OVERRIDE_HTTP_VERB="${3:-"N/A"}"

    local RESULT
    local HTTP_STATUS
    local BODY
    local RESPONSE

    local HTTP_VERB=()
    if [[ "${OVERRIDE_HTTP_VERB}" != "N/A" ]]; then
        HTTP_VERB=(-X "${OVERRIDE_HTTP_VERB}")
    fi

    local DATA_ARG=()
    if [[ "${DATA}" != "N/A" ]]; then
        DATA_ARG=(-d "${DATA}")
    fi

    RESULT=$(curl -s "${HARBOR_API}${API_PATH}" \
        "${HTTP_VERB[@]}" \
        -w '%{http_code}' \
        -H "${HEADER_ACCEPT}" \
        -H "${HEADER_CONTENT_TYPE}" \
        -H "${HARBOR_BASIC_AUTH}" \
        "${DATA_ARG[@]}"
    )

    HTTP_STATUS=$(printf "%s" "${RESULT}" | tail -c 3)
    BODY=${RESULT::-3}

    if [[ "${BODY}" == "" ]]; then
        BODY="{}"
    fi

    RESPONSE=$(jq --compact-output --null-input \
        --arg status "${HTTP_STATUS}" \
        --argjson body "${BODY}" \
        '{"status": $status|tonumber, "body": $body}'
    )

    printf "%s" "${RESPONSE}"
}

_check() {
    local NAME="${1:?}"
    local END_POINT="${2:?}"
    local __RETURN="${3:?}"
    local ID_NAME="${4:-"id"}"
    local __RETURN_ID="${5:-"RETURN_ID"}"

    local RESPONSE
    RESPONSE=$(_request "/${END_POINT}?q=name=${NAME}")

    local HTTP_STATUS
    HTTP_STATUS=$(printf "%s" "${RESPONSE}" | jq --compact-output '.status')

    local BODY
    BODY=$(printf "%s" "${RESPONSE}" | jq --compact-output '.body')

    local FOUND_NAME
    if [[ "${HTTP_STATUS}" == "200" ]]; then
        FOUND_NAME=$(printf "%s" "${BODY}" | jq --raw-output --compact-output '.[].name')
        if [[ "${FOUND_NAME}" != "" ]]; then
            _log "info" "${END_POINT}: ${NAME}, already exits"
            eval "${__RETURN}"="YES"
            eval "${__RETURN_ID}"="$(printf "%s" "${BODY}" | jq --raw-output --compact-output ".[].${ID_NAME}")"
        else
            _log "info" "${END_POINT}: ${NAME}, not found"
            eval "${__RETURN}"="NO"
            eval "${__RETURN_ID}"="0"
        fi
    else
        _log "error" "${BODY}" "JSON"
        exit 1
    fi
}

_refresh_robot_secret(){
    local USER_ID="${1:?}"
    local USER_TOKEN="${2:?}"

    local DATA
    DATA=$(jq --compact-output --null-input \
        --arg token "${USER_TOKEN}" \
        '{
            "secret": $token
        }'
    )

    local RESPONSE
    RESPONSE=$(_request "/robots/${USER_ID}" "${DATA}" "PATCH")

    local HTTP_STATUS
    HTTP_STATUS=$(printf "%s" "${RESPONSE}" | jq --compact-output '.status')

    local BODY
    BODY=$(printf "%s" "${RESPONSE}" | jq --compact-output '.body')

    if [[ "${HTTP_STATUS}" != "200" ]]; then
        _log "error" "${BODY}" "JSON"
        exit 1
    fi

    _log "info" "refreshed secret for robot account id: ${USER_ID}"
}

_create_robot_user() {
    local USER="${1:?}"
    local USER_TOKEN="${2:-$(_generate_random_password 32)}"

    local PERMISSIONS
    PERMISSIONS='[
      {
        "access": [
          {
            "action": "push",
            "resource": "repository"
          },
          {
            "action": "pull",
            "resource": "repository"
          },
          {
            "action": "read",
            "resource": "helm-chart"
          },
          {
            "action": "create",
            "resource": "helm-chart-version"
          },
          {
            "action": "create",
            "resource": "tag"
          },
          {
            "action": "create",
            "resource": "artifact-label"
          }
        ],
        "kind": "project",
        "namespace": "*"
      }
    ]'

    local DATA
    DATA=$(jq --compact-output --null-input \
        --arg user "${USER}" \
        --arg userDesc "${USER} robot account" \
        --arg token "${USER_TOKEN}" \
        --argjson permissions "${PERMISSIONS}" \
        '{
            "secret": $token,
            "disable": false,
            "name": $user,
            "level": "system",
            "duration": -1,
            "description": $userDesc,
            "permissions": $permissions
        }'
    )

    _check "${USER}" "robots" EXISTS "id" RETURN_ID

    if [[ "${EXISTS}" == "NO" ]]; then
        local RESPONSE
        RESPONSE=$(_request "/robots" "${DATA}")

        local HTTP_STATUS
        HTTP_STATUS=$(printf "%s" "${RESPONSE}" | jq --compact-output '.status')

        local BODY
        BODY=$(printf "%s" "${RESPONSE}" | jq --compact-output '.body')

        if [[ "${HTTP_STATUS}" != "201" ]]; then
            _log "error" "${BODY}" "JSON"
            exit 1
        fi

        RETURN_ID=$(printf "%s" "${BODY}" | jq --compact-output '.id')

        _log "info" "created robot account: ${USER}"
    fi

    _refresh_robot_secret "${RETURN_ID}" "${USER_TOKEN}"
}

_delete_project() {
    local NAME="${1:?}"

    _check "${NAME}" "projects" EXISTS

    if [[ "${EXISTS}" == "YES" ]]; then
        local RESPONSE
        RESPONSE=$(_request "/projects/${NAME}" "N/A" "DELETE")

        local HTTP_STATUS
        HTTP_STATUS=$(printf "%s" "${RESPONSE}" | jq --compact-output '.status')

        local BODY
        BODY=$(printf "%s" "${RESPONSE}" | jq --compact-output '.body')

        if [[ "${HTTP_STATUS}" != "200" ]]; then
            _log "error" "${BODY}" "JSON"
            exit 1
        fi

        _log "info" "deleted project: ${NAME}"
    fi
}

_create_project() {
    local NAME="${1:?}"

    local DATA
    DATA=$(jq --compact-output --null-input \
        --arg name "${NAME}" \
        '{
            "project_name": $name,
            "public": false,
            "storage_limit": -1
        }'
    )

    _check "${NAME}" "projects" EXISTS

    if [[ "${EXISTS}" == "NO" ]]; then
        local RESPONSE
        RESPONSE=$(_request "/projects" "${DATA}")

        local HTTP_STATUS
        HTTP_STATUS=$(printf "%s" "${RESPONSE}" | jq --compact-output '.status')

        local BODY
        BODY=$(printf "%s" "${RESPONSE}" | jq --compact-output '.body')

        if [[ "${HTTP_STATUS}" != "201" ]]; then
            _log "error" "${BODY}" "JSON"
            exit 1
        fi

        _log "info" "created project: ${NAME}"
    fi
}

_main() {
    _create_robot_user "tekton" "$TEKTON_TOKEN"
    _delete_project "library"
    _create_project "demo"
}

_main "$@"
