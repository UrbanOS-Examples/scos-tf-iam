#!/usr/bin/env bash

user_password=
realm_name=
admin_password=

until [ ${#} -eq 0 ]; do
    case "${1}" in
        --user-password)
            user_password=${2}
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

# Add the bind user service account
ipa useradd binduser --first=bind --last=user

# Set the user password based on the determined password
ipa passwd binduser "${user_password}"

# Remove the user from the default group to further lock down access;
# User account only needs read access to the directory tree.
ipa group-remove-member ipausers --user=binduser