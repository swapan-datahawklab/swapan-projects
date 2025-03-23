export ="FOLDERNM"
cd DEMO_FOLDER
curl https://start.spring.io/starter.tgz -d dependencies=webflux -d name=js-demo -d type=maven-project | tar -xzvf -
add src/main/resources/static/index.html
./mvnw package
java -jar target/demo-0.0.1-SNAPSHOT.jar
http://localhost:8080/


add to pom.xml
<dependency>
	<groupId>org.webjars</groupId>
	<artifactId>webjars-locator-core</artifactId>
</dependency>
<dependency>
	<groupId>org.webjars.npm</groupId>
	<artifactId>bootstrap</artifactId>
	<version>5.1.3</version>
</dependency>

update src/main/resources/static/index.html
<head>
	...
	<link rel="stylesheet" type="text/css" href="/webjars/bootstrap/dist/css/bootstrap.min.css" />
</head>