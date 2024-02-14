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

# setup gremlin console 
# RUN cd /opt \
#     && wget --no-check-certificate https://dlcdn.apache.org/tinkerpop/3.5.3/apache-tinkerpop-gremlin-console-3.5.3-bin.zip \
#     && unzip apache-tinkerpop-gremlin-console-3.5.3-bin.zip \
#     && cd /opt/apache-tinkerpop-gremlin-console-3.5.3/conf \
#     && sed -i "s/localhost/ip6-localhost/g" ./remote.yaml \

# setup basis for gremlin server
RUN cd /opt \
    && wget --no-check-certificate https://dlcdn.apache.org/tinkerpop/3.5.3/apache-tinkerpop-gremlin-server-3.5.3-bin.zip \
    && unzip apache-tinkerpop-gremlin-server-3.5.3-bin.zip \
    && ln -s /opt/apache-atlas-2.2.0/server/webapp/atlas/WEB-INF/lib/*.jar /opt/apache-tinkerpop-gremlin-server-3.5.3/lib 2>/dev/null \
    && rm -f /opt/apache-tinkerpop-gremlin-server-3.5.3/lib/atlas-webapp-2.2.0.jar \
    && rm -f /opt/apache-tinkerpop-gremlin-server-3.5.3/lib/netty-3.10.5.Final.jar \
    && rm -f /opt/apache-tinkerpop-gremlin-server-3.5.3/lib/netty-all-4.0.52.Final.jar \
    && rm -f /opt/apache-tinkerpop-gremlin-server-3.5.1/lib/groovy-*.jar \
    && ln -s /opt/apache-atlas-2.2.0/server/webapp/atlas/WEB-INF/lib/groovy-*.jar /opt/apache-tinkerpop-gremlin-server-3.5.3/lib \
    && sed -i 's/assistive_technologies=org.GNOME.Accessibility.AtkWrapper/#assistive_technologies=org.GNOME.Accessibility.AtkWrapper/g' /etc/java-8-openjdk/accessibility.properties 

COPY conf/gremlin/gremlin-server-atlas.yaml /opt/apache-tinkerpop-gremlin-server-3.5.1/conf/gremlin-server-atlas.yaml
COPY conf/gremlin/janusgraph-hbase-solr.properties /opt/apache-tinkerpop-gremlin-server-3.5.1/conf/janusgraph-hbase-solr.properties
COPY bin/start-gremlin-server.sh /opt/apache-atlas-${VERSION}/bin/start-gremlin-server.sh

RUN chmod 700 /opt/apache-atlas-${VERSION}/bin/start-gremlin-server.sh
