FROM maven:3.9-eclipse-temurin-25 AS build

WORKDIR /workspace

COPY mvnw pom.xml ./
COPY .mvn .mvn
COPY src src

RUN chmod +x mvnw && ./mvnw -B package -DskipTests

FROM eclipse-temurin:25-jre

WORKDIR /app

COPY --from=build /workspace/target/quarkus-app/ ./

USER 1001

EXPOSE 8080

CMD ["sh", "-c", "exec java -Dquarkus.http.host=0.0.0.0 -Dquarkus.http.port=${PORT:-8080} -Djava.util.logging.manager=org.jboss.logmanager.LogManager -jar /app/quarkus-run.jar"]
