FROM maven:3.8.3-openjdk-17 AS builder
WORKDIR /app
COPY . .
RUN mvn clean
RUN mvn install -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/product-service-0.0.1-SNAPSHOT.jar .
CMD ["java","-jar","product-service-0.0.1-SNAPSHOT.jar"]
