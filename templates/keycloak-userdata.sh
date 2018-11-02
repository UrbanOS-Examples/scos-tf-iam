#!/usr/bin/env bash

set -e

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

IP=$(hostname -I | xargs)

cat << EOF > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
$${IP} ${hostname}.${hosted_zone} ${hostname}
EOF

hostnamectl set-hostname "${hostname}.${hosted_zone}"

until dnf -y install freeipa-client freeipa-admintools java-1.8.0-openjdk wget; do
  sleep 10
done

sleep 360 

until curl -I --insecure "https://${hostname_prefix}-master.${hosted_zone}/ipa/ui/"; do
  sleep 30
done

until \
ipa-client-install \
--domain="${hosted_zone}" \
--realm="${upper("${hosted_zone}")}" \
--server="${hostname_prefix}-master.${hosted_zone}" \
--hostname="${hostname}.${hosted_zone}" \
--principal="admin@${upper("${hosted_zone}")}" \
--password="${admin_password}" \
--ntp-server=us.pool.ntp.org \
--unattended;
do
  sleep 60
done

export KEYCLOAK_HOME=/usr/local/keycloak/keycloak-${keycloak_version}.Final
mkdir -p $$KEYCLOAK_HOME
wget -qO- --no-check-certificate https://downloads.jboss.org/keycloak/${keycloak_version}.Final/keycloak-${keycloak_version}.Final.tar.gz \
  | tar xvz -C /usr/local/keycloak

mkdir /etc/keycloak /var/run/keycloak

cd $$KEYCLOAK_HOME/docs/contrib/scripts/systemd/
sed -e 's/wildfly/keycloak/g' \
  -e 's/WILDFLY/KEYCLOAK/g' \
  -e "s/KEYCLOAK_BIND=0.0.0.0/KEYCLOAK_BIND=$$(hostname -i)/g" wildfly.conf \
  > /etc/keycloak/keycloak.conf

sed -e 's/wildfly/keycloak/g' \
  -e 's/WILDFLY/KEYCLOAK/g' \
  -e "s%KEYCLOAK_HOME=.*%KEYCLOAK_HOME=$$KEYCLOAK_HOME%" launch.sh \
  > $$KEYCLOAK_HOME/bin/launch.sh

chmod 755 $$KEYCLOAK_HOME/bin/launch.sh

sed -e 's/User=.*/User=root/g' \
  -e 's/wildfly/keycloak/g' -e 's/WILDFLY/KEYCLOAK/g' \
  -e 's/Description=.*/Description=Keycloak Identity Provider/g' \
  -e "s%/opt/keycloak/bin%$$KEYCLOAK_HOME/bin%" wildfly.service \
  > /etc/systemd/system/keycloak.service

$$KEYCLOAK_HOME/bin/add-user-keycloak.sh -r master -u admin -p ${admin_password}

systemctl enable keycloak
systemctl start keycloak

echo "${admin_password}" | kinit "admin@${upper("${hosted_zone}")}"
ipa service-add "HTTP/${hostname}.${hosted_zone}@${upper("${hosted_zone}")}"

ipa-getkeytab -s "${hostname_prefix}-master.${hosted_zone}" \
  -p "HTTP/${hostname}.${hosted_zone}@${upper("${hosted_zone}")}" \
  -k /etc/ipa.keytab

cd $$KEYCLOAK_HOME/standalone/configuration
keytool -genkey \
  -storepass ${admin_password} \
  -keypass ${admin_password} \
  -alias ${hosted_zone} \
  -dname "CN=${hostname}.${hosted_zone},OU=scos,O=smartcolumbus,L=Columbus,S=Ohio,C=US" \
  -keyalg RSA \
  -keystore keycloak.jks \
  -validity 10950

keytool -certreq \
  -alias ${hosted_zone} \
  -keystore keycloak.jks \
  -storepass ${admin_password} \
  > keycloak.careq

ipa cert-request --principal \
  "HTTP/${hostname}.${hosted_zone}@${upper("${hosted_zone}")}" \
  keycloak.careq

ipa service-show "HTTP/${hostname}.${hosted_zone}" \
  --out keycloak.cert

keytool -import \
  -keystore keycloak.jks \
  -file /etc/ipa/ca.crt \
  -alias root \
  -storepass ${admin_password} \
  -noprompt

keytool -import \
  -keystore keycloak.jks \
  -file keycloak.cert \
  -alias ${hosted_zone} \
  -storepass ${admin_password}

cat > cfgpatch1 <<EOF
            <security-realm name="UndertowRealm">
                <server-identities>
                    <ssl>
                        <keystore path="keycloak.jks" relative-to="jboss.server.config.dir" keystore-password="${admin_password}" />
                    </ssl>
                </server-identities>
            </security-realm>
EOF
awk '//; /<security-realms>/{while(getline<"cfgpatch1"){print}}' standalone.xml >tempconfig
mv tempconfig standalone.xml

sed -i '/https-listener/d' standalone.xml
cat > cfgpatch2 <<EOF
                <https-listener name="https" socket-binding="https" security-realm="UndertowRealm"/>
EOF
awk '//; /<server name="default-server">/{while(getline<"cfgpatch2"){print}}' standalone.xml >tempconfig
mv tempconfig standalone.xml

systemctl restart keycloak