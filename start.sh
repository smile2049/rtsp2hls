#!/bin/bash

set -m

nginx -g "daemon off;" &

node ./build/app.js

fg %1
