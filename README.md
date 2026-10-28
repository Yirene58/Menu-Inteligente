# Menu Inteligente

El repositorio contiene el backend Quarkus en `Back/` y la aplicacion Flutter en `Front/`.

## Backend

Desde PowerShell, ejecuta las pruebas con `.\Back\mvnw.cmd test` y el servidor de desarrollo con `.\Back\mvnw.cmd quarkus:dev`.

El reconocimiento de imagen y la generación dinámica de recetas requieren `GEMINI_API_KEY` en el entorno del proceso backend. Sin esa variable, los endpoints correspondientes responden `503` y no realizan llamadas externas. Las preferencias alimentarias se guardan por cuenta. Las recetas que se muestran con filtros activos se validan conservadoramente usando sus ingredientes declarados; esto no garantiza ausencia de trazas ni contaminación cruzada.

El catálogo de recetas y la despensa usan PostgreSQL. Configura `DB_URL`, `DB_USERNAME` y `DB_PASSWORD` en el entorno del backend. El script `Back/database/scripts/04_create_recipes.sql` carga el catálogo inicial. El endpoint `GET /api/sugerencias/recetas?usuarioId=1` devuelve recetas según los ingredientes disponibles, junto con coincidencias, faltantes y porcentaje de cobertura.

## Frontend

Desde `Front/`, ejecuta `flutter pub get` y `flutter run --dart-define=API_BASE_URL=http://localhost:8080`. Para dispositivos fisicos, configura `API_BASE_URL` con la direccion del equipo que ejecuta Quarkus.

La vista de recomendaciones está en `Front/lib/recipe_recommendations_page.dart`; intégrala con `RecipeRecommendationsPage` y su función `loadRecommendations`.

El reconocimiento de imagen permite revisar, editar y guardar varios alimentos detectados antes de agregarlos al inventario. Desde la pantalla de inventario también puedes crear, renombrar y eliminar categorías; no es posible borrar una categoría que aún tenga alimentos asociados.

## Proyecto Quarkus

El backend usa Quarkus. Consulta <https://quarkus.io/> para las guias del framework.

## Running the application in dev mode

You can run your application in dev mode that enables live coding using:

```shell script
cd Back && ./mvnw quarkus:dev
```

> **_NOTE:_**  Quarkus now ships with a Dev UI, which is available in dev mode only at <http://localhost:8080/q/dev/>.

## Packaging and running the application

The application can be packaged using:

```shell script
cd Back && ./mvnw package
```

It produces the `quarkus-run.jar` file in the `target/quarkus-app/` directory.
Be aware that it’s not an _über-jar_ as the dependencies are copied into the `target/quarkus-app/lib/` directory.

The application is now runnable using `java -jar target/quarkus-app/quarkus-run.jar`.

If you want to build an _über-jar_, execute the following command:

```shell script
cd Back && ./mvnw package -Dquarkus.package.jar.type=uber-jar
```

The application, packaged as an _über-jar_, is now runnable using `java -jar target/*-runner.jar`.

## Creating a native executable

You can create a native executable using:

```shell script
cd Back && ./mvnw package -Dnative
```

Or, if you don't have GraalVM installed, you can run the native executable build in a container using:

```shell script
cd Back && ./mvnw package -Dnative -Dquarkus.native.container-build=true
```

You can then execute your native executable with: `./target/gestortecno-1.0.0-SNAPSHOT-runner`

If you want to learn more about building native executables, please consult <https://quarkus.io/guides/maven-tooling>.

## Related Guides

- REST ([guide](https://quarkus.io/guides/rest)): Build RESTful web services and APIs using Jakarta REST (formerly JAX-RS)

## Provided Code

### REST

Easily start your REST Web Services

[Related guide section...](https://quarkus.io/guides/getting-started-reactive#reactive-jax-rs-resources)
