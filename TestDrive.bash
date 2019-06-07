#!/bin/bash

# This script will automatically fetch all dependencies and setup a spark environment for testing the SparkFHE project code.
# NOTE, it is still a research project. 

SparkFHE_Maven_Repo_Base_URL=https://github.com/SpiRITlab/SparkFHE-Maven-Repo/raw/master
SparkFHE_AWS_S3_Base_URL=https://sparkfhe.s3.amazonaws.com


Hadoop_Distribution_Name=hadoop-3.3.0-SNAPSHOT
Hadoop_Distribution_File="$Hadoop_Distribution_Name".tar.gz
HadoopConfigFiles=hadoop.zip
Spark_Distribution_Name=spark-3.0.0-SNAPSHOT-bin-SparkFHE
Spark_Distribution_File="$Spark_Distribution_Name".tgz
libSparkFHEName="libSparkFHE"


### UPDATE AUTOMATICALLY by running deploy.bash
SparkFHE_Plugin_latest_jar_file=spiritlab/sparkfhe/spark-fhe_2.12/1.0-SNAPSHOT/spark-fhe_2.12-1.0-20190528.232552-1-jar-with-dependencies.jar
SparkFHE_API_latest_jar_file=spiritlab/sparkfhe/sparkfhe-api/1.0-SNAPSHOT/sparkfhe-api-1.0-20190606.040204-1.jar
SparkFHE_Examples_latest_jar_file=spiritlab/sparkfhe/sparkfhe-examples/1.0-SNAPSHOT/sparkfhe-examples-1.0-20190530.185459-1.jar
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
    echo "Which package do you want to deploy to SparkFHEMavenRepo?"
    echo "hadoop 		Apache Hadoop distribution package"
    echo "spark 		Apache Spark distribution package"
    echo "dependencies 	download and install plugin, api, and examples"
    echo "addon 		sparkfhe addon (scripts, resources)"
    echo "lib 			libSparkFHE.so (unix), libSparkFHE.dylib (mac osx)"
    echo "all   		deploy all packages"
    exit
}


function fetch_spark_distribution() {
	echo "Fetching $Spark_Distribution..."
	rm -rf $Spark_Distribution_File $Spark_Distribution_Name 
	wget $SparkFHE_AWS_S3_Base_URL/dist/$Spark_Distribution_File
	tar xzf $Spark_Distribution_File
	rm $Spark_Distribution_File
}


function fetch_hadoop_distribution() {
	NUM_OF_WORKERS=$ExtraArg
	echo "Fetching $Hadoop_Distribution..."
	cd $Spark_Distribution_Name
	rm -rf $Hadoop_Distribution_File $Hadoop_Distribution_Name
	wget $SparkFHE_AWS_S3_Base_URL/dist/$Hadoop_Distribution_File
	tar xzf $Hadoop_Distribution_File
	rm $Hadoop_Distribution_File

	mkdir -p /tmp/hadoop
	wget $SparkFHE_AWS_S3_Base_URL/dist/$HadoopConfigFiles
	unzip -q -u "$HadoopConfigFiles".zip
	mv hadoop $Hadoop_Distribution_Name/etc/

	rm -p $$Hadoop_Distribution_Name/etc/hadoop/workers
	for i in $(seq 1 $NUM_OF_WORKERS); do 
		echo "worker$i" >> $Hadoop_Distribution_Name/etc/hadoop/workers
	done

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
	unzip -q -u "$libSparkFHEName"-"$family"-"$arch".zip 
	rm -rf "$libSparkFHEName"-"$family"-"$arch".zip
	cd $Current_Directory
	echo "DONE"
}


CheckCommands

PackageName=$1
ExtraArg=$2
if [[ "$PackageName" == "" ]]; then
  	Usage
elif [[ "$PackageName" == "hadoop" ]]; then
	fetch_hadoop_distribution $ExtraArg
elif [[ "$PackageName" == "spark" ]]; then
	fetch_spark_distribution
elif [[ "$PackageName" == "dependencies" ]]; then
	fetch_dependencies
elif [[ "$PackageName" == "addon" ]]; then
	fetch_sparkfhe_addon
elif [[ "$PackageName" == "lib" ]]; then
	fetch_shared_libraries
elif [[ "$PackageName" == "all" ]]; then
	fetch_spark_distribution
	fetch_hadoop_distribution $ExtraArg
	fetch_dependencies
	fetch_sparkfhe_addon
	fetch_shared_libraries
fi



# add to PATH variable
bashrc_changed=false
if [[ "$(grep $Spark_Distribution_Name ~/.bashrc)" == "" ]] ; then 
	echo "export PATH=$Current_Directory/$Spark_Distribution_Name/bin:"'$PATH' >> ~/.bashrc
	bashrc_changed=true
fi
if [[ "$(grep hadoop ~/.bashrc)" == "" ]] ; then 
	echo "export PATH=$Current_Directory/$Hadoop_Distribution_Name/bin:$Current_Directory/$Hadoop_Distribution_Name/sbin:"'$PATH' >> ~/.bashrc
	bashrc_changed=true
fi

if [ "$bashrc_changed" = true ] ; then
	source ~/.bashrc
fi

echo "The SparkFHE environment is all set. Enjoy!"


