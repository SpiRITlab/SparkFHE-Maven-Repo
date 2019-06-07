# Ubuntu 18.04 with SparkFHE distribution and HDFS
# Build image with:  docker build -t sparkfhe/sparkfhe-dist .

FROM ubuntu:18.04
MAINTAINER Spiritlab, https://github.com/SpiRITlab
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y  software-properties-common && \
    add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    apt-get install -y sudo openssh-server scala libpcre3-dev net-tools iputils-ping nmap m4 wget git vim build-essential gcc-8 g++-8 cmake gradle && \
    apt-get install -y openjdk-8-jdk python-dev libcurl4-nss-dev libsasl2-dev libsasl2-modules maven libapr1-dev libsvn-dev unzip libz-dev apt-utils && \
    apt-get clean


# download the TestDrive.bash script
RUN wget https://github.com/SpiRITlab/SparkFHE-Maven-Repo/raw/master/TestDrive.bash
RUN cd /; bash TestDrive.bash all


RUN cd /spark-3.0.0-SNAPSHOT-bin-SparkFHE/SparkFHE-Addon/scripts/setup && bash install_shared_libraries.bash && rm -rf /spark-3.0.0-SNAPSHOT-bin-SparkFHE/deps


WORKDIR spark-3.0.0-SNAPSHOT-bin-SparkFHE