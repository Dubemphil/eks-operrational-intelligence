ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM eclipse-temurin:21-jdk-noble AS builder

WORKDIR /app

COPY ["build.gradle", "gradlew", "./"]
COPY gradle gradle
RUN sed -i 's/\r$//' gradlew && chmod +x gradlew
RUN ./gradlew downloadRepos

COPY . .
RUN sed -i 's/\r$//' gradlew && chmod +x gradlew
RUN ./gradlew installDist

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app
COPY --from=builder /app .

EXPOSE 9555
ENTRYPOINT ["/app/build/install/hipstershop/bin/AdService"]
