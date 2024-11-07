#!/bin/bash

set -e 
apt install -y python3-pip python3 git
cd /root
git clone https://github.com/joubin/duckertheduck.git
cp /root/ducktheduck/sound_sensor.service /etc/systemd/system/sound_sensor.service
cd /root/duckertheduck/db_sensor/
python3 -m venv venv 

source venv/bin/activate
pip3 install -r requirements.txt
python3 main.py
