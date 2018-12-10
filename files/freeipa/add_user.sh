#!/usr/bin/env bash

username=
first_name=
last_name=
user_password=
realm_name=
admin_password=
groups=

until [ ${#} -eq 0 ]; do
    case "${1}" in
        --username)
            username=${2}
            shift
            ;;
        --first-name)
            first_name=${2}
            shift
            ;;
        --last-name)
            last_name=${2}
            shift
            ;;
        --password)
            password=${2}
            shift
            ;;
        --groups)
            groups=$(echo ${2} | sed -e 's/,/\n/')
            shift
            ;;
        --realm-name)
            realm_name=${2}
            shift
            ;;
        --admin-password)
            admin_password=${2}
            shift
            ;;
    esac
    shift
done

set -e

echo "${admin_password}" | kinit "admin@${realm_name^^}"

if ! ipa user-find ${username} >/dev/null; then
    # Add the user service account
    ipa user-add ${username} --first=${first_name} --last=${last_name}
fi

# Set the user password based on the determined password
ipa passwd ${username} "${password}"

current_groups=$(ipa user-show --all ${username} | grep -oP '^  Member of groups: \K.*$' | sed -e 's/, /\n/')

for group in ${current_groups[@]}; do
    if echo ${groups} | grep -vq "${group}"; then
        ipa group-remove-member ${group} --users=${username} > /dev/null
    fi
done

for group in ${groups[@]}; do
    if echo ${current_groups} | grep -vq "${group}"; then
        ipa group-add-member ${group} --users=${username} > /dev/null
    fi
done