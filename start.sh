#!/bin/sh
docker rm -f nexus > /dev/null

mkdir -p data 
echo 'setting permissions of volumes, might ask for sudo..'
sudo chown -R 200 data

echo 'starting docker container..'
docker run -d -p 8081-8091:8081-8091 -p 8443:8443 \
	--name nexus \
	-v $(pwd)/data:/nexus-data \
	-e NEXUS_SECURITY_RANDOMPASSWORD=false \
	sonatype/nexus3 
	
echo 'Waiting for nexus to start..'
timeout 60 bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost:8081)" != "200" ]]; do sleep 5; done' || false


echo 'Enabling ssl..'
docker cp nexus.properties nexus:/nexus-data/etc/nexus.properties
docker exec nexus mkdir -p /nexus-data/etc/ssl
docker exec nexus keytool -genkeypair -keystore /tmp/keystore.jks -storepass password -alias example.com \
 -keyalg RSA -keysize 2048 -validity 5000 -keypass password \
 -dname 'CN=*.example.com, OU=Sonatype, O=Sonatype, L=Unspecified, ST=Unspecified, C=US' \
 -ext 'SAN=DNS:nexus.example.com,DNS:clm.example.com,DNS:repo.example.com,DNS:www.example.com'
 docker exec nexus mv -f /tmp/keystore.jks /nexus-data/etc/ssl/keystore.jks
 
#docker cp keystore.jks nexus:/nexus-data/etc/ssl/keystore.jks

echo 'Restarting to enable ssl .. '
docker stop nexus  > /dev/null; docker start nexus  > /dev/null
timeout 60 bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost:8443)" != "200" ]]; do sleep 5; done' || false

echo "Nexus started on http://localhost:8081"
echo "Nexus started on https://localhost:8443"
echo -e "Username:\tadmin\nPassword:\tadmin123"
echo -e "Ports 8082-8091 are forwarded and can be used as connectors"
