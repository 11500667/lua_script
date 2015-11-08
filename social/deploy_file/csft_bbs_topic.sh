#!/bin/bash
step=2 #间隔的秒数，不能大于60
for (( i = 0; i < 60; i=(i+step) )); do
/usr/local/sphinx/bin/indexer index_incr_bbs_topic -c /usr/local/sphinx/etc/csft_bbs_topic.conf --rotate
sleep $step
done
exit 0
