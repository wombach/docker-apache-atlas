#!/bin/bash

cd /opt/apache-tinkerpop-gremlin-server-3.5.3
export GREMLIN_YAML=conf/gremlin-server-atlas.yaml
./bin/gremlin-server.sh start