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

RUN wget https://github.com/apache/zookeeper/archive/release-$ZOOKEEPER_VER.tar.gz
RUN tar -xvf release-$ZOOKEEPER_VER.tar.gz -C ..; \
    mv ../zookeeper-release-$ZOOKEEPER_VER $ZOOKEEPER_HOME

RUN cd $ZOOKEEPER_HOME; \
    ant
RUN rm $ZOOKEEPER_HOME/conf/*.cfg; \
    rm $ZOOKEEPER_HOME/conf/*.properties
COPY zookeeper/ $ZOOKEEPER_HOME/

EXPOSE 22
EXPOSE 2181 2888 3888

# HDFS
RUN yum install -y hadoop-hdfs-namenode hadoop-hdfs-datanode
RUN mkdir -p /var/run/hdfs-sockets; \
    chown hdfs.hadoop /var/run/hdfs-sockets
RUN mkdir -p /data/dn/
RUN chown hdfs.hadoop /data/dn

ADD hdfs/etc/hadoop/conf/core-site.xml /etc/hadoop/conf/
ADD hdfs/etc/hadoop/conf/hdfs-site.xml /etc/hadoop/conf/

EXPOSE 50010 50020 50070 50075 50090 50091 50100 50105 50475 50470 8020 8485 8480 8481
EXPOSE 50030 50060 13562 10020 19888

# PostgreSQL

RUN yum -y install postgresql-server postgresql postgresql-contrib pwgen


# Sudo requires a tty. fix that.
RUN sed -i 's/.*requiretty$/#Defaults requiretty/' /etc/sudoers

ADD ./postgresql/postgresql-setup /usr/bin/postgresql-setup

RUN chmod +x /usr/bin/postgresql-setup

RUN /usr/bin/postgresql-setup initdb

ADD ./postgresql/postgresql.conf /var/lib/pgsql/data/postgresql.conf
ADD ./postgresql/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf

ADD ./postgresql/init_postgres_user.sh /init_postgres_user.sh
RUN chmod +x /init_postgres_user.sh

RUN chown -v postgres.postgres /var/lib/pgsql/data/postgresql.conf
RUN chown -v postgres.postgres /var/lib/pgsql/data/pg_hba.conf

RUN echo "host    all             all             0.0.0.0/0               trust" >> /var/lib/pgsql/data/pg_hba.conf

VOLUME ["/var/lib/pgsql"]

EXPOSE 5432


# HIVE
ENV HIVE_VER 3.1.2

ENV HIVE_HOME /opt/hive
ENV HIVE_CONF_DIR $HIVE_HOME/conf

ENV PATH $HIVE_HOME/bin:$PATH

RUN wget https://www-us.apache.org/dist/hive/hive-${HIVE_VER}/apache-hive-${HIVE_VER}-bin.tar.gz

RUN tar -xvf apache-hive-$HIVE_VER-bin.tar.gz -C ..; \
    mv ../apache-hive-$HIVE_VER-bin $HIVE_HOME
RUN wget https://jdbc.postgresql.org/download/postgresql-42.2.5.jar -O $HIVE_HOME/lib/postgresql-42.2.5.jar

RUN useradd -p $(echo "hive" | openssl passwd -1 -stdin) hive; \
    usermod -a -G hdfs hive;

EXPOSE 9083

WORKDIR /

# Impala

RUN yum install -y impala impala-server impala-shell impala-catalog impala-state-store
RUN yum clean all

RUN groupadd supergroup; \ 
    usermod -a -G supergroup impala; \
    usermod -a -G hdfs impala; \
    usermod -a -G supergroup hive; \
    usermod -a -G hdfs hive

ADD ./impala/etc/hadoop/conf/core-site.xml /etc/impala/conf/
ADD ./impala/etc/hadoop/conf/hdfs-site.xml /etc/impala/conf/
ADD ./impala/etc/impala/conf/hive-site.xml /etc/impala/conf/

# Impala Ports
EXPOSE 21000 21050 22000 23000 24000 25000 25010 26000 28000

# Various helper scripts
ADD ./impala/bin/start-impala.sh /

ADD ./hdfs/bin/start-hdfs.sh /

ADD ./etc/supervisord.conf /etc/

ADD ./bin/supervisord-bootstrap.sh /
ADD ./bin/wait-for-it.sh /
RUN chmod +x /*.sh

# ADD ./hive/conf/hive-site.xml /opt/hive/conf
RUN rm -f $HIVE_CONF_DIR/hive-site.xml $HIVE_CONF_DIR/hive-log4j2.properties
ADD ./hive/conf/hive-site.xml $HIVE_HOME/conf/

# ADD ./hive/conf/hive-log4j2.properties $HIVE_HOME/conf/
ADD hive/psql/fix_default_location.sql /

# Impala custom UDAFs
RUN yum install -y gcc-c++ cmake boost-devel impala-udf-devel

ADD ./udafs/build_udafs.sh /
ADD ./udafs/create_udafs.sh /
ADD ./udafs/upload_udafs_to_hdfs.sh /
ADD ./udafs/udaf_create_queries /

RUN /build_udafs.sh


ENTRYPOINT ["supervisord", "-c", "/etc/supervisord.conf", "-n"]
