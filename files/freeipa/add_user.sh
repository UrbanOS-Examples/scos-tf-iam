#!/usr/bin/env bash

username=
first_name=
last_name=
user_password=
realm_name=
admin_password=

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

if ipa group-show ipausers | grep 'Member users: ' | grep -q " ${username},"; then
    # User account only needs read access to the directory tree.
    # Remove the user from the default group to further lock down access
    ipa group-remove-member ipausers --user=${username}
fi
