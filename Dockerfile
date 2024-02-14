FROM scratch
FROM ubuntu:18.04
LABEL maintainer="andreas.wombacher@aureliusenterprise.com"
ARG VERSION=2.2.1

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install apt-utils \
    && apt-get -y install \
    vim \
    maven \
    wget \
    git \
    python \
    openjdk-8-jdk-headless \
    patch \
    net-tools \
    unzip \
    lsof \
    && cd /tmp \
    && wget http://mirror.linux-ia64.org/apache/atlas/${VERSION}/apache-atlas-${VERSION}-sources.tar.gz \
    && mkdir -p /tmp/atlas-src \
    && tar --strip 1 -xzvf apache-atlas-${VERSION}-sources.tar.gz -C /tmp/atlas-src \
    && rm apache-atlas-${VERSION}-sources.tar.gz \
    && cd /tmp/atlas-src \
    && export MAVEN_OPTS="-Xms2g -Xmx2g" \
    && export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64" \
    && mvn clean -Dmaven.repo.local=/tmp/.mvn-repo -Drat.skip=true -Dhttps.protocols=TLSv1.2 -DskipTests package -Pdist,embedded-hbase-solr \
    && tar -xzvf /tmp/atlas-src/distro/target/apache-atlas-${VERSION}-server.tar.gz -C /opt \
    && rm -Rf /tmp/atlas-src \
    && rm -Rf /tmp/.mvn-repo \
    && apt-get -y --purge remove \
    maven \
    git \
    && apt-get -y remove openjdk-11-jre-headless \
    && apt-get -y autoremove \
    && apt-get -y clean

VOLUME ["/opt/apache-atlas-${VERSION}/conf", "/opt/apache-atlas-${VERSION}/logs"]

COPY atlas_start.py.patch atlas_config.py.patch /opt/apache-atlas-${VERSION}/bin/

RUN cd /opt/apache-atlas-${VERSION}/bin \
    && patch -b -f < atlas_start.py.patch \
    && patch -b -f < atlas_config.py.patch

#COPY conf/hbase/hbase-site.xml.template /opt/apache-atlas-${VERSION}/conf/hbase/hbase-site.xml.template
COPY conf/atlas-env.sh /opt/apache-atlas-${VERSION}/conf/atlas-env.sh
COPY conf/atlas-application.properties /opt/apache-atlas-${VERSION}/conf/atlas-application.properties
COPY bin/startup.sh /opt/apache-atlas-${VERSION}/bin/startup.sh

RUN cd /opt/apache-atlas-${VERSION}/bin \
    && chmod u+x startup.sh

#ENTRYPOINT [/opt/apache-atlas-2.2.0/bin/startup.sh]
#RUN cd /opt/apache-atlas-${VERSION} \
#    && export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64" \
#    && ./bin/atlas_start.py -setup || true

#RUN touch /opt/apache-atlas-${VERSION}/logs/application.log 
#RUN cd /opt/apache-atlas-${VERSION} \
#    && export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64" \
#    && ./bin/atlas_start.py & \ 
#    touch /opt/apache-atlas-${VERSION}/logs/application.log \
#    && tail -f /opt/apache-atlas-${VERSION}/logs/application.log | sed '/AtlasAuthenticationFilter.init(filterConfig=null)/ q' \
#    && sleep 10 \
#    && /opt/apache-atlas-${VERSION}/bin/atlas_stop.py

#RUN cd /opt/apache-atlas-${VERSION}/bin \
#    && export VERSION=${VERSION} \
#    && nohup ./bin/atlas_start.py > /opt/apache-atlas-${VERSION}/application.log 2>&1 & 
#    touch /opt/apache-atlas-${VERSION}/logs/application.log \
