#!/bin/bash
curl -O http://download.redis.io/redis-stable.tar.gz >/dev/null
tar xvzf redis-stable.tar.gz >/dev/null
cd redis-stable
make
