#!/bin/bash

# rsync -a user@remote_host:/home/username/dir1 place_to_sync_on_local_machine
# rsync -anzP c_bjayan@c-cvenum-linux:/local/mnt/workspace/c_cvenum/tip tip


rsync -anzP c_bjayan@c-cvenum-linux:/local/mnt/workspace/c_cvenum/tip /local/mnt/workspace/src/quic/M/tip
