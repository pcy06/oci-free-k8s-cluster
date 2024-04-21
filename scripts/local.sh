#!/bin/bash

chmod 400 $SSH_KEY_PATH

while true; do
    scp -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ubuntu@$MASTER_PUBLIC_IP:/tmp/master.env ./generated/master.env

    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "Copied Master Node Environment variables Successfully."
        break
    else
        echo "Master Node Environment copy Action failed with exit code $exit_code. Retrying..."
        sleep 3
    fi
done

source ./generated/master.env

sed -i "" "s|MASTER_HOST=.*|MASTER_HOST=\"$MASTER_HOST\"|" scripts/worker.sh
sed -i "" "s|MASTER_TOKEN=.*|MASTER_TOKEN=\"$MASTER_TOKEN\"|" scripts/worker.sh
sed -i "" "s|MASTER_CA_CERT_HASH=.*|MASTER_CA_CERT_HASH=\"$MASTER_CA_CERT_HASH\"|" scripts/worker.sh