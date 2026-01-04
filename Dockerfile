# two stages
# 1. build stage: use a mvn image to build the java project
FROM maven:3.8.5-openjdk-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean -B package -DskipTests

# 2. runtime stage: use a jre image to run the built jar file
FROM eclipse-temurin:17.0.17_10-jre-alpine-3.23
WORKDIR /app
COPY --from=build /app/target/tiny-url-app.jar .
EXPOSE 8080
CMD ["java", "-jar", "tiny-url-app.jar"]