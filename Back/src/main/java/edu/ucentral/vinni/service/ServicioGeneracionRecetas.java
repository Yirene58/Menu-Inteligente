package edu.ucentral.vinni.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

@ApplicationScoped
public class ServicioGeneracionRecetas {

    private static final String API_URL =
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent";
    private static final int MAX_RECIPES = 5;
    private static final int MAX_INGREDIENTS_PER_RECIPE = 30;

    @ConfigProperty(name = "gemini.api.key", defaultValue = "")
    String apiKey;

    private final ObjectMapper mapper = new ObjectMapper();
    private final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    public List<GeneratedRecipe> generar(List<PantryIngredient> pantry, List<FiltroAlimentario> filters) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new WebApplicationException("El servicio de recetas no está configurado.",
                    Response.Status.SERVICE_UNAVAILABLE);
        }
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(API_URL))
                    .timeout(Duration.ofSeconds(35))
                    .header("Content-Type", "application/json")
                    .header("x-goog-api-key", apiKey)
                    .POST(HttpRequest.BodyPublishers.ofString(createPayload(pantry, filters)))
                    .build();
            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) {
                throw new WebApplicationException("El servicio de recetas no está disponible.",
                        Response.Status.BAD_GATEWAY);
            }
            JsonNode root = mapper.readTree(response.body());
            if (root == null || !root.isObject()) {
                throw new WebApplicationException("El servicio de recetas devolvió una respuesta inválida.",
                        Response.Status.BAD_GATEWAY);
            }
            JsonNode candidates = root.path("candidates");
            if (!candidates.isArray() || candidates.isEmpty()) {
                throw new WebApplicationException("El servicio de recetas devolvió una respuesta vacía.",
                        Response.Status.BAD_GATEWAY);
            }
            JsonNode textNode = candidates.get(0).path("content").path("parts").path(0).path("text");
            if (!textNode.isTextual() || textNode.asText().isBlank()) {
                throw new WebApplicationException("El servicio de recetas devolvió una respuesta vacía.",
                        Response.Status.BAD_GATEWAY);
            }
            String text = textNode.asText();
            return parseRecipes(text);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new WebApplicationException("La generación de recetas fue interrumpida.",
                    Response.Status.BAD_GATEWAY);
        } catch (IOException exception) {
            throw new WebApplicationException("No fue posible procesar la respuesta del servicio de recetas.",
                    Response.Status.BAD_GATEWAY);
        }
    }

    String createPayload(List<PantryIngredient> pantry, List<FiltroAlimentario> filters) throws IOException {
        ObjectNode root = mapper.createObjectNode();
        ArrayNode contents = root.putArray("contents");
        ObjectNode content = contents.addObject();
        ArrayNode parts = content.putArray("parts");
        parts.addObject().put("text", buildPrompt(pantry, filters));
        ObjectNode generationConfig = root.putObject("generationConfig");
        generationConfig.put("responseMimeType", "application/json");
        generationConfig.put("temperature", 0.4);
        return mapper.writeValueAsString(root);
    }

    List<GeneratedRecipe> parseRecipes(String responseText) throws IOException {
        JsonNode root = mapper.readTree(responseText);
        if (root == null || !root.isObject() || !root.path("recetas").isArray()) {
            throw new WebApplicationException("El servicio de recetas devolvió un formato inválido.",
                    Response.Status.BAD_GATEWAY);
        }
        JsonNode recipes = root.path("recetas");
        List<GeneratedRecipe> result = new ArrayList<>();
        for (JsonNode recipe : recipes) {
            if (result.size() == MAX_RECIPES) {
                break;
            }
            result.add(parseRecipe(recipe));
        }
        return List.copyOf(result);
    }

    private GeneratedRecipe parseRecipe(JsonNode recipe) {
        String name = requiredText(recipe, "nombre");
        String category = requiredText(recipe, "categoria");
        JsonNode minutes = recipe.path("minutos");
        JsonNode ingredientsNode = recipe.path("ingredientes");
        if (!minutes.canConvertToInt() || minutes.asInt() < 1 || minutes.asInt() > 1440
                || !ingredientsNode.isArray() || ingredientsNode.isEmpty()
                || ingredientsNode.size() > MAX_INGREDIENTS_PER_RECIPE) {
            throw new WebApplicationException("El servicio de recetas devolvió una receta inválida.",
                    Response.Status.BAD_GATEWAY);
        }
        List<RecipeIngredient> ingredients = new ArrayList<>();
        for (JsonNode ingredient : ingredientsNode) {
            String ingredientName = requiredText(ingredient, "nombre");
            JsonNode quantity = ingredient.path("cantidad");
            String unit = requiredText(ingredient, "unidad");
            if (!quantity.isNumber() || quantity.asDouble() <= 0) {
                throw new WebApplicationException("El servicio de recetas devolvió un ingrediente inválido.",
                        Response.Status.BAD_GATEWAY);
            }
            ingredients.add(new RecipeIngredient(ingredientName, quantity.asDouble(), unit));
        }
        return new GeneratedRecipe(name, category, minutes.asInt(), List.copyOf(ingredients));
    }

    private String requiredText(JsonNode node, String field) {
        JsonNode value = node.path(field);
        if (!value.isTextual() || value.asText().isBlank()) {
            throw new WebApplicationException("El servicio de recetas devolvió datos incompletos.",
                    Response.Status.BAD_GATEWAY);
        }
        return value.asText().trim();
    }

    private String buildPrompt(List<PantryIngredient> pantry, List<FiltroAlimentario> filters) throws IOException {
        String inventory = mapper.writeValueAsString(pantry);
        String dietaryPreferences = filters.isEmpty()
                ? "No hay preferencias dietarias seleccionadas."
                : "Prioriza recetas que cumplan al menos uno de estos criterios: "
                        + filters.stream().map(Enum::name).toList() + ".";
        return """
                Propón hasta 5 recetas variadas que se puedan preparar principalmente con este inventario.
                Puedes incluir ingredientes faltantes comunes, pero lista todos los ingredientes necesarios
                con cantidades y unidades para que el sistema identifique cuáles faltan.
                Usa nombres de ingredientes simples, explícitos y sin marcas; no uses categorías vagas
                como "condimentos" o "salsa".
                No afirmes certificaciones ni ausencia de trazas. Los criterios dietarios se validan aparte.
                Devuelve solamente JSON con esta forma exacta:
                {"recetas":[{"nombre":"...","categoria":"...","minutos":20,
                "ingredientes":[{"nombre":"tomate","cantidad":2,"unidad":"unidad"}]}]}
                Si no hay propuestas razonables, devuelve {"recetas":[]}.
                Preferencias: %s
                Inventario del usuario: %s
                """.formatted(dietaryPreferences, inventory);
    }

    public record PantryIngredient(String nombre, Double cantidad, String unidad) {}
    public record RecipeIngredient(String nombre, double cantidad, String unidad) {}
    public record GeneratedRecipe(String nombre, String categoria, int minutos, List<RecipeIngredient> ingredientes) {
        public GeneratedRecipe {
            nombre = nombre.trim();
            categoria = categoria.trim();
            ingredientes = List.copyOf(ingredientes);
        }
    }
}
