#!/bin/bash

cd /home/nptl/code/peripheralCode/redisReader

python populateRedis.py

sleep 1

echo "Monitoring robot arm..."
python sendSCLsimarm.py

