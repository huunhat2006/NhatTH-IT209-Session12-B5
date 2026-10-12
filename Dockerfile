# Multi-stage Dockerfile for Sample Application
FROM alpine:3.19

LABEL maintainer="huunhat2006"
LABEL description="Sample application for IT209 Session 12 Exercise 5"

WORKDIR /app

RUN echo "CI/CD Pipeline Fixed Successfully!" > build-info.txt

CMD ["cat", "build-info.txt"]
