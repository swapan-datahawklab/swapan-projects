#!/bin/bash

APP_NAME="cluster-selector"
MODULE_NAME="com.example.clusterselector"
BASE_DIR="$APP_NAME"
SRC_DIR="$BASE_DIR/src/main"
JAVA_DIR="$SRC_DIR/java"
PKG_DIR="$JAVA_DIR/com/example"
MODEL_DIR="$PKG_DIR/model"
SERVICE_DIR="$PKG_DIR/service"
RESOURCES_DIR="$SRC_DIR/resources"

echo "📁 Creating project structure..."
mkdir -p "$MODEL_DIR" "$SERVICE_DIR" "$RESOURCES_DIR"

echo "🧾 Writing pom.xml..."
cat > "$BASE_DIR/pom.xml" <<EOF
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>$APP_NAME</artifactId>
    <version>1.0.0</version>

    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>io.fabric8</groupId>
                <artifactId>kubernetes-client-bom</artifactId>
                <version>5.12.0</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <dependencies>
        <dependency>
            <groupId>info.picocli</groupId>
            <artifactId>picocli</artifactId>
            <version>4.7.4</version>
        </dependency>
        <dependency>
            <groupId>org.jline</groupId>
            <artifactId>jline</artifactId>
            <version>3.21.0</version>
        </dependency>
        <dependency>
            <groupId>io.fabric8</groupId>
            <artifactId>openshift-client</artifactId>
        </dependency>
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-core</artifactId>
            <version>2.15.3</version>
        </dependency>
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
            <version>2.15.3</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.8.1</version>
                <configuration>
                    <source>\${maven.compiler.source}</source>
                    <target>\${maven.compiler.target}</target>
                    <encoding>\${project.build.sourceEncoding}</encoding>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-jar-plugin</artifactId>
                <version>3.2.0</version>
                <configuration>
                    <archive>
                        <manifest>
                            <mainClass>com.example.ClusterSelector</mainClass>
                        </manifest>
                    </archive>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-jlink-plugin</artifactId>
                <version>3.1.0</version>
                <configuration>
                    <outputDirectory>\${project.build.directory}/image</outputDirectory>
                    <launcher>
                        <name>cluster-selector</name>
                    </launcher>
                    <addModules>
                        <addModule>$MODULE_NAME</addModule>
                    </addModules>
                    <stripDebug>true</stripDebug>
                    <compress>2</compress>
                    <noHeaderFiles>true</noHeaderFiles>
                    <noManPages>true</noManPages>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF

echo "📄 Writing module-info.java..."
cat > "$JAVA_DIR/module-info.java" <<EOF
module $MODULE_NAME {
    requires picocli;
    requires org.jline.reader;
    requires org.jline.terminal;
    requires io.fabric8.kubernetes.client;
    requires io.fabric8.openshift.client;
    requires com.fasterxml.jackson.databind;
    requires com.fasterxml.jackson.core;

    opens com.example to picocli;
    exports com.example;
    exports com.example.model;
    exports com.example.service;
}
EOF

echo "🧠 Writing Cluster.java..."
cat > "$MODEL_DIR/Cluster.java" <<EOF
package com.example.model;

public class Cluster {
    public final String id;
    public String context;
    public String name;
    public String env;

    public Cluster(String id) {
        this.id = id;
    }

    public void setProperty(String prop, String val) {
        switch(prop) {
            case "context": this.context = val; break;
            case "name": this.name = val; break;
            case "env": this.env = val; break;
        }
    }
}
EOF

echo "🔌 Writing ClusterConnector.java..."
cat > "$SERVICE_DIR/ClusterConnector.java" <<EOF
package com.example.service;

import com.example.model.Cluster;
import io.fabric8.kubernetes.client.Config;
import io.fabric8.kubernetes.client.ConfigBuilder;
import io.fabric8.kubernetes.client.DefaultKubernetesClient;
import io.fabric8.kubernetes.client.KubernetesClient;

public class ClusterConnector {
    public void connect(Cluster cluster) {
        Config config = new ConfigBuilder().withContext(cluster.context).build();
        try (KubernetesClient client = new DefaultKubernetesClient(config)) {
            System.out.printf("Connected to %s: version=%s%n", cluster.context, client.getVersion().getGitVersion());
        } catch (Exception e) {
            System.err.printf("Failed to connect to %s: %s%n", cluster.context, e.getMessage());
        }
    }
}
EOF

echo "🚦 Writing ClusterSelector.java..."
cat > "$PKG_DIR/ClusterSelector.java" <<EOF
package com.example;

import com.example.model.Cluster;
import com.example.service.ClusterConnector;
import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import org.jline.reader.LineReader;
import org.jline.reader.LineReaderBuilder;

import java.io.InputStream;
import java.util.*;
import java.util.concurrent.Callable;
import java.util.stream.Collectors;

@Command(name = "cluster-selector", mixinStandardHelpOptions = true, version = "1.2", description = "Interactive CLI to select OpenShift clusters from properties file")
public class ClusterSelector implements Callable<Integer> {
    @Option(names = {"-u", "--username"}, description = "Username")
    private String username;

    @Option(names = {"-e", "--env"}, description = "Environment (prod/non-prod)")
    private String env;

    public static void main(String[] args) {
        System.exit(new CommandLine(new ClusterSelector()).execute(args));
    }

    @Override
    public Integer call() throws Exception {
        LineReader reader = LineReaderBuilder.builder().build();
        if (username == null) username = reader.readLine("Enter username: ");
        if (env == null) env = reader.readLine("Select environment (prod/non-prod): ");

        Properties props = new Properties();
        try (InputStream is = getClass().getClassLoader().getResourceAsStream("clusterinfo.properties")) {
            props.load(is);
        }

        Map<String, Cluster> clusters = new HashMap<>();
        props.forEach((k, v) -> {
            String key = (String) k;
            if (key.startsWith("cluster.")) {
                String[] parts = key.split("\\\\.");
                String id = parts[1];
                clusters.computeIfAbsent(id, Cluster::new).setProperty(parts[2], (String) v);
            }
        });

        List<Cluster> filtered = clusters.values().stream()
            .filter(c -> c.env.equalsIgnoreCase(env))
            .collect(Collectors.toList());

        System.out.println("Available clusters:");
        for (int i = 0; i < filtered.size(); i++) {
            System.out.printf("%d) %s (%s)%n", i+1, filtered.get(i).name, filtered.get(i).context);
        }

        String input = reader.readLine("Select clusters by numbers (comma-separated) or 'all': ");
        List<Cluster> selected = "all".equalsIgnoreCase(input.trim()) ? filtered : Arrays.stream(input.split(","))
            .map(String::trim).map(Integer::parseInt).map(idx -> filtered.get(idx-1)).collect(Collectors.toList());

        System.out.println("Selected clusters:");
        selected.forEach(c -> System.out.printf("- %s%n", c.name));

        ClusterConnector connector = new ClusterConnector();
        for (Cluster c : selected) {
            connector.connect(c);
        }
        return 0;
    }
}
EOF

echo "📋 Writing clusterinfo.properties..."
cat > "$RESOURCES_DIR/clusterinfo.properties" <<EOF
cluster.cluster1.context=prod-context1
cluster.cluster1.name=Production Cluster One
cluster.cluster1.env=prod

cluster.cluster2.context=prod-context2
cluster.cluster2.name=Production Cluster Two
cluster.cluster2.env=prod

cluster.dev1.context=dev-context1
cluster.dev1.name=Development Cluster One
cluster.dev1.env=non-prod

cluster.dev2.context=dev-context2
cluster.dev2.name=Development Cluster Two
cluster.dev2.env=non-prod
EOF

echo "✅ Modular JLink-compatible project generated in ./$APP_NAME"

