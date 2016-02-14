#!/bin/bash
curl -O http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make
export PATH="$PWD/redis-stable/src/:$PATH"
