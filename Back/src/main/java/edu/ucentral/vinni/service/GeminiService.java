package edu.ucentral.vinni.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpTimeoutException;
import java.text.Normalizer;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * Reconocimiento de alimentos en imágenes usando la API de Gemini.
 * Devuelve {"alimentos":[{nombre, categoriaNombre, cantidad, unidadMedida, descripcion, confianza}]}.
 */
@ApplicationScoped
public class GeminiService {

    private static final Logger LOG = Logger.getLogger(GeminiService.class);

    public static final List<String> CATEGORIAS = List.of(
            "Frutas", "Verduras", "Proteínas", "Lácteos", "Cereales", "Otros");
    public static final List<String> UNIDADES = List.of("unidad", "kg", "g", "litro", "ml");
    private static final Set<String> MIME_PERMITIDOS = Set.of(
            "image/jpeg", "image/png", "image/webp", "image/heic", "image/heif");
    /** Por debajo de este valor la detección se marca como "incierta" (HU02 de la wiki). */
    public static final double UMBRAL_CONFIANZA = 0.6;

    private static final String PROMPT = """
            Eres un asistente de inventario de cocina. Analiza la fotografía (nevera, despensa, \
            mesa o compra del supermercado) e identifica TODOS los alimentos o productos comestibles \
            visibles, incluidos los empacados (lee etiquetas y marcas para saber qué son).

            Reglas:
            - Usa nombres genéricos en español y en singular, con mayúscula inicial (ej. "Tomate", "Leche", "Arroz").
            - Agrupa los elementos iguales en una sola entrada y cuenta cuántos hay.
            - cantidad: número estimado. Para piezas sueltas o envases usa la unidad "unidad"; \
            si la etiqueta muestra peso o volumen puedes usar kg, g, litro o ml.
            - categoriaNombre debe ser exactamente una de: Frutas, Verduras, Proteínas, Lácteos, Cereales, Otros.
              (carnes, pescado, huevos y legumbres = Proteínas; pan, pasta, arroz, avena = Cereales).
            - unidadMedida debe ser exactamente una de: unidad, kg, g, litro, ml.
            - descripcion: detalle breve útil (variedad, marca, estado), o cadena vacía.
            - confianza: número entre 0 y 1 que indica qué tan seguro estás de la identificación.
            - No incluyas objetos que no sean comida (platos, utensilios, electrodomésticos, personas).
            - No inventes alimentos que no se vean. Si no hay alimentos devuelve {"alimentos":[]}.
            Responde únicamente con JSON.
            """;

    @ConfigProperty(name = "gemini.api.key", defaultValue = "")
    String apiKey;

    @ConfigProperty(name = "gemini.model", defaultValue = "gemini-3.8-flash")
    String model = "gemini-3.8-flash";

    @ConfigProperty(name = "gemini.vision.timeout-seconds", defaultValue = "90")
    int timeoutSeconds = 90;

    private final ObjectMapper mapper = new ObjectMapper();
    private final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    public Map<String, Object> analizarImagen(String base64Image) {
        if (apiKey == null || apiKey.isBlank()) {
            throw error(Response.Status.SERVICE_UNAVAILABLE,
                    "El servicio de reconocimiento no está configurado (falta GEMINI_API_KEY).");
        }

        ImagenDecodificada imagen = decodificarImagen(base64Image);

        try {
            String jsonPayload = mapper.writeValueAsString(construirPeticion(imagen));
            String url = "https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent";

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(Duration.ofSeconds(timeoutSeconds))
                    .header("Content-Type", "application/json")
                    .header("x-goog-api-key", apiKey)
                    .POST(HttpRequest.BodyPublishers.ofString(jsonPayload))
                    .build();

            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                LOG.errorf("Gemini respondió %d: %s", response.statusCode(), response.body());
                throw error(Response.Status.BAD_GATEWAY, mensajeErrorGemini(response.statusCode()));
            }
            return parsearRespuesta(response.body());

        } catch (HttpTimeoutException e) {
            throw error(Response.Status.GATEWAY_TIMEOUT,
                    "El servicio de reconocimiento tardó demasiado. Intenta de nuevo.");
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw error(Response.Status.BAD_GATEWAY, "El servicio de reconocimiento fue interrumpido.");
        } catch (WebApplicationException e) {
            throw e;
        } catch (Exception e) {
            LOG.error("Error llamando a Gemini", e);
            throw error(Response.Status.BAD_GATEWAY, "No fue posible procesar la imagen.");
        }
    }

    ObjectNode construirPeticion(ImagenDecodificada imagen) {
        ObjectNode root = mapper.createObjectNode();
        ArrayNode parts = root.putArray("contents").addObject().put("role", "user").putArray("parts");
        // La imagen va antes del texto: Google recomienda este orden para mejores resultados.
        ObjectNode inline = parts.addObject().putObject("inline_data");
        inline.put("mime_type", imagen.mimeType());
        inline.put("data", imagen.base64());
        parts.addObject().put("text", PROMPT);

        ObjectNode generationConfig = root.putObject("generationConfig");
        generationConfig.put("responseMimeType", "application/json");
        generationConfig.set("responseSchema", esquemaRespuesta());
        // Menos "pensamiento" = respuesta más rápida; suficiente para identificar alimentos.
        generationConfig.putObject("thinkingConfig").put("thinkingLevel", "low");
        return root;
    }

    private ObjectNode esquemaRespuesta() {
        ObjectNode alimento = mapper.createObjectNode();
        alimento.put("type", "OBJECT");
        ObjectNode props = alimento.putObject("properties");
        props.putObject("nombre").put("type", "STRING");
        ObjectNode categoria = props.putObject("categoriaNombre").put("type", "STRING");
        CATEGORIAS.forEach(categoria.putArray("enum")::add);
        props.putObject("cantidad").put("type", "NUMBER");
        ObjectNode unidad = props.putObject("unidadMedida").put("type", "STRING");
        UNIDADES.forEach(unidad.putArray("enum")::add);
        props.putObject("descripcion").put("type", "STRING");
        props.putObject("confianza").put("type", "NUMBER");
        ArrayNode required = alimento.putArray("required");
        List.of("nombre", "categoriaNombre", "cantidad", "unidadMedida", "confianza").forEach(required::add);

        ObjectNode schema = mapper.createObjectNode();
        schema.put("type", "OBJECT");
        ObjectNode lista = schema.putObject("properties").putObject("alimentos");
        lista.put("type", "ARRAY");
        lista.set("items", alimento);
        schema.putArray("required").add("alimentos");
        return schema;
    }

    ImagenDecodificada decodificarImagen(String base64Image) {
        String valor = base64Image.trim();
        String mimeType = "image/jpeg";
        if (valor.startsWith("data:")) {
            int coma = valor.indexOf(',');
            int puntoComa = valor.indexOf(';');
            if (coma < 0) {
                throw error(Response.Status.BAD_REQUEST, "La imagen enviada no es válida.");
            }
            if (puntoComa > 5 && puntoComa < coma) {
                mimeType = valor.substring(5, puntoComa).toLowerCase(Locale.ROOT);
            }
            valor = valor.substring(coma + 1);
        }
        valor = valor.replaceAll("\\s", "");
        if (!MIME_PERMITIDOS.contains(mimeType)) {
            throw error(Response.Status.BAD_REQUEST, "Formato de imagen no soportado: " + mimeType);
        }
        try {
            byte[] bytes = Base64.getDecoder().decode(valor);
            if (bytes.length < 100) {
                throw error(Response.Status.BAD_REQUEST, "La imagen enviada está vacía o dañada.");
            }
        } catch (IllegalArgumentException e) {
            throw error(Response.Status.BAD_REQUEST, "La imagen no está codificada correctamente en Base64.");
        }
        return new ImagenDecodificada(mimeType, valor);
    }

    Map<String, Object> parsearRespuesta(String responseBody) {
        JsonNode root;
        try {
            root = mapper.readTree(responseBody);
        } catch (Exception e) {
            throw error(Response.Status.BAD_GATEWAY, "No fue posible procesar la respuesta del reconocimiento.");
        }

        if (root.path("promptFeedback").has("blockReason")) {
            throw error(Response.Status.UNPROCESSABLE_ENTITY,
                    "La imagen fue rechazada por el servicio de reconocimiento. Prueba con otra foto.");
        }

        JsonNode candidate = root.path("candidates").path(0);
        StringBuilder texto = new StringBuilder();
        for (JsonNode part : candidate.path("content").path("parts")) {
            // Ignorar partes de razonamiento ("thought") y quedarse con la respuesta final.
            if (part.path("thought").asBoolean(false)) {
                continue;
            }
            if (part.path("text").isTextual()) {
                texto.append(part.path("text").asText());
            }
        }
        if (texto.isEmpty()) {
            String finishReason = candidate.path("finishReason").asText("");
            LOG.warnf("Gemini no devolvió texto. finishReason=%s cuerpo=%s", finishReason, responseBody);
            throw error(Response.Status.BAD_GATEWAY,
                    "El servicio de reconocimiento no devolvió resultados. Intenta de nuevo.");
        }

        JsonNode detectados;
        try {
            JsonNode parsed = mapper.readTree(limpiarJson(texto.toString()));
            detectados = parsed.isArray() ? parsed : parsed.path("alimentos");
            if (!detectados.isArray() && parsed.isObject() && (parsed.has("objeto") || parsed.has("nombre"))) {
                detectados = mapper.createArrayNode().add(parsed);
            }
        } catch (Exception e) {
            LOG.warnf("Respuesta de Gemini no es JSON válido: %s", texto);
            throw error(Response.Status.BAD_GATEWAY, "No fue posible interpretar la respuesta del reconocimiento.");
        }

        Map<String, Map<String, Object>> porNombre = new LinkedHashMap<>();
        if (detectados.isArray()) {
            for (JsonNode d : detectados) {
                String nombre = capitalizar(d.path("nombre").asText(d.path("objeto").asText("")).trim());
                if (nombre.isEmpty()) {
                    continue;
                }
                String unidad = normalizarUnidad(d.path("unidadMedida").asText(d.path("unidad").asText("unidad")));
                double cantidad = d.path("cantidad").asDouble(1);
                if (!(cantidad > 0) || Double.isInfinite(cantidad)) {
                    cantidad = 1;
                }
                double confianza = Math.max(0, Math.min(1, d.path("confianza").asDouble(1)));

                String clave = normalizarTexto(nombre) + "|" + unidad;
                Map<String, Object> existente = porNombre.get(clave);
                if (existente != null) {
                    existente.put("cantidad", (Double) existente.get("cantidad") + cantidad);
                    existente.put("confianza", Math.min((Double) existente.get("confianza"), confianza));
                    continue;
                }

                Map<String, Object> food = new LinkedHashMap<>();
                food.put("nombre", nombre);
                food.put("categoriaNombre", normalizarCategoria(
                        d.path("categoriaNombre").asText(d.path("categoria").asText("Otros"))));
                food.put("cantidad", cantidad);
                food.put("unidadMedida", unidad);
                food.put("descripcion", d.path("descripcion").asText("").trim());
                food.put("confianza", confianza);
                porNombre.put(clave, food);
            }
        }

        List<Map<String, Object>> foods = new ArrayList<>(porNombre.values());
        for (Map<String, Object> food : foods) {
            food.put("incierto", (Double) food.get("confianza") < UMBRAL_CONFIANZA);
        }
        if (foods.isEmpty()) {
            throw error(Response.Status.UNPROCESSABLE_ENTITY,
                    "No se reconocieron alimentos en la imagen. Intenta con una foto más cercana y con buena luz.");
        }
        return Map.of("alimentos", foods);
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

    static String normalizarTexto(String valor) {
        return Normalizer.normalize(valor == null ? "" : valor, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .trim()
                .toLowerCase(Locale.ROOT);
    }

    static String normalizarCategoria(String valor) {
        String n = normalizarTexto(valor);
        for (String categoria : CATEGORIAS) {
            if (normalizarTexto(categoria).equals(n)) {
                return categoria;
            }
        }
        if (n.startsWith("fruta")) return "Frutas";
        if (n.startsWith("verdura") || n.startsWith("hortaliza") || n.startsWith("vegetal")) return "Verduras";
        if (n.startsWith("proteina") || n.startsWith("carne") || n.contains("huevo")
                || n.contains("pescado") || n.contains("legumbre")) return "Proteínas";
        if (n.startsWith("lacteo") || n.contains("queso") || n.contains("leche")) return "Lácteos";
        if (n.startsWith("cereal") || n.contains("grano") || n.contains("pan") || n.contains("pasta")) return "Cereales";
        return "Otros";
    }

    static String normalizarUnidad(String valor) {
        String n = normalizarTexto(valor);
        return switch (n) {
            case "kg", "kilo", "kilos", "kilogramo", "kilogramos" -> "kg";
            case "g", "gr", "grs", "gramo", "gramos" -> "g";
            case "l", "lt", "lts", "litro", "litros" -> "litro";
            case "ml", "mililitro", "mililitros" -> "ml";
            default -> "unidad";
        };
    }

    private static String capitalizar(String valor) {
        if (valor.isEmpty()) return valor;
        return valor.substring(0, 1).toUpperCase(Locale.ROOT) + valor.substring(1);
    }

    private static String mensajeErrorGemini(int status) {
        return switch (status) {
            case 400 -> "El servicio de reconocimiento rechazó la imagen. Prueba con otra foto.";
            case 401, 403 -> "La clave de Gemini no es válida o no tiene permisos.";
            case 404 -> "El modelo de Gemini configurado no existe (revise gemini.model).";
            case 429 -> "Se superó el límite de uso del servicio de reconocimiento. Intenta en unos minutos.";
            default -> "El servicio de reconocimiento no está disponible en este momento.";
        };
    }

    /** Excepción con cuerpo JSON {"error": "..."} para que el frontend muestre el mensaje real. */
    static WebApplicationException error(Response.Status status, String mensaje) {
        return new WebApplicationException(mensaje, Response.status(status)
                .type(MediaType.APPLICATION_JSON)
                .entity(Map.of("error", mensaje))
                .build());
    }

    record ImagenDecodificada(String mimeType, String base64) {
    }
}
