#!/bin/bash

myUserName=peiworld

master=c220g1-031103.wisc.cloudlab.us
worker1=c220g1-031104.wisc.cloudlab.us
worker2=c220g1-031119.wisc.cloudlab.us

echo "Deleting old jar files..."
ssh -p 22 $myUserName@$master 'rm -rf /spark-3.0.0-SNAPSHOT-bin-SparkFHE/examples/jars/sparkfhe-examples*'
ssh -p 22 $myUserName@$worker1 'rm -rf /spark-3.0.0-SNAPSHOT-bin-SparkFHE/examples/jars/sparkfhe-examples*'
ssh -p 22 $myUserName@$worker2 'rm -rf /spark-3.0.0-SNAPSHOT-bin-SparkFHE/examples/jars/sparkfhe-examples*'

echo "Copying new jar files..."
scp $1 $myUserName@$master:/spark-3.0.0-SNAPSHOT-bin-SparkFHE/examples/jars/
scp $1 $myUserName@$worker1:/spark-3.0.0-SNAPSHOT-bin-SparkFHE/examples/jars/
scp $1 $myUserName@$worker2:/spark-3.0.0-SNAPSHOT-bin-SparkFHE/examples/jars/

