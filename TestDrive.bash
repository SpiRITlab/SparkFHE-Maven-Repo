#!/bin/bash

# This script will automatically fetch all dependencies and setup a spark environment for testing the SparkFHE project code.
# NOTE, it is still a research project. 

SparkFHE_Maven_Repo_Base_URL=https://github.com/SpiRITlab/SparkFHE-Maven-Repo/raw/master
SparkFHE_AWS_S3_Base_URL=https://sparkfhe.s3.amazonaws.com


Hadoop_Distribution_Name=hadoop-3.3.0-SNAPSHOT
HadoopConfigFiles=hadoop.zip
Spark_Distribution_Name=spark-3.0.0-SNAPSHOT-bin-SparkFHE
Spark_Distribution_File="$Spark_Distribution_Name".tgz
libSparkFHEName="libSparkFHE"


### UPDATE AUTOMATICALLY by running deploy.bash
SparkFHE_Plugin_latest_jar_file=spiritlab/sparkfhe/spark-fhe_2.12/1.0-SNAPSHOT/spark-fhe_2.12-1.0-20190528.232552-1-jar-with-dependencies.jar
SparkFHE_API_latest_jar_file=spiritlab/sparkfhe/sparkfhe-api/1.0-SNAPSHOT/sparkfhe-api-1.0-20190611.052620-1.jar
SparkFHE_Examples_latest_jar_file=spiritlab/sparkfhe/sparkfhe-examples/1.0-SNAPSHOT/sparkfhe-examples-1.0-20190613.161525-1.jar
#######################################
Current_Directory=`pwd`


function CheckCommands() {
	commands=( "wget" "unzip" "awk" )
	for ((idx=0; idx<${#commands[@]}; ++idx)); do
		echo "Checking command: ${commands[idx]}..."
		`${commands[idx]} 2>tmpCommandCheck` &>/dev/null
		if [[ `grep "command not found" tmpCommandCheck` == "" ]] ; then echo "${commands[idx]} found!"; else echo "${commands[idx]} not found, install and try again."; exit 0; fi
		rm tmpCommandCheck
	done
}

function CheckCommand() {
	command=$1
	echo "Checking command: $command..."
	`$command 2>tmpCommandCheck` &>/dev/null
	if [[ `grep "command not found" tmpCommandCheck` == "" ]] ; then echo "$command found!"; else echo "$command not found, install and try again."; exit 0; fi
	rm tmpCommandCheck
	
}


function Usage() {
    echo "Usage: $0 PackageName"
    echo "Which package do you want to install or update?"
    echo "hadoop 		Apache Hadoop distribution package"
    echo "spark 		Apache Spark distribution package"
    echo "dependencies 	download and install plugin, api, and examples"
    echo "addon 		sparkfhe addon (scripts, resources)"
    echo "lib 			libSparkFHE.so (unix), libSparkFHE.dylib (mac osx)"
    echo "all   		all packages"
    echo "selfupdate	update TestDrive.bash to the lastest version"
    exit
}


function fetch_spark_distribution() {
	echo "Fetching $Spark_Distribution_Name from aws s3..."
	rm -rf $Spark_Distribution_File $Spark_Distribution_Name 
	wget $SparkFHE_AWS_S3_Base_URL/dist/$Spark_Distribution_File
	tar xzf $Spark_Distribution_File
	rm $Spark_Distribution_File
}


function fetch_hadoop_distribution() {
	echo "Fetching $Hadoop_Distribution_Name from aws s3..."
	cd $Spark_Distribution_Name
	arch=$(mvn --version | grep -o 'arch: [^,]*' | awk -F: 'gsub(/: /, ":") && gsub(/"/,"") {print $2}')
	family=$(mvn --version | grep -o 'family: [^,]*' | awk -F: 'gsub(/: /, ":") && gsub(/"/,"") {print $2}')
	Hadoop_Distribution_File="$Hadoop_Distribution_Name"-"$family"-"$arch".tar.gz
	rm -rf $Hadoop_Distribution_File $Hadoop_Distribution_Name
	wget $SparkFHE_AWS_S3_Base_URL/dist/$Hadoop_Distribution_File
	tar xzf $Hadoop_Distribution_File
	rm $Hadoop_Distribution_File

	mkdir -p /tmp/hadoop
	wget $SparkFHE_AWS_S3_Base_URL/dist/$HadoopConfigFiles
	unzip -q -u $HadoopConfigFiles
	rm -rf $Hadoop_Distribution_Name/etc/*
	mv hadoop $Hadoop_Distribution_Name/etc/
	rm -rf $HadoopConfigFiles hadoop

	if [[ "$ExtraArg" != "" ]] ; then
		NUM_OF_WORKERS=$ExtraArg
		rm -rf $Hadoop_Distribution_Name/etc/hadoop/workers
		for i in $(seq 1 $NUM_OF_WORKERS); do 
			echo "worker$i" >> $Hadoop_Distribution_Name/etc/hadoop/workers
		done
	fi

	mv $Hadoop_Distribution_Name hadoop
	cd $Current_Directory
	echo "DONE"
}


function fetch_dependencies() {
	echo "Fetching dependencies..."
	cd $Spark_Distribution_Name
	jar_files=(spark-fhe sparkfhe-api)
	for ((idx=0; idx<${#jar_files[@]}; ++idx)); do
		jar_file=$(ls jars | grep ${jar_files[idx]})
		if [[ "$jar_file" != "" ]] ; then rm jars/$jar_file; fi
	done
	wget $SparkFHE_Maven_Repo_Base_URL/$SparkFHE_Plugin_latest_jar_file
	wget $SparkFHE_Maven_Repo_Base_URL/$SparkFHE_API_latest_jar_file
	mv *.jar jars/
	jar_file=$(ls examples/jars | grep sparkfhe-examples)
	if [[ "$jar_file" != "" ]] ; then rm examples/jars/$jar_file; fi
	wget $SparkFHE_Maven_Repo_Base_URL/$SparkFHE_Examples_latest_jar_file
	mv *.jar examples/jars/
	cd $Current_Directory
	echo "DONE"
}


function fetch_sparkfhe_addon() {
	echo "Fetching SparkFHE-Addon from GitHub..."
	cd $Spark_Distribution_Name
	git clone https://github.com/SpiRITlab/SparkFHE-Addon.git 
	cd SparkFHE-Addon/scripts/setup

	OSname=`uname`
	if [ $OSname == "Linux" ] ; then
		bash pre_install_debian.bash
	elif [ $OSname == "Darwin" ] ; then
		bash pre_install_mac_osx.bash
	else
		echo "Currently, we only have support for Mac OSX and Linux (e.g., Ubuntu)."
		exit 0;
	fi

	cd $Current_Directory
	echo "DONE"
}


function fetch_shared_libraries() {
	echo "Fetching shared libraries..."
	CheckCommand "mvn"
	cd $Spark_Distribution_Name
	arch=$(mvn --version | grep -o 'arch: [^,]*' | awk -F: 'gsub(/: /, ":") && gsub(/"/,"") {print $2}')
	family=$(mvn --version | grep -o 'family: [^,]*' | awk -F: 'gsub(/: /, ":") && gsub(/"/,"") {print $2}')
	rm -rf "$libSparkFHEName"-"$family"-"$arch".zip
	wget $SparkFHE_AWS_S3_Base_URL/$libSparkFHEName/"$libSparkFHEName"-"$family"-"$arch".zip
	if [[ -d "$libSparkFHEName" ]] ; then
		mkdir -p tmp_$libSparkFHEName
		rm -rf $libSparkFHEName/lib/$libSparkFHEName.*
		unzip -q -u "$libSparkFHEName"-"$family"-"$arch".zip -d tmp_$libSparkFHEName
		mv tmp_$libSparkFHEName/$libSparkFHEName/lib/$libSparkFHEName.* $libSparkFHEName/lib/
		rm -rf tmp_$libSparkFHEName
	else	
		unzip -q -u "$libSparkFHEName"-"$family"-"$arch".zip
	fi
	rm -rf "$libSparkFHEName"-"$family"-"$arch".zip
	cd $Current_Directory
	echo "DONE"
}

function update_environment_variables() {
	if [ "$Current_Directory" == "/" ] ; then
		SPARKFHE_HOME=/$Spark_Distribution_Name
	else
		SPARKFHE_HOME=$Current_Directory/$Spark_Distribution_Name
	fi
	HADOOP_HOME=$SPARKFHE_HOME/hadoop
	HADOOP_CLASSPATH=$(find $HADOOP_HOME -name "*.jar" | xargs echo | tr " " ":")

	# add to PATH variable
	if [[ "$(grep $Spark_Distribution_Name ~/.bashrc)" == "" ]] ; then 
		echo "
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export SPARKFHE_HOME=$SPARKFHE_HOME

# Hadoop Environment Variables
export HADOOP_HOME=$SPARKFHE_HOME/hadoop
export HADOOP_PREFIX=$HADOOP_HOME
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
export HADOOP_CLASSPATH=\$(find $HADOOP_HOME -name \"*.jar\" | xargs echo | tr \" \" \":\")
export CLASSPATH=$CLASSPATH:\$HADOOP_CLASSPATH

export HDFS_NAMENODE_USER=\"root\"
export HDFS_DATANODE_USER=\"root\"
export HDFS_SECONDARYNAMENODE_USER=\"root\"
export YARN_RESOURCEMANAGER_USER=\"root\"
export YARN_NODEMANAGER_USER=\"root\"

# Hadoop native path
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
export HADOOP_OPTS=\"-Djava.library.path=$HADOOP_HOME/lib/native\"
export LD_LIBRARY_PATH=$HADOOP_HOME/lib/native:$LD_LIBRARY_PATH

# SparkFHE Environment Variables
export PATH=$SPARKFHE_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH" >> ~/.bashrc
		source ~/.bashrc
	fi
}

function selfupdate() {
	echo "Updating TestDrive.bash script..."
	wget https://github.com/SpiRITlab/SparkFHE-Maven-Repo/raw/master/TestDrive.bash -O TestDrive.bash.bak
	echo "renaming TestDrive.bash.bak to TestDrive.bash..."
	mv TestDrive.bash.bak TestDrive.bash
}


function print_hadoop_statement() {
	echo "============================================================================================"
	echo "If you are a developer of our SparkFHE shared library, you may want to create this softlink:"
	echo "sudo ln -s $Spark_Distribution_Name/hadoop /usr/local/"
	echo "============================================================================================"
}

CheckCommands

PackageName=$1
ExtraArg=$2
if [[ "$PackageName" == "" ]]; then
  	Usage
elif [[ "$PackageName" == "hadoop" ]]; then
	fetch_hadoop_distribution $ExtraArg
	print_hadoop_statement
elif [[ "$PackageName" == "spark" ]]; then
	fetch_spark_distribution
elif [[ "$PackageName" == "dependencies" ]]; then
	fetch_dependencies
elif [[ "$PackageName" == "addon" ]]; then
	fetch_sparkfhe_addon
elif [[ "$PackageName" == "lib" ]]; then
	fetch_shared_libraries
elif [[ "$PackageName" == "variables" ]]; then
	update_environment_variables
elif [[ "$PackageName" == "all" ]]; then
	fetch_spark_distribution
	fetch_hadoop_distribution $ExtraArg
	fetch_dependencies
	fetch_sparkfhe_addon
	fetch_shared_libraries
	update_environment_variables
	print_hadoop_statement
elif [[ "$PackageName" == "selfupdate" ]]; then
	selfupdate
fi


echo "The SparkFHE environment is all set. Enjoy!"


