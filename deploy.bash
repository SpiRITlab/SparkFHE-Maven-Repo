#!/bin/bash

DATE=`date '+%Y-%m-%d %H:%M:%S'`
currentDir=`pwd`
HadoopBasePath='../hadoop'
SparkBasePath='../spark'
SparkFHEApiPath='../SparkFHE/sparkfhe-api-java'
SparkFHEPluginPath='../SparkFHE-Plugin'
SparkFHEexamplesPath='../SparkFHE-Examples'
SparkFHEAddonPath='../SparkFHE-Addon'
libSparkFHEPath='../SparkFHE/deps/lib'

scala_version_number=2.12
release_version=1.1.1-SNAPSHOT
echo "Release Version: $release_version"

function CheckCommands() {
	commands=("mvn" "unzip" "awk" )
	for ((idx=0; idx<${#commands[@]}; ++idx)); do
		echo "Checking command: ${commands[idx]}..."
		`${commands[idx]} 2>tmp` &>/dev/null
		if [[ `grep "command not found" tmp` == "" ]] ; then echo "${commands[idx]} found!"; else echo "${commands[idx]} not found, install and try again."; exit 0; fi
		rm tmp
	done
}

function Usage() {
    echo "Usage: $0 PackageName [C]"
    echo "Which package do you want to deploy to SparkFHEMavenRepo?"
    echo "hadoopDist	hadoop package"
    echo "spark 		modified Apache Spark packages with FHE support."
    echo "sparkDist 	official spark distribution"
    echo "api 			sparkfhe-api.jar; an API for the C++ shared library"
    echo "plugin 		spark-fhe.jar; a SparkFHE plugin for Apache Spark"
    echo "examples 		sparkfhe-example.jar"
    echo "addon 		sparkfhe addon (scripts, resources)"
    echo "lib 			libSparkFHE.so (unix), libSparkFHE.dylib (mac osx)"
    echo "all   		deploy all packages"
    echo " "
    echo "C 			deploy&commit to SparkFHEMavenRepo or AWS S3 (deploy, but not commit&push by default)"
    exit
}

function DeployHadoopDistribution() {
	echo "Deploying hadoop distribution..."
	#format like this, OS name: "mac os x", version: "10.14.1", arch: "x86_64", family: "mac"
	arch=$(mvn --version | grep -o 'arch: [^,]*' | awk -F: 'gsub(/: /, ":") && gsub(/"/,"") {print $2}')
	family=$(mvn --version | grep -o 'family: [^,]*' | awk -F: 'gsub(/: /, ":") && gsub(/"/,"") {print $2}')
	HadoopVersion=hadoop-3.3.0-SNAPSHOT
	HadoopDistributionName="$HadoopVersion"-"$family"-"$arch".tar.gz
	rm -rf spiritlab/sparkfhe/"$HadoopVersion".tar.gz
	cp $HadoopBasePath/hadoop-dist/target/"$HadoopVersion".tar.gz spiritlab/sparkfhe/dist/$HadoopDistributionName
	cd $currentDir
}

function DeploySpark() {
	echo "Deploying modified apache spark-*..."
	rm -rf spiritlab/sparkfhe/research
	cd $SparkBasePath
	build/mvn -DskipTests deploy
	cd $currentDir
}

function DeploySparkDistribution() {
	SparkDistributionName=spark-3.1.0-SNAPSHOT-bin-SparkFHE.tgz
	echo "Deploying apache distribution..."
	rm -rf spiritlab/sparkfhe/$SparkDistributionName
	cp $SparkBasePath/$SparkDistributionName spiritlab/sparkfhe/dist/
	cd $currentDir
}


function DeployApi() {
	echo "Deploying sparkfhe-api..."
	rm -rf spiritlab/sparkfhe/sparkfhe-api
	cd $SparkFHEApiPath
	mvn -DskipTests deploy
	cd $currentDir

	# update TestDrive.bash
	# e.g., spiritlab/sparkfhe/sparkfhe-api/1.0-SNAPSHOT/sparkfhe-api-1.0-20181207.083754-1.jar
	SparkFHE_API_latest_jar_file=$(ls spiritlab/sparkfhe/sparkfhe-api/$release_version | awk 'match($0, /sparkfhe-api-[0-9].[0-9]-*.*-[0-9].jar$/) {print}')
	echo "Updating TestDrive.bash to use $SparkFHE_API_latest_jar_file..."
	sed -i'.bak' 's/SparkFHE_API_latest_jar_file=.*/SparkFHE_API_latest_jar_file=spiritlab\/sparkfhe\/sparkfhe-api'"\/$release_version\/$SparkFHE_API_latest_jar_file"'/g' TestDrive.bash
	rm TestDrive.bash.bak
}

function DeployPlugin() {
	echo "Deploying spark-fhe..."
	rm -rf spiritlab/sparkfhe/spark-fhe_*
	cd $SparkFHEPluginPath
	mvn -DskipTests deploy
	cd $currentDir

	# update TestDrive.bash
	# e.g., spiritlab/sparkfhe/spark-fhe_2.12/1.0-SNAPSHOT/spark-fhe_2.12-1.0-20181213.175432-1-jar-with-dependencies.jar	
	SparkFHE_Plugin_latest_jar_file=$(ls spiritlab/sparkfhe/spark-fhe_$scala_version_number/$release_version | awk 'match($0, /spark-fhe*.*-with-dependencies.jar$/) {print}')
	echo "Updating TestDrive.bash to use $SparkFHE_Plugin_latest_jar_file..."
	sed -i'.bak' 's/SparkFHE_Plugin_latest_jar_file=.*/SparkFHE_Plugin_latest_jar_file=spiritlab\/sparkfhe\/spark-fhe_'"$scala_version_number\/$release_version\/$SparkFHE_Plugin_latest_jar_file"'/g' TestDrive.bash
	rm TestDrive.bash.bak
}

function DeployExample() {
	# echo "Deploying sparkfhe-example..."
	rm -rf spiritlab/sparkfhe/sparkfhe-examples
	cd $SparkFHEexamplesPath
	rm -rf gen/keys gen/records
	mvn -DskipTests clean compile
	mvn -DskipTests deploy
	cd $currentDir

	# update TestDrive.bash
	# e.g., spiritlab/sparkfhe/sparkfhe-examples/1.0-SNAPSHOT/sparkfhe-examples-1.0-20181213.123133-1.jar
	SparkFHE_Examples_latest_jar_file=$(ls spiritlab/sparkfhe/sparkfhe-examples/$release_version | awk 'match($0, /sparkfhe-examples-[0-9].[0-9]-*.*-[0-9].jar$/) {print}')
	echo "Updating TestDrive.bash to use $SparkFHE_Examples_latest_jar_file..."
	sed -i'.bak' 's/SparkFHE_Examples_latest_jar_file=.*/SparkFHE_Examples_latest_jar_file=spiritlab\/sparkfhe\/sparkfhe-examples'"\/$release_version\/$SparkFHE_Examples_latest_jar_file"'/g' TestDrive.bash
	rm TestDrive.bash.bak
}


function DeployLib() {
	echo "Deploying libSparkFHE..."
	#format like this, OS name: "mac os x", version: "10.14.1", arch: "x86_64", family: "mac"
	arch=$(mvn --version | grep -o 'arch: [^,]*' | awk -F: 'gsub(/: /, ":") && gsub(/"/,"") {print $2}')
	family=$(mvn --version | grep -o 'family: [^,]*' | awk -F: 'gsub(/: /, ":") && gsub(/"/,"") {print $2}')
	libSparkFHEName="libSparkFHE"
	rm -rf $libSparkFHEName/"$libSparkFHEName"-"$family"-"$arch".zip
	mkdir -p $libSparkFHEName
	#find $libSparkFHEPath/ -maxdepth 1 -type f | xargs -I {} cp {} $libSparkFHEName/
	cd ../SparkFHE
	# Update: no longer need this
	# change the absolute path in shared lib produced by mac
	# if [[ "$family" == "mac" ]]; then
	# 	install_name_tool -change /Users/ph/myGit/project_on_vhost6/SparkFHE/deps/lib/libgmp.10.dylib @loader_path/libgmp.10.dylib deps/lib/libSparkFHE.dylib
	# 	install_name_tool -change /Users/ph/myGit/project_on_vhost6/SparkFHE/deps/lib/libgf2x.1.dylib @loader_path/libgf2x.1.dylib deps/lib/libSparkFHE.dylib
	# 	install_name_tool -add_rpath "@loader_path" deps/lib/libSparkFHE.dylib
	# 	install_name_tool -add_rpath "deps/lib" deps/lib/libSparkFHE.dylib	
	# fi
	zip -r $currentDir/$libSparkFHEName/"$libSparkFHEName"-"$family"-"$arch".zip deps/lib/$(ls deps/lib | awk '/libSparkFHE.so$/||/libSparkFHE.dylib$/')
	cd $currentDir
}


CheckCommands

PackageName=$1
C=$2
updatePkgName="."
if [[ "$PackageName" == "" ]]; then
  	Usage
elif [[ "$PackageName" == "hadoopDist" ]]; then
	DeployHadoopDistribution
	updatePkgName="spiritlab/sparkfhe/dist/HadoopDistribution"
elif [[ "$PackageName" == "hadoopConfig" ]]; then
	updatePkgName="spiritlab/sparkfhe/dist/HadoopConfig"
elif [[ "$PackageName" == "spark" ]]; then
	DeploySpark
	updatePkgName="spiritlab/sparkfhe/research/spark"
elif [[ "$PackageName" == "sparkDist" ]]; then
	DeploySparkDistribution
	updatePkgName="spiritlab/sparkfhe/dist/SparkDistribution"
elif [[ "$PackageName" == "api" ]]; then
	DeployApi
	updatePkgName="spiritlab/sparkfhe/sparkfhe-api"
elif [[ "$PackageName" == "plugin" ]]; then
	DeployPlugin
	updatePkgName="spiritlab/sparkfhe/spark-fhe"
elif [[ "$PackageName" == "examples" ]]; then
	DeployExample
	updatePkgName="spiritlab/sparkfhe/sparkfhe-examples"
elif [[ "$PackageName" == "lib" ]]; then
	DeployLib
	updatePkgName="libSparkFHE"
elif [[ "$PackageName" == "all" ]]; then
	DeployHadoopDistribution
	DeploySpark
	DeploySparkDistribution
	DeployApi
	DeployPlugin
	DeployExample
	DeployAddon
	DeployLib
	updatePkgName="all"
elif [[ "$PackageName" == "jars" ]]; then
	DeployApi
	DeployPlugin
	DeployExample
	updatePkgName="jars"
fi

if [[ "$C" == "C" && "$PackageName" != "hadoopConfig" \
	&& "$PackageName" != "hadoopDist" \
	&& "$PackageName" != "sparkDist" \
	&& "$PackageName" != "lib" \
	&& "$PackageName" != "plugin" \
	&& "$PackageName" != "api" \
	&& "$PackageName" != "examples" ]]; then
	git pull
	git add -A . && git commit -m "[$DATE] Update $PackageName package(s)"
	git push
elif [[ "$C" == "C" && "$PackageName" == "plugin" ]]; then
	aws s3 rm --recursive s3://sparkfhe/spiritlab/sparkfhe/spark-fhe_2.12
	aws s3 cp --recursive spiritlab/sparkfhe/spark-fhe_2.12 s3://sparkfhe/spiritlab/sparkfhe/spark-fhe_2.12
  	aws s3 cp TestDrive.bash s3://sparkfhe/TestDrive.bash
elif [[ "$C" == "C" && "$PackageName" == "api" ]]; then
	aws s3 rm --recursive s3://sparkfhe/spiritlab/sparkfhe/sparkfhe-api
	aws s3 cp --recursive spiritlab/sparkfhe/sparkfhe-api s3://sparkfhe/spiritlab/sparkfhe/sparkfhe-api
	aws s3 cp TestDrive.bash s3://sparkfhe/TestDrive.bash
elif [[ "$C" == "C" && "$PackageName" == "examples" ]]; then
	aws s3 rm --recursive s3://sparkfhe/spiritlab/sparkfhe/sparkfhe-examples
	aws s3 cp --recursive spiritlab/sparkfhe/sparkfhe-examples s3://sparkfhe/spiritlab/sparkfhe/sparkfhe-examples
	aws s3 cp TestDrive.bash s3://sparkfhe/TestDrive.bash
elif [[ "$C" == "C" && "$PackageName" == "hadoopConfig" ]]; then
	aws s3 cp spiritlab/sparkfhe/dist/hadoop.zip s3://sparkfhe/dist/	
elif [[ "$C" == "C" && "$PackageName" == "hadoopDist" ]]; then
	aws s3 cp spiritlab/sparkfhe/dist/$HadoopDistributionName s3://sparkfhe/dist/
elif [[ "$C" == "C" && "$PackageName" == "sparkDist" ]]; then
	aws s3 cp spiritlab/sparkfhe/dist/$SparkDistributionName s3://sparkfhe/dist/
elif [[ "$C" == "C" && "$PackageName" == "lib" ]]; then
	aws s3 cp libSparkFHE/"$libSparkFHEName"-"$family"-"$arch".zip s3://sparkfhe/libSparkFHE/
fi


