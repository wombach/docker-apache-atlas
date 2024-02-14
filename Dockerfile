FROM scratch
FROM ubuntu:20.04
LABEL maintainer="andreas.wombacher@aureliusenterprise.com"
ARG VERSION=2.2.0
ARG DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt -y upgrade
RUN TZ=Etc apt -y install \
    vim \
    maven \
    wget \
    git \
    python \
    openjdk-8-jdk-headless \
    patch \
    net-tools \
    unzip \
    lsof

ENV JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64" 
# https://stackoverflow.com/questions/68199459/maven-build-failed-pkix-path-validation-failed-java-security-cert-certpathval/68201055#68201055
ENV MAVEN_OPTS="-Xms2g -Xmx2g -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true -Dmaven.wagon.http.ssl.ignore.validity.dates=true" 

RUN cd /tmp \
    && wget http://mirror.linux-ia64.org/apache/atlas/${VERSION}/apache-atlas-${VERSION}-sources.tar.gz \
    && mkdir -p /tmp/atlas-src \
    && tar --strip 1 -xzvf apache-atlas-${VERSION}-sources.tar.gz -C /tmp/atlas-src \
    && rm apache-atlas-${VERSION}-sources.tar.gz

RUN cd /tmp/atlas-src \
    && mvn clean -Dmaven.repo.local=/tmp/.mvn-repo -Drat.skip=true -Dhttps.protocols=TLSv1.2 -DskipTests package -Pdist,embedded-hbase-solr 

RUN tar -xzvf /tmp/atlas-src/distro/target/apache-atlas-${VERSION}-server.tar.gz -C /opt \
    && rm -Rf /tmp/atlas-src \
    && rm -Rf /tmp/.mvn-repo

RUN apt -y --purge remove \
    maven \
    git \
    && apt -y remove openjdk-11-jre-headless \
    && apt -y autoremove \
    && apt -y clean

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
