# mysql-aws-3

API REST de Estudiantes (Spring Boot 3.3.7, Java 17, MySQL 8) lista para desplegar en AWS.
Evolución de [`mysql-local-2.4`](../mysql-local-2.4/) para las guías de la unidad 3.2.2:

- **Opción A — EKS + Istio + Kiali:** [`../GUIA_ESTUDIANTE_3.2.2_OPCION_A_EKS.md`](../GUIA_ESTUDIANTE_3.2.2_OPCION_A_EKS.md)
- **Opción B — ECS Fargate + Service Connect + CloudWatch:** [`../GUIA_ESTUDIANTE_3.2.2_OPCION_B_ECS.md`](../GUIA_ESTUDIANTE_3.2.2_OPCION_B_ECS.md)

## Qué cambió respecto de `mysql-local-2.4`

| Archivo | Cambio |
|---|---|
| `pom.xml` | Nombre/clave de SonarCloud `mysql-aws-3`; añade `spring-boot-starter-actuator` |
| `application.properties` | Probes de Actuator, `hikari.connection-timeout=3000`, apagado graceful, sin SQL en logs |
| `GlobalExceptionHandler` | Errores de base de datos devuelven **503** (antes 400) |
| `StudentControllerTest` | Nuevo test del 503 |
| `Dockerfile` | Usuario no root (UID 10001) y `MaxRAMPercentage=75` |
| `docker-compose.yml` | `healthcheck` de la API |
| `.github/workflows/main.yml` | Imagen etiquetada con el SHA del commit; no publica en pull requests |
| `.github/workflows/deploy-eks.yml` | **Nuevo:** despliegue manual a EKS + Istio |
| `.github/workflows/deploy-ecs.yml` | **Nuevo:** despliegue manual a ECS Fargate |
| `k8s/` | **Nuevo:** manifiestos de Kubernetes e Istio |
| `ecs/` | **Nuevo:** plantillas de ECS y `render.sh` |

La lógica de negocio (entidad, repositorio, servicio, controlador) no cambia.

## Ejecutar en local

```bash
mvn test                  # usa H2 en memoria, no necesita MySQL
docker-compose up --build # MySQL + API en http://localhost:8080
```

Endpoints: `/students` (CRUD), `/actuator/health`, `/swagger-ui.html`.

## Estructura

```
mysql-aws-3/
├── src/                      código de la API y tests
├── Dockerfile
├── docker-compose.yml
├── k8s/                      EKS + Istio (namespace, MySQL, API, Gateway, seguridad)
├── ecs/                      ECS Fargate (task definitions, servicios, dashboard)
│   └── render.sh             genera ecs/out/*.json con tus valores
└── .github/workflows/
    ├── main.yml              CI: tests, SonarCloud, Snyk, imagen en DockerHub
    ├── deploy-eks.yml        despliegue manual a EKS
    └── deploy-ecs.yml        despliegue manual a ECS
```

## Secretos de GitHub

| Secreto | Usado por |
|---|---|
| `SONAR_TOKEN`, `SONAR_PROJECT_KEY`, `SONAR_ORGANIZATION`, `SNYK_TOKEN` | `main.yml` |
| `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` | `main.yml` y los despliegues |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` | `deploy-eks.yml`, `deploy-ecs.yml` |

## Notas

- Las credenciales de MySQL son **de laboratorio** (las mismas que `docker-compose.yml`). En un entorno real usa AWS Secrets Manager.
- MySQL usa almacenamiento efímero: los datos se pierden al recrear el pod o la tarea.
- Compila a bytecode Java 17 (`maven.compiler.release=17`); el CI usa JDK 21 solo para ejecutar el scanner de SonarCloud.
