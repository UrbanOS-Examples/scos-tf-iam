#!/usr/bin/env bash

hostname=
hosted_zone=
admin_password=
realm_name=
hostname_prefix=
freeipa_version=

until [ ${#} -eq 0 ]; do
    case "${1}" in
        --hostname)
            hostname=${2}
            shift
            ;;
        --hosted-zone)
            hosted_zone=${2}
            shift
            ;;
        --admin-password)
            admin_password=${2}
            shift
            ;;
        --realm-name)
            realm_name=${2}
            shift
            ;;
        --hostname-prefix)
            hostname_prefix=${2}
            shift
            ;;
        --freeipa-version)
            freeipa_version=${2}
            shift
            ;;
    esac
    shift
done

set -e

IP=$(hostname -I | xargs)

cat << EOF > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
${IP} ${hostname}.${hosted_zone} ${hostname}
EOF

hostnamectl set-hostname "${hostname}.${hosted_zone}"

dnf -y install freeipa-server-${freeipa_version}

ipa-client-install \
  --domain="${hosted_zone}" \
  --realm="${realm_name^^}" \
  --server="${hostname_prefix}-master.${hosted_zone}" \
  --hostname="${hostname}.${hosted_zone}" \
  --principal="admin@${realm_name^^}" \
  --password="${admin_password}" \
  --ntp-server=us.pool.ntp.org \
  --unattended
