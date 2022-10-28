#!/usr/bin/env python3
import sys
import time
from enum import Enum

PROC_NET_DEV = "/proc/net/dev"
#          0         1          2    3    4    5    6     7          8         9         10         11    12    13    14    15      16
#Interface rx-bytes  rx-packets errs drop fifo frame compressed multicast tx-bytes  tx-packets errs  drop  fifo  colls carrier compressed

class NetstatsIndex(Enum):
    RX_BYTES = 0
    RX_PACKETS = 1
    RX_ERRORS = 2
    RX_DROPS = 3


def get_stats(interface: str) -> dict:
    fp = open(PROC_NET_DEV)
    contents = fp.read()
    lines = contents.split("\n")
    lines = lines[2:]
    for line in lines:
        line = line.strip()
        # Skip newlines
        if not line:
            continue
        columns = line.split(":")
        iface = columns[0]
        stats = columns[1]
        if iface == interface:
            stats_arr =  stats.split()
            return {
                "rx_bytes": int(stats_arr[NetstatsIndex.RX_BYTES.value]),
                "rx_packets": int(stats_arr[NetstatsIndex.RX_PACKETS.value]),
                "rx_errors": int(stats_arr[NetstatsIndex.RX_ERRORS.value]),
                "rx_drops": int(stats_arr[NetstatsIndex.RX_DROPS.value]),
            }
    # If interface was not found
    return None


# Sample interval in seconds
sample_interval = 5
if len(sys.argv) < 2:
    print("Expected interface")
    sys.exit()

if len(sys.argv) > 2:
    sample_interval = int(sys.argv[2])

interface = sys.argv[1]
prev_stats = get_stats(interface)
print(f"{prev_stats}")
while True:
    time.sleep(sample_interval)
    stats = get_stats(sys.argv[1])
    rx_bitrate = (stats["rx_bytes"] - prev_stats["rx_bytes"]) * 8.0 / sample_interval / 1000000
    rx_packet_rate = (stats["rx_packets"] - prev_stats["rx_packets"]) / sample_interval / 1000.0
    rx_error_rate = (stats["rx_errors"] - prev_stats["rx_errors"]) / sample_interval
    rx_drop_rate = (stats["rx_drops"] - prev_stats["rx_drops"]) / sample_interval
    print(f"{interface}: {rx_bitrate:.2f} Mbps,  {rx_packet_rate:.2f} Kpps,  errs: {rx_error_rate:} pps drops: {rx_drop_rate:} pps")
    prev_stats = stats

