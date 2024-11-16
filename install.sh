#!/bin/bash
DDD_HOME="/root/duckertheduck"
set -e 
apt install -y python3-pip python3 git
cd /root
git clone https://github.com/joubin/duckertheduck.git
sleep 1
install -m 644 ${DDD_HOME}/sound_sensor.service /etc/systemd/system/sound_sensor.service
cd ${DDD_HOME}/db_sensor/
pip3 install --break-system-packages -r requirements.txt
install -m 644 ${DDD_HOME}/linux/first_boot.service /etc/systemd/system/first_boot.service
install -m 755 ${DDD_HOME}/linux/first_boot.sh /first_boot.sh