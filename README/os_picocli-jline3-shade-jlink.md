## links

shade:  
https://headcrashing.wordpress.com/2020/02/23/reducing-jar-footprint-with-maven-shade-plugin-3-2-2/  
https://dev.to/cicirello/how-to-use-the-maven-shade-plugin-if-your-project-uses-java-platform-module-system-2cmh

jdeps:  
https://blog.idrsolutions.com/how-to-create-a-module-info-file-with-jdeps/  
https://gist.github.com/fundter/d2cd7551cc818ceb8e77d5ebc2884535  
https://stackoverflow.com/questions/71276373/how-to-calculate-list-of-needed-java-modules-with-jdeps  
https://stackoverflow.com/questions/47727869/creating-module-info-for-automatic-modules-with-jdeps-in-java-9  
https://livebook.manning.com/book/the-java-9-module-system/d-analyzing-a-project-s-dependencies-with-jdeps/v-10/13  
https://nipafx.dev/jdeps-tutorial-analyze-java-project-dependencies/  
https://www.oreilly.com/library/view/modular-programming-in/9781787126909/eafc9b7d-8c64-4020-8a1a-763621a69f38.xhtml  
https://www.informit.com/articles/article.aspx?p=3197428&seqNum=8  
https://github.com/aws-samples/aws-lambda-java-custom-runtime/tree/main

moditect:  
https://blog.bmarwell.de/2020/12/08/use-snakeyaml-in-a-modular-jlink-distribution.html  
https://stackoverflow.com/questions/76400567/using-moditect-to-add-module-info-to-existing-maven-dependencies  
https://www.praj.in/posts/2020/self-contained-native-looking-apps/  
https://stackoverflow.com/questions/51751981/why-does-maven-shade-plugin-remove-module-info-class  
https://jaehong21.com/posts/java/java-jdeps-jlink/

list just the not found dependencies

```bash
./automatic-to-explicit.sh
```

./automatic-to-explicit.sh

```bash
jdeps --list-deps something.jar
```

```bash
jdeps \
--ignore-missing-deps \
--print-module-deps \
-q \
--recursive \
--multi-release 17 \
target/cluster-selector-1.0.0.jar > target/exjar/deps.info


jdeps \
--print-module-deps \
-q \
--recursive \
--multi-release 17 \
target/cluster-selector-1.0.0.jar > target/exjar/deps.info

```

```bash
jdeps --ignore-missing-deps --generate-module-info . target/cluster-selector-1.0.0.jar
```

```bash
export MODDEPS=$(jdeps --ignore-missing-deps --module-path target/libs --multi-release 17 --recursive --print-module-deps target/cluster-selector-1.0.0.jar)
jlink \
    --verbose \
    --module-path target/libs \
    --add-modules $MODDEPS \
    --strip-debug \
    --no-man-pages --no-header-files \
    --compress=2 \
    --output target/exjar/jre
```

```bash
jlink --module-path <jdk-11-path>/jmods:<javafx-jmods-11-path>:<javafx-sdk-11-path>/lib/javafx.base.jar:<javafx-sdk-11-path>/lib/javafx.controls.jar:<javafx-sdk-11-path>/lib/javafx.graphics.jar:<path-to-projects>/TestFXord/dist/TestFXord.jar --add-modules TestFXord --strip-debug --launcher TestFXord=TestFXord/testfxord.TestFXord --output dist/jlink/TestFXord
```

```bash
mkdir -p target/exjar/jre
mkdir -p target/exjar/app
```

```bash
export JAVA_HOME=/home/developer1/code/cluster-selector/target/exjar/jre ;\
export PATH="${JAVA_HOME}/bin:${PATH}" 
java -jar target/cluster-selector-1.0.0.jar --username your-username
```