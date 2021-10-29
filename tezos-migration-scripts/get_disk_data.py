#!/usr/bin/env python3

import subprocess
import sys
import re

# We're going to use `ftrace` to get the read and write events corresponding to
# the files in the migration context. For this we'll need to parse each line &
# filter out the events not relevant to the migration.
process = subprocess.Popen([ '/usr/bin/sudo', 'fatrace', '--timestamp' ], stdout=subprocess.PIPE)
pattern = re.compile(r"(?P<time_sec>.*)\.[0-9]*\ main\.exe(.*):\ (?P<type>.)\ /bench/craig/data/.tezos-node/context/(?P<file>.*)", re.VERBOSE)

latest_time = ""
reads = {}
writes = {}

def increment (data, key): data[key] = data.get(key,0) + 1

# CSV header:
print ('time,type,file,count')

for c in iter(process.stdout.readline, ''):
    line = c.decode('ascii')
    pieces = pattern.match(line)

    if pieces is not None:
        time_sec = pieces.group("time_sec")
        type_    = pieces.group("type")
        file_    = pieces.group("file")

        if time_sec != latest_time:
            for file_, count in reads.items(): print (f'{latest_time},R,{file_},{count}')
            for file_, count in writes.items(): print (f'{latest_time},W,{file_},{count}')
            latest_time = time_sec

        if type_ == 'R': increment(reads,file_)
        elif type_ == 'W': increment(writes,file_)
        else: print (f'Ignored event of type: {type_}')
