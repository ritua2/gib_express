#FROM  tomcat:8.5.42
FROM tomcat:9.0

ENV JAVA_OPTS="$JAVA_OPTS --add-opens java.base/java.lang.invoke=ALL-UNNAMED -Xmx1024m"
RUN apt-get update && apt-get install openssh-client -y &&\
    # Removes the starting ROOT directory, which contains information about Tomcat itself
    # this will then be replaced by springipt (../docker-compose.yml volume for .war file)
    rm -rf /usr/local/tomcat/webapps/ROOT && echo $JAVA_OPTS
