#!/bin/bash

function docker-list-tags () {
    COMMAND_NAME="$0"

    # Make array indexing start from 0 just like in bash, even in zsh.
    if [ -n "$ZSH_VERSION" ]; then
        setopt localoptions ksharrays
    fi

    function docker-list-tags-usage () {
        echo "Usage: ${COMMAND_NAME} [-j|--json] [-n|--with-name] [<NAMESPACE>/]<IMAGE>" 1>&2
        echo ""
        echo "Argument Specifications:"
        echo '  <NAMESPACE>  : Docker Hub namespace or username (default: `library`)'
        echo '  <IMAGE>      : Docker image name (mandatory)'
        echo
        echo "Options:"
        echo '  -j, --json      : Output the result in JSON format'
        echo '  -n, --with-name : Include the image name in the output'
        echo '  -h, --help      : Show this help message and exit'
        echo
        echo "Examples:"
        echo "  ${COMMAND_NAME} ubuntu"
        echo "    List all tags for the 'library/ubuntu' image"
        echo "  ${COMMAND_NAME} mysql/mysql-server"
        echo "    List all tags for the 'mysql/mysql-server' image"
    }

    # parse arguments
    declare -a args=("$@")
    declare -a params=()

    JSON=false
    WITHNAME=false

    I=0
    while [ $I -le ${#args[@]} ]; do
        OPT="${args[$I]}"
        case $OPT in
            -h | --help )
                docker-list-tags-usage
                return 0
                ;;
            -j | --json )
                JSON=true
                ;;
            -n | --with-name )
                WITHNAME=true
                ;;
            -- | -)
                I=$(($I+1))
                while [ $I -le ${#args[@]} ]; do
                    params+=("${args[$I]}")
                    I=$(($I+1))
                done
                break
                ;;
            -*)
                echo "$0: illegal option -- '$(echo $OPT | sed 's/^-*//')'" 1>&2
                return 1
                ;;
            *)
                if [[ ! -z "$OPT" ]] && [[ ! "$OPT" =~ ^-+ ]]; then
                    params+=( "$OPT" )
                fi
                ;;
        esac
        I=$(($I+1))
    done

    # handle invalid arguments
    ARG_COUNT="${#params[@]}"
    if [ ${ARG_COUNT} -eq 0 ]; then
        echo "$0: Specify image name." 1>&2
        echo "Try '$0 --help' for more information." 1>&2
        return 1
    elif [ ${ARG_COUNT} -gt 1 ]; then
        echo "$0: Too many arguments." 1>&2
        echo "Try '$0 --help' for more information." 1>&2
        return 1
    fi

    TARGET="${params[0]}"

    if [[ "$TARGET" == */* ]]; then
        NAMESPACE="${TARGET%/*}"
        IMAGE="${TARGET#*/}"
    else
        NAMESPACE="library"
        IMAGE="$TARGET"
    fi

    PREFIX=""
    if ${WITHNAME}; then
        if [[ "${NAMESPACE}" = "library" ]]; then
            PREFIX="${IMAGE}:"
        else
            PREFIX="${NAMESPACE}/${IMAGE}:"
        fi
    fi

    if ${JSON}; then
        JQ_OPT=""
        JQ_ARG=".tags | map (\"${PREFIX}\" + .)"
    else
        JQ_OPT="-r"
        JQ_ARG=".tags | map(\"${PREFIX}\" + .) | join(\"\\n\")"
    fi

    TOKEN="$(curl -s "https://auth.docker.io/token?scope=repository%3A${NAMESPACE}%2F${IMAGE}%3Apull&service=registry.docker.io" | jq -r .token)"
    curl -s -H "Authorization: Bearer ${TOKEN}" "https://registry-1.docker.io/v2/${NAMESPACE}/${IMAGE}/tags/list" | jq ${JQ_OPT} "${JQ_ARG}"
}

function docker-inspect-architecture () {
    if [ $# -ne 1 ]; then
        echo "Usage: $0 [<NAMESPACE>/]<IMAGE>[:<TAG>]" 1>&2
        echo ""
        echo "Argument Specifications:"
        echo '  <NAMESPACE>  : Docker Hub namespace or username (default: `library`)'
        echo '  <IMAGE>      : Image name (mandatory)'
        echo '  <TAG>        : Tag name (default: `latest`)'
        echo
        echo "Examples:"
        echo "  $0 ubuntu"
        echo '    Inspect architectures of library/ubuntu:latest'
        echo "  $0 ubuntu:22.04"
        echo '    Inspect architectures of library/ubuntu:22.04'
        echo "  $0 mysql/mysql-server"
        echo '    Inspect architectures of mysql/mysql-server:latest'
        echo "  $0 mysql/mysql-server:8.0"
        echo '    Inspect architectures of mysql/mysql-server:8.0'
        return 1
    fi

    if [[ "$1" == */* ]]; then
        NAMESPACE="${1%/*}"
        IMAGE="${1#*/}"
    else
        NAMESPACE="library"
        IMAGE="$1"
    fi

    if [[ "${IMAGE}" == *:* ]]; then
        TAG="${IMAGE#*:}"
        IMAGE="${IMAGE%:*}"
    else
        TAG="latest"
    fi

    echo -n "Inspecting "
    if [ ${NAMESPACE} != "library" ]; then
        echo -n "${NAMESPACE}/"
    fi
    echo "${IMAGE}:${TAG}"

    TOKEN="$(curl -s "https://auth.docker.io/token?scope=repository%3A${NAMESPACE}%2F${IMAGE}%3Apull&service=registry.docker.io" | jq -r '.token')"
    curl -s -H "Authorization: Bearer ${TOKEN}" "https://registry-1.docker.io/v2/${NAMESPACE}/${IMAGE}/manifests/${TAG}" | jq -r '.architecture // .manifests[].platform.architecture'
}
