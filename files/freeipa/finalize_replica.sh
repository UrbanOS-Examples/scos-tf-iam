#!/usr/bin/env bash

admin_password=

until [ ${#} -eq 0 ]; do
    case "${1}" in
        --admin-password)
            admin_password=${2}
            shift
            ;;
    esac
    shift
done

set -e

until ipa-replica-install; do
  sleep 30
done

echo "${admin_password}" | ipa-ca-install

ipa-pkinit-manage enable
