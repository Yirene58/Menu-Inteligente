# GestorTecno — HU4

Recomendaciones de recetas basadas en los ingredientes disponibles del usuario.

## Estructura

- `front/`: vista Flutter de recomendaciones.
- `back/`: API Quarkus, configuración, pruebas y scripts SQL.

## Backend

Desde `back/`, inicia Quarkus en modo desarrollo con `./mvnw quarkus:dev` (Windows: `mvnw.cmd quarkus:dev`).

Configura `DB_URL`, `DB_USERNAME` y `DB_PASSWORD` para conectar PostgreSQL. El script `back/database/scripts/04_create_recipes.sql` crea y carga el catálogo de recetas.

`GET /api/sugerencias/recetas?usuarioId=1` devuelve recetas con ingredientes disponibles, coincidencias, faltantes y porcentaje de cobertura.

## Frontend

Importa `front/lib/recipe_recommendations_page.dart` y conecta `RecipeRecommendationsPage` con la función `loadRecommendations` de la aplicación.
