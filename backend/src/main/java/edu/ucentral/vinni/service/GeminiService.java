package edu.ucentral.vinni.service;

import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Map;
import java.util.HashMap;

@ApplicationScoped
public class GeminiService {

    @ConfigProperty(name = "gemini.api.key")
    String apiKey;

    private final ObjectMapper mapper = new ObjectMapper();

    public Map<String, String> analizarImagen(String base64Image) {
        Map<String, String> resultado = new HashMap<>();
        try {
            String cleanBase64 = base64Image.contains(",") ? base64Image.split(",")[1] : base64Image;

            String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent?key=" + apiKey;

            // Prompt pidiendo "descripcion" detallada visual
            String promptText = "Analiza la imagen adjunta. Identifica el elemento principal y responde UNICAMENTE con un objeto JSON valido con estas tres claves exactas: " +
                    "\"objeto\" (nombre corto), " +
                    "\"categoria\" (ej: Mascota, Alimento, Vehiculo, Objeto personal, etc.), e " +
                    "\"descripcion\" (descripcion visual detallada del elemento en la foto, incluyendo colores, postura o detalles clave). No agregues formato Markdown ni bloques ```json.";

            ObjectNode rootNode = mapper.createObjectNode();
            ArrayNode contentsArray = rootNode.putArray("contents");
            ObjectNode contentObject = contentsArray.addObject();
            ArrayNode partsArray = contentObject.putArray("parts");

            partsArray.addObject().put("text", promptText);

            ObjectNode inlineDataNode = mapper.createObjectNode();
            inlineDataNode.put("mime_type", "image/jpeg");
            inlineDataNode.put("data", cleanBase64);
            
            partsArray.addObject().set("inline_data", inlineDataNode);

            String jsonPayload = mapper.writeValueAsString(rootNode);

            HttpClient client = HttpClient.newHttpClient();
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(jsonPayload))
                    .build();

            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() == 200) {
                JsonNode root = mapper.readTree(response.body());
                String responseText = root.path("candidates").get(0)
                        .path("content").path("parts").get(0)
                        .path("text").asText().trim();

                if (responseText.startsWith("```json")) {
                    responseText = responseText.replace("```json", "").replace("```", "").trim();
                } else if (responseText.startsWith("```")) {
                    responseText = responseText.replace("```", "").trim();
                }

                JsonNode parsedJson = mapper.readTree(responseText);

                // Mapeo con la nueva clave "descripcion"
                resultado.put("objeto", parsedJson.path("objeto").asText("Desconocido"));
                resultado.put("categoria", parsedJson.path("categoria").asText("General"));
                resultado.put("descripcion", parsedJson.path("descripcion").asText("Sin descripción disponible."));
                return resultado;
            } else {
                resultado.put("objeto", "Error de API");
                resultado.put("categoria", "Error");
                resultado.put("descripcion", "Gemini devolvio HTTP " + response.statusCode() + ": " + response.body());
                return resultado;
            }

        } catch (Exception e) {
            e.printStackTrace();
            resultado.put("objeto", "Error Interno");
            resultado.put("categoria", "Error");
            resultado.put("descripcion", "Excepcion en backend: " + e.getMessage());
            return resultado;
        }
    }
}