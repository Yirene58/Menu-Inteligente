FROM maven:3.9-eclipse-temurin-25 AS build
WORKDIR /app
# Copia explícitamente el pom.xml primero
COPY pom.xml .
# Luego copia el resto del código fuente
COPY src ./src
# Ejecuta Maven (ya no necesitas -f porque el pom está en el directorio actual)
RUN mvn package -DskipTests

FROM eclipse-temurin:25-jre-alpine
WORKDIR /deployments
COPY --from=build /app/target/quarkus-app/lib/ /deployments/lib/
COPY --from=build /app/target/quarkus-app/*.jar /deployments/
COPY --from=build /app/target/quarkus-app/app/ /deployments/app/
COPY --from=build /app/target/quarkus-app/quarkus/ /deployments/quarkus/
EXPOSE 8080
CMD ["java", "-jar", "/deployments/quarkus-run.jar"]
