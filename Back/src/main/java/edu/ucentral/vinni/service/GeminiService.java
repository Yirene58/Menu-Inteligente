package edu.ucentral.vinni.service;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@ApplicationScoped
public class GeminiService {

    @ConfigProperty(name = "gemini.api.key", defaultValue = "")
    String apiKey;

    private final ObjectMapper mapper = new ObjectMapper();
    private final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    public Map<String, Object> analizarImagen(String base64Image) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new WebApplicationException("El servicio de reconocimiento no está configurado.",
                    Response.Status.SERVICE_UNAVAILABLE);
        }

        try {
            String[] imageParts = base64Image.split(",", 2);
            String cleanBase64 = imageParts.length == 2 ? imageParts[1] : imageParts[0];
            String mimeType = imageParts.length == 2 && imageParts[0].startsWith("data:")
                    ? imageParts[0].substring("data:".length(), imageParts[0].indexOf(';'))
                    : "image/jpeg";

            String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent";

            String promptText = "Identifica los alimentos visibles en la imagen. Devuelve únicamente JSON válido "
                    + "con la forma {\"alimentos\":[{\"nombre\":\"Manzana\","
                    + "\"categoriaNombre\":\"Frutas\",\"cantidad\":1,"
                    + "\"unidadMedida\":\"unidad\",\"descripcion\":\"\"}]}. "
                    + "Incluye cada alimento reconocible una sola vez; no inventes alimentos que no sean visibles. "
                    + "Usa categorías Frutas, Verduras, Proteínas, Lácteos, Cereales u Otros. "
                    + "Usa unidades kg, g, unidad, litro o ml. Sin Markdown.";

            ObjectNode rootNode = mapper.createObjectNode();
            ArrayNode contentsArray = rootNode.putArray("contents");
            ObjectNode contentObject = contentsArray.addObject();
            ArrayNode partsArray = contentObject.putArray("parts");

            partsArray.addObject().put("text", promptText);

            ObjectNode inlineDataNode = mapper.createObjectNode();
            inlineDataNode.put("mime_type", mimeType);
            inlineDataNode.put("data", cleanBase64.trim());

            partsArray.addObject().set("inline_data", inlineDataNode);

            String jsonPayload = mapper.writeValueAsString(rootNode);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(Duration.ofSeconds(30))
                    .header("Content-Type", "application/json")
                    .header("x-goog-api-key", apiKey)
                    .POST(HttpRequest.BodyPublishers.ofString(jsonPayload))
                    .build();

            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                throw new WebApplicationException("El servicio de reconocimiento no está disponible.",
                        Response.Status.BAD_GATEWAY);
            }
            return parsearRespuesta(response.body());

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new WebApplicationException("El servicio de reconocimiento no respondió a tiempo.",
                    Response.Status.BAD_GATEWAY);
        } catch (WebApplicationException e) {
            throw e;
        } catch (Exception e) {
            throw new WebApplicationException("No fue posible procesar la imagen.", Response.Status.BAD_GATEWAY);
        }
    }

    Map<String, Object> parsearRespuesta(String responseBody) {
        try {
            JsonNode root = mapper.readTree(responseBody);
            JsonNode parts = root.path("candidates").path(0).path("content").path("parts");
            if (!parts.isArray() || parts.isEmpty() || !parts.get(0).path("text").isTextual()) {
                throw new IllegalArgumentException("La respuesta no contiene alimentos reconocidos.");
            }

            String responseText = parts.get(0).path("text").asText().trim()
                    .replaceFirst("^```(?:json)?\\s*", "")
                    .replaceFirst("\\s*```$", "");
            JsonNode parsed = mapper.readTree(responseText);
            JsonNode detectedFoods = parsed.path("alimentos");
            if (!detectedFoods.isArray() && parsed.isObject() && parsed.has("objeto")) {
                detectedFoods = mapper.createArrayNode().add(parsed);
            }
            if (!detectedFoods.isArray() || detectedFoods.isEmpty()) {
                throw new IllegalArgumentException("No se reconocieron alimentos en la imagen.");
            }

            List<Map<String, Object>> foods = new ArrayList<>();
            for (JsonNode detectedFood : detectedFoods) {
                String name = detectedFood.path("nombre").asText(
                        detectedFood.path("objeto").asText("")).trim();
                if (name.isEmpty()) {
                    continue;
                }

                Map<String, Object> food = new LinkedHashMap<>();
                food.put("nombre", name);
                food.put("categoriaNombre", detectedFood.path("categoriaNombre")
                        .asText(detectedFood.path("categoria").asText("Otros")));
                food.put("cantidad", detectedFood.path("cantidad").asDouble(1));
                food.put("unidadMedida", detectedFood.path("unidadMedida").asText("unidad"));
                food.put("descripcion", detectedFood.path("descripcion").asText(""));
                foods.add(food);
            }
            if (foods.isEmpty()) {
                throw new IllegalArgumentException("No se reconocieron alimentos válidos en la imagen.");
            }
            return Map.of("alimentos", foods);
        } catch (Exception e) {
            if (e instanceof WebApplicationException webApplicationException) {
                throw webApplicationException;
            }
            throw new WebApplicationException("No fue posible procesar la respuesta del reconocimiento.",
                    Response.Status.BAD_GATEWAY);
        }
    }
}