import usb.core

import time
import os
import socket
import influxdb_client, os, time
from influxdb_client import InfluxDBClient, Point, WritePrecision, WriteOptions

def connect():
    dev = usb.core.find(idVendor=0x16c0, idProduct=0x5dc)
    assert dev is not None, "Is your sound meter plugged in to USB?"
    print(dev)
    return dev


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

    while True:
        ret = dev.ctrl_transfer(0xC0, 4, 0, 0, 200)
        dB = (ret[0] + ((ret[1] & 3) * 256)) * 0.1 + 30
        dB = round(dB, 1)  # Round to one decimal place
        write_api.write(bucket=bucket, org=org, record={
            "measurement": "sound_sensor",
            "tags": {
                "sensor_id": sensor_id,
                "range": range,
            },
            "fields": {
                "dB": dB
            }
        })
        time.sleep(1)