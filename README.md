# SparkFHE-Maven-Repo

## For Developers
* Deploy.bash script can be used as follows
```
$> bash deploy.bash [ARGUMENT]
```
Here is a list of ARGUMENTs:
```
spark           Apache Spark distributionpackages
dependencies    download and install plugin, api, and examples
addon           sparkfhe addon (scripts, resources)
lib             libSparkFHE.so (unix), libSparkFHE.dylib (mac osx)
all             deploy all packages
```

## For Testers
* Usage of our packages in Gradle

```
repositories {
    maven {
        url "https://raw.githubusercontent.com/SpiRITlab/SparkFHE-Maven-Repo/master"
    }

    mavenLocal()
    
    // must be the last
    mavenCentral()
}

dependencies {
    def scala_snapshot_version='2.12'
    def spark_snapshot_version='3.0.0'
    compile group: 'org.apache.spark', name: "spark-core_${scala_snapshot_version}", version: "${spark_snapshot_version}-SNAPSHOT"
    compile group: 'org.apache.spark', name: "spark-streaming_${scala_snapshot_version}", version: "${spark_snapshot_version}-SNAPSHOT"
    compile group: 'org.apache.spark', name: "spark-sql_${scala_snapshot_version}", version: "${spark_snapshot_version}-SNAPSHOT"
    compile group: 'org.apache.spark', name: "spark-hive_${scala_snapshot_version}", version: "${spark_snapshot_version}-SNAPSHOT"
    compile group: 'org.apache.spark', name: "spark-graphx_${scala_snapshot_version}", version: "${spark_snapshot_version}-SNAPSHOT"
    compile group: 'org.apache.spark', name: "spark-catalyst_${scala_snapshot_version}", version: "${spark_snapshot_version}-SNAPSHOT"
    compile group: 'org.apache.spark', name: "spark-launcher_${scala_snapshot_version}", version: "${spark_snapshot_version}-SNAPSHOT"
    compile group: 'org.apache.spark', name: "spark-mllib_${scala_snapshot_version}", version: "${spark_snapshot_version}-SNAPSHOT"
    compile group: 'org.apache.spark', name: "spark-mllib-local_${scala_snapshot_version}", version: "${spark_snapshot_version}-SNAPSHOT"


    /* others */
    compile group: 'spiritlab.sparkfhe', name: 'sparkfhe-api', version: '1.0-SNAPSHOT'
}
```



* Usage in Maven

```
<properties>
    <scala.binary.version>2.12</scala.binary.version>
    <spark.version>3.0.0-SNAPSHOT</spark.version>
    <scala.version>2.12.7</scala.version>
    <fasterxml.jackson.version>2.9.6</fasterxml.jackson.version>
</properties>

<dependencies>
    <!-- =============== Spark dependency block =============== -->
    <dependency>
      <groupId>com.fasterxml.jackson.core</groupId>
      <artifactId>jackson-core</artifactId>
      <version>${fasterxml.jackson.version}</version>
    </dependency>
    <dependency>
      <groupId>com.fasterxml.jackson.core</groupId>
      <artifactId>jackson-databind</artifactId>
      <version>${fasterxml.jackson.version}</version>
    </dependency>
    <dependency>
      <groupId>com.fasterxml.jackson.core</groupId>
      <artifactId>jackson-annotations</artifactId>
      <version>${fasterxml.jackson.version}</version>
    </dependency>
    <dependency>
      <groupId>com.fasterxml.jackson.module</groupId>
      <artifactId>jackson-module-jaxb-annotations</artifactId>
      <version>${fasterxml.jackson.version}</version>
    </dependency>
    <dependency>
      <groupId>org.json4s</groupId>
      <artifactId>json4s-jackson_${scala.binary.version}</artifactId>
      <version>3.5.3</version>
      <exclusions>
        <exclusion>
          <groupId>com.fasterxml.jackson.core</groupId>
          <artifactId>*</artifactId>
        </exclusion>
      </exclusions>
    </dependency>
    <dependency>
      <groupId>org.scala-lang</groupId>
      <artifactId>scala-compiler</artifactId>
      <version>${scala.version}</version>
    </dependency>
    <dependency>
      <groupId>org.scala-lang</groupId>
      <artifactId>scala-reflect</artifactId>
      <version>${scala.version}</version>
    </dependency>
    <dependency>
      <groupId>org.scala-lang</groupId>
      <artifactId>scala-library</artifactId>
      <version>${scala.version}</version>
    </dependency>
    <dependency>
      <groupId>org.scala-lang</groupId>
      <artifactId>scala-actors</artifactId>
      <version>2.11.12</version>
    </dependency>
    <dependency>
      <groupId>org.scala-lang.modules</groupId>
      <artifactId>scala-parser-combinators_${scala.binary.version}</artifactId>
      <version>1.1.0</version>
    </dependency>

    <dependency>
    <groupId>org.apache.spark</groupId>
    <artifactId>spark-core_${scala.binary.version}</artifactId>
    <version>${spark.version}</version>
    <scope>compile</scope>
    </dependency>
    <dependency>
    <groupId>org.apache.spark</groupId>
    <artifactId>spark-sql_${scala.binary.version}</artifactId>
    <version>${spark.version}</version>
    <scope>compile</scope>
    </dependency>
    <dependency>
    <groupId>org.apache.spark</groupId>
    <artifactId>spark-catalyst_${scala.binary.version}</artifactId>
    <version>${spark.version}</version>
    <scope>compile</scope>
    </dependency>
    <dependency>
    <groupId>org.apache.spark</groupId>
    <artifactId>spark-launcher_${scala.binary.version}</artifactId>
    <version>${spark.version}</version>
    <scope>compile</scope>
    </dependency>
    <dependency>
    <groupId>org.apache.spark</groupId>
    <artifactId>spark-mllib_${scala.binary.version}</artifactId>
    <version>${spark.version}</version>
    <scope>compile</scope>
    </dependency>
    <dependency>
    <groupId>org.apache.spark</groupId>
    <artifactId>spark-mllib-local_${scala.binary.version}</artifactId>
    <version>${spark.version}</version>
    <scope>compile</scope>
    </dependency>
    <dependency>
      <groupId>org.apache.spark</groupId>
      <artifactId>spark-hive_${scala.binary.version}</artifactId>
      <version>${spark.version}</version>
      <scope>compile</scope>
    </dependency>
    <!-- =============== END of Spark dependency block =============== -->
    
    <dependency>
      <groupId>spiritlab.sparkfhe</groupId>
      <artifactId>sparkfhe-api</artifactId>
      <version>1.0-SNAPSHOT</version>
      <scope>compile</scope>
    </dependency>
</dependencies>
```





