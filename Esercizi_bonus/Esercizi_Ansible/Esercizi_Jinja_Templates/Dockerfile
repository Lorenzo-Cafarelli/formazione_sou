# Dockerfile generato dinamicamente
FROM openjdk:17-slim

LABEL maintainer="DevOpsTribe"

# Installazione pacchetti condizionale
RUN apt-get update && apt-get install -y curl vim htop

WORKDIR /app

# Copia app
COPY myapp-1.0.jar .

# Esposizione porta dinamica
EXPOSE 8080

CMD ["java", "-jar", "myapp-1.0.jar"]