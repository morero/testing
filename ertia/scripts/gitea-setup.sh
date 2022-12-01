#!/bin/bash

set -euo pipefail

NAMESPACE="${1:?}"

GITEA_USERNAME="gitea"
GITEA_PASSWORD="${2:?}"

TEKTON_USERNAME="tekton"
TEKTON_PASSWORD="${3:?}"

GITEA_API="http://git-gitea-http.git:3000/api/v1"

K8S_AUTH=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
K8S_API="https://kubernetes.default/api/v1"
K8S_HEADER_AUTH_BEARER="Authorization: Bearer ${K8S_AUTH}"

GITEA_BASIC_AUTH=$(printf "%s:%s" "${GITEA_USERNAME}" "${GITEA_PASSWORD}" | base64)
GITEA_HEADER_BASIC_AUTH="Authorization: Basic ${GITEA_BASIC_AUTH}"

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
    local HEADER_BASIC_AUTH="${4:-${GITEA_HEADER_BASIC_AUTH}}"

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

    RESULT=$(curl -s "${GITEA_API}${API_PATH}" \
        "${HTTP_VERB[@]}" \
        -w '%{http_code}' \
        -H "${HEADER_ACCEPT}" \
        -H "${HEADER_CONTENT_TYPE}" \
        -H "${HEADER_BASIC_AUTH}" \
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
    local HEADER_BASIC_AUTH="${6:-${GITEA_HEADER_BASIC_AUTH}}"

    local RESPONSE
    RESPONSE=$(_request "${END_POINT}" "N/A" "N/A" "${HEADER_BASIC_AUTH}" )

    local HTTP_STATUS
    HTTP_STATUS=$(printf "%s" "${RESPONSE}" | jq --compact-output '.status')

    local BODY
    BODY=$(printf "%s" "${RESPONSE}" | jq --compact-output '.body')

    local FOUND
    if [[ "${HTTP_STATUS}" == "200" ]]; then
        FOUND=$(printf "%s" "${BODY}" | jq --raw-output --compact-output ".${ID_NAME}")
        if [[ "${FOUND}" != "" ]]; then
            _log "info" "${END_POINT}: ${NAME}, already exits"
            eval "${__RETURN}"="YES"
            eval "${__RETURN_ID}"="${FOUND}"
        else
            _log "info" "${END_POINT}: ${NAME}, not found"
            eval "${__RETURN}"="NO"
            eval "${__RETURN_ID}"="0"
        fi
    elif [[ "${HTTP_STATUS}" == "404" ]]; then
        _log "info" "${END_POINT}: ${NAME}, not found"
        eval "${__RETURN}"="NO"
        eval "${__RETURN_ID}"="0"
    else
        _log "error" "${BODY}" "JSON"
        exit 1
    fi
}

_create_robot_user() {
    local USER="${1:?}"
    local USER_PASSWORD="${2:-$(_generate_random_password 48)}"

    local DATA
    DATA=$(jq --compact-output --null-input \
        --arg user "${USER}" \
        --arg name "${USER} robot account" \
        --arg password "${USER_PASSWORD}" \
        --arg mail "${USER}@ertia.io" \
        '{
            "email": $mail,
            "full_name": $name,
            "login_name": $user,
            "must_change_password": false,
            "password": $password,
            "send_notify": false,
            "username": $user,
            "visibility": "limited"
        }'
    )

    _check "${USER}" "/users/${USER}" EXISTS "id" RETURN_ID

    if [[ "${EXISTS}" == "NO" ]]; then
        local RESPONSE
        RESPONSE=$(_request "/admin/users" "${DATA}")

        local HTTP_STATUS
        HTTP_STATUS=$(printf "%s" "${RESPONSE}" | jq --compact-output '.status')

        local BODY
        BODY=$(printf "%s" "${RESPONSE}" | jq --compact-output '.body')

        if [[ "${HTTP_STATUS}" != "201" ]]; then
            _log "error" "${BODY}" "JSON"
            exit 1
        fi

        _log "info" "created robot account: ${USER}"
    fi

    _create_robot_user_token "${USER}" "${USER_PASSWORD}"
}

_create_robot_user_token() {
    local USER="${1:?}"
    local USER_PASSWORD="${2:?}"

    local BASIC_AUTH
    BASIC_AUTH=$(printf "%s:%s" "${USER}" "${USER_PASSWORD}" | base64)
    local HEADER_BASIC_AUTH="Authorization: Basic ${BASIC_AUTH}"

    local DATA
    DATA=$(jq --compact-output --null-input \
        --arg name "${USER}-token" \
        '{
            "name": $name
        }'
    )

    local TOKEN

    _check "${USER}-token" "/users/${USER}/tokens" EXISTS \
        "[] | select(.name == \"${USER}-token\") | .name" \
        RETURN_NAME "${HEADER_BASIC_AUTH}"

    if [[ "${EXISTS}" == "NO" ]]; then
        local RESPONSE
        RESPONSE=$(_request "/users/${USER}/tokens" "${DATA}" "N/A" "${HEADER_BASIC_AUTH}")

        local HTTP_STATUS
        HTTP_STATUS=$(printf "%s" "${RESPONSE}" | jq --compact-output '.status')

        local BODY
        BODY=$(printf "%s" "${RESPONSE}" | jq --compact-output '.body')

        if [[ "${HTTP_STATUS}" != "201" ]]; then
            _log "error" "${BODY}" "JSON"
            exit 1
        fi

        _log "info" "created token for user: ${USER}"

        TOKEN=$(printf "%s" "${BODY}" | jq --raw-output --compact-output '.sha1')
        _create_secret "${NAMESPACE}" "${USER}" "${TOKEN}"
    fi
}

_create_secret() {
    local NAMESPACE="${1:?}"

    local USERNAME="${2:?}"

    local USERNAME_B64
    USERNAME_B64=$(printf "%s" "${2:?}" | base64)

    local TOKEN
    TOKEN=$(printf "%s" "${3:?}" | base64)

    local NAME
    NAME="${USERNAME}-gitea-token"

    local DATA
    DATA=$(jq --compact-output --null-input \
        --arg namespace "${NAMESPACE}" \
        --arg name "${NAME}" \
        --arg username "${USERNAME_B64}" \
        --arg token "${TOKEN}" \
        '{
            "apiVersion": "v1",
            "data": {
                "username": $username,
                "token": $token
            },
            "kind": "Secret",
            "metadata": {
                "name": $name,
                "namespace": $namespace
            },
            "type": "Opaque"
        }'
    )

    local RESPONSE

    RESPONSE=$(curl -sk "${K8S_API}/namespaces/${NAMESPACE}/secrets/${NAME}?gracePeriodSeconds=0" \
        -X DELETE \
        -w '%{http_code}' \
        -H "${HEADER_CONTENT_TYPE}" \
        -H "${K8S_HEADER_AUTH_BEARER}"
    )

    BODY=${RESPONSE::-3}

    if [[ "${BODY}" == "" ]]; then
        BODY="{}"
    fi

    _log "info" "${BODY}" "JSON"

    RESPONSE=$(curl -sk "${K8S_API}/namespaces/${NAMESPACE}/secrets" \
        -w '%{http_code}' \
        -H "${HEADER_CONTENT_TYPE}" \
        -H "${K8S_HEADER_AUTH_BEARER}" \
        -d "${DATA}"
    )

    local HTTP_STATUS
    HTTP_STATUS=$(printf "%s" "${RESPONSE}" | tail -c 3)

    local BODY
    BODY=${RESPONSE::-3}

    if [[ "${BODY}" == "" ]]; then
        BODY="{}"
    fi

    OK=$(printf "%s" "${HTTP_STATUS}" | cut -c1-1)
    if [[ "${OK}" = "2" ]]; then
        _log "info" "created k8s secret: ${NAME}, in namespace: ${NAMESPACE}"
    else
        _log "error" "${BODY}" "JSON"
        exit 1
    fi
}

_create_org() {
    local ORG_NAME=${1:?}
    local ORG_FULLNAME="${2:?}"
    local ORG_DESC="${3:?}"

    local DATA
    DATA=$(jq --compact-output --null-input \
        --arg name "${ORG_NAME}" \
        --arg fullname "${ORG_FULLNAME}" \
        --arg orgdesc "${ORG_DESC}" \
        '{
            "description": $orgdesc,
            "full_name": $fullname,
            "location": "",
            "repo_admin_change_team_access": true,
            "username": $name,
            "visibility": "limited",
            "website": ""
        }'
    )

    _check "${ORG_NAME}" "/orgs/${ORG_NAME}" EXISTS "id" RETURN_NAME

    if [[ "${EXISTS}" == "NO" ]]; then
        local RESPONSE
        RESPONSE=$(_request "/orgs" "${DATA}")

        local HTTP_STATUS
        HTTP_STATUS=$(printf "%s" "${RESPONSE}" | jq --compact-output '.status')

        local BODY
        BODY=$(printf "%s" "${RESPONSE}" | jq --compact-output '.body')

        if [[ "${HTTP_STATUS}" != "201" ]]; then
            _log "error" "${BODY}" "JSON"
            exit 1
        fi

        _log "info" "created organisation: ${ORG_NAME}"
    fi

    _create_org_team "${ORG_NAME}" "${TEKTON_USERNAME}" "${TEKTON_USERNAME} - team"
}

_create_org_team() {
    local ORG_NAME=${1:?}
    local TEAM_NAME=${2:?}
    local TEAM_DESC=${3:?}

    local PERMISSIONS
    PERMISSIONS='{
        "repo.code":"read",
        "repo.issues":"write",
        "repo.ext_issues":"none",
        "repo.wiki":"admin",
        "repo.pulls":"owner",
        "repo.releases":"none",
        "repo.projects":"none",
        "repo.ext_wiki":"none"
    }'

    _log "info" "creating org team"
    local DATA
    DATA=$(jq --compact-output --null-input \
        --arg name "${TEAM_NAME}" \
        --arg desc "${TEAM_DESC}" \
        --argjson permissions "${PERMISSIONS}" \
        '{
            "can_create_org_repo": false,
            "description": $desc,
            "includes_all_repositories": true,
            "name": $name,
            "permission": "read",
            "units": [
                "repo.code",
                "repo.issues",
                "repo.ext_issues",
                "repo.wiki",
                "repo.pulls",
                "repo.releases",
                "repo.projects",
                "repo.ext_wiki"
            ],
            "units_map": $permissions
        }'
    )
    _log "info" "creating org team 2"

    _check "${TEAM_NAME}" "/orgs/${ORG_NAME}/teams/search?q=${TEAM_NAME}" EXISTS \
        "try data[] | select(.name == \"${TEAM_NAME}\") | .id" RETURN_ID

    if [[ "${EXISTS}" == "NO" ]]; then
        local RESPONSE
        RESPONSE=$(_request "/orgs/${ORG_NAME}/teams" "${DATA}")

        local HTTP_STATUS
        HTTP_STATUS=$(printf "%s" "${RESPONSE}" | jq --compact-output '.status')

        local BODY
        BODY=$(printf "%s" "${RESPONSE}" | jq --compact-output '.body')

        if [[ "${HTTP_STATUS}" != "201" ]]; then
            _log "error" "${BODY}" "JSON"
            exit 1
        fi

        RETURN_ID=$(printf "%s" "${BODY}" | jq --compact-output '.id')
        _log "info" "created team: ${TEAM_NAME}, in organisation: ${ORG_NAME}"
    fi

    _add_team_member "${RETURN_ID}" "${TEKTON_USERNAME}"
}

_add_team_member() {
    local TEAM_ID=${1:?}
    local USER=${2:?}

    _check "${USER}" "/teams/${TEAM_ID}/members/${USER}" EXISTS "login" RETURN_NAME

    if [[ "${EXISTS}" == "NO" ]]; then
        local RESPONSE
        RESPONSE=$(_request "/teams/${TEAM_ID}/members/${USER}" "${DATA}" "PUT")

        local HTTP_STATUS
        HTTP_STATUS=$(printf "%s" "${RESPONSE}" | jq --compact-output '.status')

        local BODY
        BODY=$(printf "%s" "${RESPONSE}" | jq --compact-output '.body')

        if [[ "${HTTP_STATUS}" != "204" ]]; then
            _log "error" "${BODY}" "JSON"
            exit 1
        fi

        _log "info" "user: ${USER}, added to team whith id: ${TEAM_ID}"
    fi
}

_main () {
    _create_robot_user "${TEKTON_USERNAME}" "${TEKTON_PASSWORD}"
    _create_org "ertia" "Ertia" "Ertia organisation - NOT FOR USE"
    _create_org "demo" "Demo" "Demo organisation - NOT FOR USE"
}

_main "$@"
