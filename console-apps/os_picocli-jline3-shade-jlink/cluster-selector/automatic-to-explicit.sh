#!/bin/bash

# Ensure the temp directory exists
mkdir -p temp

# # Run the Maven copy-dependencies goal
# mvn dependency:copy-dependencies

for jar in target/libs/*.jar; do
    # Check if the jar has an automatic module
    if jdeps --multi-release 17 --print-module-deps "$jar" | grep -q 'not a modular jar'; then
        echo "Processing $jar"

        # Generate module-info.java
        jdeps --generate-module-info temp "$jar"
        if [ $? -ne 0 ]; then
            echo "Failed to generate module-info.java for $jar"
            continue
        fi

        # Compile the module-info.java
        javac --patch-module $(basename "$jar" .jar)=temp/$(basename "$jar" .jar) "$jar" temp/module-info.java
        if [ $? -ne 0 ]; then
            echo "Failed to compile module-info.java for $jar"
            continue
        fi

        # Update jar with module-info
        cd temp
        jar uf "$jar" module-info.class
        if [ $? -ne 0 ]; then
            echo "Failed to update $jar with module-info.class"
            cd ..
            continue
        fi
        cd ..

        echo "Successfully updated $jar with module-info.class"
    else
        echo "$jar does not have an automatic module"
    fi
done