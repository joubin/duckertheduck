# General

1. Sensor Data Collection Node
2. Sensor Data Collection Server
3. Networking

## Data Collection Design

![Design](./design.svg)

I had a few requirements for this design.

1. I wanted the design to heal itself. These sensor devices would live on other peoples networks that I couldn't and didn't want to control
2. I didn't want to complicated my networking setup or open ports to the internet
3. These devices were going to live outside of homes and could be stolen, I didn't want any secrets on the device (including my own home wifi)

Here is a general summary on how everything works

### Configuring the device with Tailscale

1. Create a tailscale auth key
   1. I associated mine with a tag `sound-sensor` to apply ACLs
2. Each device uses the `first_boot.service` to execute `first_boot.sh` to init Tailscale properly

### Configure Tailscale

![alt text](tailscale-machine-list.png)

I've been using tailscale for a while now and can't live without it. Since my network was just for me, it was very flat which allowed all of my devices to talk to eachother. The boundary called `Docker Host` in the above diagram is a tailscale network that is isolated from the rest of the network. This network is used to connect to the internet and to the sensor data collection server. I run many services on that docker host which I've never segmented before, but I did want these sensors to be fully isolated.

Tailscale Access Control Policies are very well done.

For example, you can define your tags like this

```json
tagOwners": {
  "tag:sound-sensor": ["autogroup:admin"],
  "tag:home":         ["autogroup:admin"],
  "tag:services":     ["autogroup:admin"],
 },
```

and then isolate your devices with a simple rule like this

```json

  {
   "action": "accept",
   "src":    ["tag:sound-sensor"],
   "dst":    ["tag:services:65535"],
  },
```

Note that I only run `Influxdb` on port `65535`. This effectively isolates all devices tagged as `sound-sensor` to only be able to send traffic devices tagged `services` on port `65535`

Out of convenience, I did allow my internal networks (e.g. home) to be able to talk to anything at any time. This also includes my `home` tagged devices being able to `ssh` into `sound-sensor` tagged devices. 

```json
  {
   "action": "accept",
   "src":    ["tag:home"],
   "dst":    ["*:*"],
  },
```

#### Equipment

[WS1361 Digital Sound Level Meter](https://a.co/d/eEE0PVq)

This is a simple sensor with a USB data port that exports its readings over a serial port. It is more cost effective than some other options, but I did purchase [another sensor](https://a.co/d/aOY8Xfe) with NIST traceable certification in the event I want to use this data in court proceedings.
