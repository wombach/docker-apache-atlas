#!/bin/bash

export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
touch /opt/apache-atlas-2.3.0/logs/application.log
cd /opt/apache-atlas-2.3.0/
./bin/atlas_start.py
tail -f /dev/null 
