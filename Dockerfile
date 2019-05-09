FROM parrotstream/centos-openjdk:8

USER root

ENV CDH_VERSION 6.2.0

ADD cloudera-cdh62.repo /etc/yum.repos.d/
RUN rpm --import https://archive.cloudera.com/cdh6/$CDH_VERSION/redhat7/yum/RPM-GPG-KEY-cloudera

# ZOOKEEPER
ENV ZOOKEEPER_VER 3.5.4
ENV ZOOKEEPER_HOME /opt/zookeeper
ENV PATH $ZOOKEEPER_HOME/bin:$ZOOKEEPER_HOME/sbin:$PATH

RUN yum clean all; yum update -y
RUN yum install -y ant which openssh-clients openssh-server python-setuptools git
RUN easy_install supervisor
RUN yum clean all

RUN wget https://github.com/apache/zookeeper/archive/release-$ZOOKEEPER_VER.tar.gz
RUN tar -xvf release-$ZOOKEEPER_VER.tar.gz -C ..; \
    mv ../zookeeper-release-$ZOOKEEPER_VER $ZOOKEEPER_HOME

RUN cd $ZOOKEEPER_HOME; \
    ant
RUN rm $ZOOKEEPER_HOME/conf/*.cfg; \
    rm $ZOOKEEPER_HOME/conf/*.properties
COPY zookeeper/ $ZOOKEEPER_HOME/


# HDFS
RUN yum install -y hadoop-hdfs-namenode hadoop-hdfs-datanode
RUN yum clean all

RUN mkdir -p /var/run/hdfs-sockets; \
    chown hdfs.hadoop /var/run/hdfs-sockets
RUN mkdir -p /data/dn/
RUN chown hdfs.hadoop /data/dn

ADD hdfs/etc/hadoop/conf/core-site.xml /etc/hadoop/conf/
ADD hdfs/etc/hadoop/conf/hdfs-site.xml /etc/hadoop/conf/

WORKDIR /

RUN yum install -y sudo

# Various helper scripts
ADD hdfs/bin/start-hdfs.sh ./

ADD etc/supervisord.conf /etc/

ADD bin/supervisord-bootstrap.sh ./
ADD bin/wait-for-it.sh ./
RUN chmod +x ./*.sh

EXPOSE 22
EXPOSE 2181 2888 3888

EXPOSE 50010 50020 50070 50075 50090 50091 50100 50105 50475 50470 8020 8485 8480 8481
EXPOSE 50030 50060 13562 10020 19888

ENTRYPOINT ["supervisord", "-c", "/etc/supervisord.conf", "-n"]
