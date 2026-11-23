package edu.ucentral.vinni.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpTimeoutException;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@ApplicationScoped
public class ServicioGeneracionRecetas {

    private static final Logger LOG = Logger.getLogger(ServicioGeneracionRecetas.class);
    private static final String API_BASE = "https://generativelanguage.googleapis.com/v1beta/models/";
    private static final int MAX_RECIPES = 5;
    private static final int MAX_INGREDIENTS_PER_RECIPE = 30;
    private static final int MAX_STEPS_PER_RECIPE = 20;
    /** Reintentos ante errores transitorios de Gemini (500/503). Un 429 no se reintenta: gastaría más cupo. */
    private static final int MAX_INTENTOS = 2;
    /** Máximo de inventarios distintos guardados en caché. */
    private static final int MAX_CACHE = 200;

    @Inject
    GroqService groq;

    @ConfigProperty(name = "gemini.api.key", defaultValue = "")
    String apiKey;

    @ConfigProperty(name = "gemini.model", defaultValue = "gemini-3.8-flash")
    String model = "gemini-3.8-flash";

    @ConfigProperty(name = "gemini.vision.timeout-seconds", defaultValue = "90")
    int timeoutSeconds = 90;

    /** Minutos que se reutilizan las recetas de un mismo inventario y filtros sin volver a llamar a Gemini. */
    @ConfigProperty(name = "gemini.recetas.cache-minutes", defaultValue = "360")
    long cacheMinutes = 360;

    private final ObjectMapper mapper = new ObjectMapper();
    private final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();
    private final Map<String, CacheEntry> cache = new ConcurrentHashMap<>();

    /**
     * Genera recetas usando Groq como proveedor principal y Gemini como respaldo
     * cuando Groq falla (saturación, límite de uso, respuesta inválida, etc.).
     */
    public List<GeneratedRecipe> generar(List<PantryIngredient> pantry, List<FiltroAlimentario> filters) {
        boolean hayGroq = groq != null && groq.configurado();
        boolean hayGemini = apiKey != null && !apiKey.isBlank();
        if (!hayGroq && !hayGemini) {
            throw GeminiService.error(Response.Status.SERVICE_UNAVAILABLE,
                    "El servicio de recetas no está configurado (falta GROQ_API_KEY o GEMINI_API_KEY).");
        }
        String cacheKey = cacheKey(pantry, filters);
        CacheEntry cached = cache.get(cacheKey);
        if (cached != null && cached.expira().isAfter(Instant.now())) {
            return cached.recetas();
        }

        List<GeneratedRecipe> recetas = null;
        if (hayGroq) {
            try {
                recetas = parseRecipes(limpiarJson(groq.completarJson(buildPrompt(pantry, filters), 0.4)));
            } catch (WebApplicationException | IOException e) {
                if (!hayGemini) {
                    throw e instanceof WebApplicationException w ? w
                            : invalida("No fue posible procesar la respuesta del servicio de recetas.");
                }
                LOG.warnf("Groq falló al generar recetas (%s); usando Gemini.", e.getMessage());
            }
        }
        if (recetas == null) {
            recetas = llamarGemini(pantry, filters);
        }
        // No se guardan resultados vacíos para permitir reintentar.
        if (!recetas.isEmpty()) {
            guardarEnCache(cacheKey, recetas);
        }
        return recetas;
    }

    private List<GeneratedRecipe> llamarGemini(List<PantryIngredient> pantry, List<FiltroAlimentario> filters) {
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(API_BASE + model + ":generateContent"))
                    .timeout(Duration.ofSeconds(timeoutSeconds))
                    .header("Content-Type", "application/json")
                    .header("x-goog-api-key", apiKey)
                    .POST(HttpRequest.BodyPublishers.ofString(createPayload(pantry, filters)))
                    .build();
            HttpResponse<String> response = null;
            for (int intento = 1; intento <= MAX_INTENTOS; intento++) {
                response = client.send(request, HttpResponse.BodyHandlers.ofString());
                int status = response.statusCode();
                if (!(status == 500 || status == 503) || intento == MAX_INTENTOS) {
                    break;
                }
                LOG.warnf("Gemini respondió %d al generar recetas; reintentando.", status);
                Thread.sleep(2000L);
            }
            if (response.statusCode() != 200) {
                LOG.errorf("Gemini respondió %d al generar recetas: %s", response.statusCode(), response.body());
                throw GeminiService.error(Response.Status.BAD_GATEWAY, mensajeError(response.statusCode()));
            }
            JsonNode root = mapper.readTree(response.body());
            if (root == null || !root.isObject()) {
                throw invalida("El servicio de recetas devolvió una respuesta inválida.");
            }
            if (root.path("promptFeedback").has("blockReason")) {
                throw invalida("El servicio de recetas rechazó la solicitud. Revisa los ingredientes guardados.");
            }
            JsonNode candidates = root.path("candidates");
            if (!candidates.isArray() || candidates.isEmpty()) {
                throw invalida("El servicio de recetas devolvió una respuesta vacía.");
            }
            StringBuilder text = new StringBuilder();
            for (JsonNode part : candidates.get(0).path("content").path("parts")) {
                // Ignorar partes de razonamiento ("thought") y quedarse con la respuesta final.
                if (!part.path("thought").asBoolean(false) && part.path("text").isTextual()) {
                    text.append(part.path("text").asText());
                }
            }
            if (text.toString().isBlank()) {
                LOG.warnf("Gemini no devolvió texto al generar recetas: %s", response.body());
                throw invalida("El servicio de recetas devolvió una respuesta vacía. Intenta de nuevo.");
            }
            return parseRecipes(limpiarJson(text.toString()));
        } catch (HttpTimeoutException exception) {
            throw GeminiService.error(Response.Status.GATEWAY_TIMEOUT,
                    "El servicio de recetas tardó demasiado. Intenta de nuevo.");
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw invalida("La generación de recetas fue interrumpida.");
        } catch (IOException exception) {
            LOG.error("Error llamando a Gemini para generar recetas", exception);
            throw invalida("No fue posible procesar la respuesta del servicio de recetas.");
        }
    }

    String createPayload(List<PantryIngredient> pantry, List<FiltroAlimentario> filters) throws IOException {
        ObjectNode root = mapper.createObjectNode();
        ArrayNode contents = root.putArray("contents");
        ObjectNode content = contents.addObject();
        content.put("role", "user");
        ArrayNode parts = content.putArray("parts");
        parts.addObject().put("text", buildPrompt(pantry, filters));
        ObjectNode generationConfig = root.putObject("generationConfig");
        generationConfig.put("responseMimeType", "application/json");
        generationConfig.put("temperature", 0.4);
        // Menos "pensamiento" = respuesta más rápida y menos riesgo de superar el tiempo de espera.
        generationConfig.putObject("thinkingConfig").put("thinkingLevel", "low");
        return mapper.writeValueAsString(root);
    }

    /**
     * Interpreta la respuesta de la IA. Las recetas mal formadas se descartan individualmente;
     * solo se responde con error si ninguna receta es válida.
     */
    List<GeneratedRecipe> parseRecipes(String responseText) throws IOException {
        JsonNode root = mapper.readTree(responseText);
        if (root != null && root.isArray()) {
            root = mapper.createObjectNode().set("recetas", root);
        }
        if (root == null || !root.isObject() || !root.path("recetas").isArray()) {
            throw invalida("El servicio de recetas devolvió un formato inválido.");
        }
        JsonNode recipes = root.path("recetas");
        List<GeneratedRecipe> result = new ArrayList<>();
        for (JsonNode recipe : recipes) {
            if (result.size() == MAX_RECIPES) {
                break;
            }
            try {
                result.add(parseRecipe(recipe));
            } catch (WebApplicationException exception) {
                LOG.warnf("Receta descartada (%s): %s", exception.getMessage(), recipe);
            }
        }
        if (result.isEmpty() && !recipes.isEmpty()) {
            throw invalida("El servicio de recetas devolvió recetas incompletas. Intenta de nuevo.");
        }
        return List.copyOf(result);
    }

    private GeneratedRecipe parseRecipe(JsonNode recipe) {
        String name = requiredText(recipe, "nombre");
        String category = recipe.path("categoria").isTextual() && !recipe.path("categoria").asText().isBlank()
                ? recipe.path("categoria").asText().trim() : "Plato";
        int minutes = (int) Math.round(numero(recipe.path("minutos")));
        JsonNode ingredientsNode = recipe.path("ingredientes");
        JsonNode stepsNode = recipe.path("pasos");
        if (minutes < 1 || minutes > 1440
                || !ingredientsNode.isArray() || ingredientsNode.isEmpty()
                || ingredientsNode.size() > MAX_INGREDIENTS_PER_RECIPE
                || !stepsNode.isArray() || stepsNode.isEmpty()
                || stepsNode.size() > MAX_STEPS_PER_RECIPE) {
            throw invalida("El servicio de recetas devolvió una receta inválida.");
        }
        List<RecipeIngredient> ingredients = new ArrayList<>();
        for (JsonNode ingredient : ingredientsNode) {
            String ingredientName = requiredText(ingredient, "nombre");
            double quantity = numero(ingredient.path("cantidad"));
            String unit = ingredient.path("unidad").isTextual() && !ingredient.path("unidad").asText().isBlank()
                    ? ingredient.path("unidad").asText().trim() : "unidad";
            if (!(quantity > 0) || Double.isInfinite(quantity)) {
                // Cantidades como "al gusto": se toma una unidad para no descartar la receta.
                quantity = 1;
            }
            ingredients.add(new RecipeIngredient(ingredientName, quantity, unit));
        }
        List<String> steps = new ArrayList<>();
        for (JsonNode step : stepsNode) {
            if (!step.isTextual() || step.asText().isBlank()) {
                throw invalida("El servicio de recetas devolvió un paso inválido.");
            }
            steps.add(step.asText().trim());
        }
        return new GeneratedRecipe(name, category, minutes, List.copyOf(ingredients), List.copyOf(steps));
    }

    /** Acepta números o textos numéricos ("20", "1.5", "1,5"); devuelve NaN si no es un número. */
    private static double numero(JsonNode value) {
        if (value.isNumber()) {
            return value.asDouble();
        }
        if (value.isTextual()) {
            try {
                return Double.parseDouble(value.asText().trim().replace(',', '.').replaceAll("[^0-9.]", ""));
            } catch (NumberFormatException ignored) {
                return Double.NaN;
            }
        }
        return Double.NaN;
    }

    private String requiredText(JsonNode node, String field) {
        JsonNode value = node.path(field);
        if (!value.isTextual() || value.asText().isBlank()) {
            throw invalida("El servicio de recetas devolvió datos incompletos.");
        }
        return value.asText().trim();
    }

    private static String limpiarJson(String texto) {
        String t = texto.trim()
                .replaceFirst("^```(?:json)?\\s*", "")
                .replaceFirst("\\s*```$", "");
        int inicioObj = t.indexOf('{');
        int inicioArr = t.indexOf('[');
        int inicio = inicioObj < 0 ? inicioArr : (inicioArr < 0 ? inicioObj : Math.min(inicioObj, inicioArr));
        int fin = Math.max(t.lastIndexOf('}'), t.lastIndexOf(']'));
        return inicio >= 0 && fin > inicio ? t.substring(inicio, fin + 1) : t;
    }

    private String cacheKey(List<PantryIngredient> pantry, List<FiltroAlimentario> filters) {
        String inventario = pantry.stream()
                .map(i -> ValidadorFiltroAlimentario.normalize(i.nombre()) + ":" + i.cantidad() + ":" + i.unidad())
                .sorted()
                .reduce("", (a, b) -> a + "|" + b);
        String proveedor = groq != null && groq.configurado() ? groq.modeloTexto() : model;
        return proveedor + "#" + filters.stream().map(Enum::name).sorted().toList() + "#" + inventario;
    }

    private void guardarEnCache(String key, List<GeneratedRecipe> recetas) {
        Instant ahora = Instant.now();
        cache.values().removeIf(entry -> entry.expira().isBefore(ahora));
        if (cache.size() >= MAX_CACHE) {
            cache.entrySet().stream()
                    .min(Comparator.comparing(e -> e.getValue().expira()))
                    .ifPresent(e -> cache.remove(e.getKey()));
        }
        cache.put(key, new CacheEntry(recetas, ahora.plus(Duration.ofMinutes(cacheMinutes))));
    }

    private static String mensajeError(int status) {
        return switch (status) {
            case 400 -> "El servicio de recetas rechazó la solicitud.";
            case 401, 403 -> "La clave de Gemini no es válida o no tiene permisos.";
            case 404 -> "El modelo de Gemini configurado no existe (revise gemini.model).";
            case 429 -> "Se agotó el cupo del servicio de recetas. Intenta más tarde.";
            case 503 -> "El servicio de recetas está saturado en este momento. Intenta de nuevo en unos minutos.";
            default -> "El servicio de recetas no está disponible en este momento.";
        };
    }

    private static WebApplicationException invalida(String mensaje) {
        return GeminiService.error(Response.Status.BAD_GATEWAY, mensaje);
    }

    private String buildPrompt(List<PantryIngredient> pantry, List<FiltroAlimentario> filters) throws IOException {
        String inventory = mapper.writeValueAsString(pantry);
        String dietaryPreferences = filters.isEmpty()
                ? "No hay preferencias dietarias seleccionadas."
                : "Prioriza recetas que cumplan al menos uno de estos criterios: "
                        + filters.stream().map(Enum::name).toList() + ".";
        return """
                Propón hasta 5 recetas variadas que se puedan preparar principalmente con este inventario.
                Cada receta debe usar al menos un ingrediente del inventario, escrito exactamente con el
                mismo nombre que aparece en el inventario.
                Puedes incluir ingredientes faltantes comunes, pero lista todos los ingredientes necesarios
                con cantidades numéricas y unidades para que el sistema identifique cuáles faltan.
                Incluye entre 3 y 10 pasos breves, claros y ordenados para preparar cada receta.
                Cada paso debe describir una acción concreta y tener suficiente detalle para cocinarla.
                Usa nombres de ingredientes simples, explícitos y sin marcas; no uses categorías vagas
                como "condimentos" o "salsa".
                No afirmes certificaciones ni ausencia de trazas. Los criterios dietarios se validan aparte.
                Devuelve solamente JSON con esta forma exacta:
                {"recetas":[{"nombre":"...","categoria":"...","minutos":20,
                "ingredientes":[{"nombre":"tomate","cantidad":2,"unidad":"unidad"}],
                "pasos":["Lava y corta el tomate.","Cocina los ingredientes hasta que estén listos."]}]}
                Si no hay propuestas razonables, devuelve {"recetas":[]}.
                Preferencias: %s
                Inventario del usuario: %s
                """.formatted(dietaryPreferences, inventory);
    }

    private record CacheEntry(List<GeneratedRecipe> recetas, Instant expira) {}

    public record PantryIngredient(String nombre, Double cantidad, String unidad) {}
    public record RecipeIngredient(String nombre, double cantidad, String unidad) {}
    public record GeneratedRecipe(
            String nombre, String categoria, int minutos, List<RecipeIngredient> ingredientes, List<String> pasos) {
        public GeneratedRecipe {
            nombre = nombre.trim();
            categoria = categoria.trim();
            ingredientes = List.copyOf(ingredientes);
            pasos = List.copyOf(pasos);
        }
    }
}
