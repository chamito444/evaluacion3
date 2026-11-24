# ─────────────────────────────────────────────
# ETAPA 1: Build (compilar la aplicación)
# ─────────────────────────────────────────────
FROM eclipse-temurin:17-jdk AS build

# Instala Maven
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia el descriptor de dependencias primero (aprovecha el caché de Docker)
COPY pom.xml .
RUN mvn dependency:go-offline -q

# Copia el código fuente y compila
COPY src ./src
RUN mvn clean package -DskipTests -q

# ─────────────────────────────────────────────
# ETAPA 2: Runtime (imagen final, más liviana)
# ─────────────────────────────────────────────
FROM eclipse-temurin:17-jre

# Usuario sin privilegios con UID numérico (Kubernetes necesita un UID numérico
# para verificar runAsNonRoot). EKS y ECS no deben ejecutar la app como root.
RUN groupadd --system --gid 10001 app && useradd --system --uid 10001 --gid app --no-create-home app

WORKDIR /app

# Solo copia el .jar generado en la etapa anterior
COPY --from=build /app/target/bdget-0.0.1-SNAPSHOT.jar app.jar

USER 10001

# Puerto que expone la aplicación
EXPOSE 8080

# La JVM ajusta el heap al límite de memoria del contenedor (pod de EKS / tarea de ECS)
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0"

# Comando de arranque
ENTRYPOINT ["java", "-jar", "app.jar"]
