# Use official Java 17 image
FROM openjdk:17-jdk-slim

# Set the JAR file location
ARG JAR_FILE=target/*.jar

# Copy the JAR file into the container
COPY ${JAR_FILE} app.jar

# Command to run the application
ENTRYPOINT ["java", "-jar", "/app.jar"]
