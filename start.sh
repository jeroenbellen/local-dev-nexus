#!/bin/sh
mkdir -p data
echo 'setting permissions of data dir, might ask for sudo..'
sudo chown -R 200 data
echo 'starting docker container..'
docker run -d -p 8081-8091:8081-8091 -v $(pwd)/data:/nexus-data -e NEXUS_SECURITY_RANDOMPASSWORD=false sonatype/nexus3
echo 'Waiting for nexus to start..'
timeout 120 bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost:8081)" != "200" ]]; do sleep 5; done' || false
echo "Nexus started on http://localhost:8081"
echo -e "Username:\tadmin\nPassword:\tadmin123"
echo -e "Ports 8082-8091 are forwarded and can be used as connectors"
