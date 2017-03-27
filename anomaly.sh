#!/bin/bash

code=$(curl -L --max-time 10 --connect-timeout 5 --silent --head -o /dev/null -w "%{http_code}" https://www.hardwareluxx.de/index.php/news/hardware/grafikkarten/39688-sneak-peek-gigabyte-geforce-gtx-1070-g1-gaming.html)
echo $code
if [ $code -gt 299 ]; then
    echo anomaly
fi
