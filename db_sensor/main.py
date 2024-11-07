from wensn import connect
from wensn import setMode
from wensn import readSPL

import time
import os
import socket
import influxdb_client, os, time
from influxdb_client import InfluxDBClient, Point, WritePrecision, WriteOptions

if __name__ == "__main__":
    # Setup Influxdb connection
    tailnet = os.environ.get("TAILNET")
    token = os.environ.get("INFLUXDB_TOKEN")
    org = "jabbari.io"
    url = f"http://mini-fedora.{tailnet}:65535"
    client = influxdb_client.InfluxDBClient(url=url, token=token, org=org)
    bucket="95762_sound_data"
    write_api = client.write_api(write_options=WriteOptions(max_retries=20, jitter_interval=10,  retry_interval=5000))

    # Setup Sound Sensor
    dev = connect()
    sensor_id = socket.gethostname()

    setMode(dev)
    while True:
        dB, range, weight, speed = readSPL(dev)
        write_api.write(bucket=bucket, org=org, record={
            "measurement": "sound_sensor",
            "tags": {
                "sensor_id": sensor_id,
                "range": range,
                "weight": weight,
                "speed": speed,
            },
            "fields": {
                "dB": dB
            }
        })
        time.sleep(1)