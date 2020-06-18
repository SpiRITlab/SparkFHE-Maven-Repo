# Ubuntu 18.04 with SparkFHE distribution and HDFS
# Build image with:  docker build -t sparkfhe/sparkfhe-dist .

FROM ubuntu:18.04
MAINTAINER Spiritlab, https://github.com/SpiRITlab

# install SparkFHE distribution
RUN apt-get update; \
	apt-get install -y software-properties-common; \
 	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EA8CACC073C3DB2A; \
 	add-apt-repository ppa:linuxuprising/java; \
 	add-apt-repository ppa:jonathonf/gcc-9.0 -y; \
	apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y pkg-config wget vim openjdk-11-jdk unzip libz-dev git build-essential m4 libpcre3-dev gcc-9 g++-9 cmake python-dev python-pip maven; \
    apt-get autoremove -y; \
    apt-get clean; \
	cd /; \
	wget https://sparkfhe.s3.amazonaws.com/TestDrive.bash; \
	bash TestDrive.bash all; \
	cd /spark-3.1.0-SNAPSHOT-bin-SparkFHE/SparkFHE-Addon; \
	git pull; \
	cd /spark-3.1.0-SNAPSHOT-bin-SparkFHE/SparkFHE-Addon/scripts/setup; \
	bash install_shared_libraries.bash; \
	rm -rf /spark-3.1.0-SNAPSHOT-bin-SparkFHE/deps/src; \
	ln -s /spark-3.1.0-SNAPSHOT-bin-SparkFHE/hadoop /usr/local/hadoop; 

WORKDIR /spark-3.1.0-SNAPSHOT-bin-SparkFHE