package edu.ucentral.vinni.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpTimeoutException;
import java.time.Duration;

/**
 * Cliente de Groq (API compatible con OpenAI). Es el proveedor principal de IA;
 * si falla, los servicios usan Gemini como respaldo.
 */
@ApplicationScoped
public class GroqService {

    private static final Logger LOG = Logger.getLogger(GroqService.class);
    private static final String API_URL = "https://api.groq.com/openai/v1/chat/completions";
    /** Groq limita las imágenes enviadas en Base64 a 4 MB por petición. */
    private static final int MAX_BASE64_IMAGEN = 4 * 1024 * 1024;

    @ConfigProperty(name = "groq.api.key", defaultValue = "")
    String apiKey;

    @ConfigProperty(name = "groq.model.texto", defaultValue = "openai/gpt-oss-120b")
    String modeloTexto = "openai/gpt-oss-120b";

    @ConfigProperty(name = "groq.model.vision", defaultValue = "qwen/qwen3.8-27b")
    String modeloVision = "qwen/qwen3.8-27b";

    @ConfigProperty(name = "groq.timeout-seconds", defaultValue = "25")
    int timeoutSeconds = 25;

    private final ObjectMapper mapper = new ObjectMapper();
    private final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    public boolean configurado() {
        return apiKey != null && !apiKey.isBlank();
    }

    public String modeloTexto() {
        return modeloTexto;
    }

    /** Envía un prompt de texto y devuelve el JSON generado por el modelo. */
    public String completarJson(String prompt, double temperatura) {
        ObjectNode root = cuerpoBase(modeloTexto, temperatura, 3000);
        root.putArray("messages").addObject().put("role", "user").put("content", prompt);
        return enviar(root);
    }

    /** Envía un prompt junto con una imagen (Base64 sin prefijo) y devuelve el JSON generado. */
    public String analizarImagenJson(String prompt, String mimeType, String base64) {
        if (base64.length() > MAX_BASE64_IMAGEN) {
            throw GeminiService.error(Response.Status.REQUEST_ENTITY_TOO_LARGE,
                    "La imagen es demasiado grande para el servicio de reconocimiento.");
        }
        ObjectNode root = cuerpoBase(modeloVision, 0.2, 1500);
        ArrayNode content = root.putArray("messages").addObject().put("role", "user").putArray("content");
        content.addObject().put("type", "text").put("text", prompt);
        content.addObject().put("type", "image_url").putObject("image_url")
                .put("url", "data:" + mimeType + ";base64," + base64);
        return enviar(root);
    }

    private ObjectNode cuerpoBase(String modelo, double temperatura, int maxTokens) {
        ObjectNode root = mapper.createObjectNode();
        root.put("model", modelo);
        root.put("temperature", temperatura);
        root.put("max_completion_tokens", maxTokens);
        root.putObject("response_format").put("type", "json_object");
        if (modelo.startsWith("openai/gpt-oss")) {
            // Menos razonamiento = respuesta más rápida; suficiente para recetas.
            root.put("reasoning_effort", "low");
        }
        return root;
    }

    private String enviar(ObjectNode cuerpo) {
        if (!configurado()) {
            throw GeminiService.error(Response.Status.SERVICE_UNAVAILABLE, "Falta GROQ_API_KEY.");
        }
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(API_URL))
                    .timeout(Duration.ofSeconds(timeoutSeconds))
                    .header("Content-Type", "application/json")
                    .header("Authorization", "Bearer " + apiKey)
                    .POST(HttpRequest.BodyPublishers.ofString(mapper.writeValueAsString(cuerpo)))
                    .build();
            HttpResponse<String> response = null;
            for (int intento = 1; intento <= 2; intento++) {
                response = client.send(request, HttpResponse.BodyHandlers.ofString());
                long espera = esperaReintento(response);
                if (response.statusCode() == 200 || espera < 0 || intento == 2) {
                    break;
                }
                LOG.warnf("Groq respondió %d; reintentando en %d ms.", response.statusCode(), espera);
                Thread.sleep(espera);
            }
            if (response.statusCode() != 200) {
                LOG.errorf("Groq respondió %d: %s", response.statusCode(), response.body());
                throw GeminiService.error(Response.Status.BAD_GATEWAY, mensajeError(response.statusCode()));
            }
            JsonNode root = mapper.readTree(response.body());
            String texto = root.path("choices").path(0).path("message").path("content").asText("");
            // Algunos modelos incluyen su razonamiento entre etiquetas <think>.
            texto = texto.replaceAll("(?s)<think>.*?</think>", "").trim();
            if (texto.isEmpty()) {
                LOG.warnf("Groq no devolvió texto: %s", response.body());
                throw GeminiService.error(Response.Status.BAD_GATEWAY, "El servicio de IA no devolvió resultados.");
            }
            return texto;
        } catch (HttpTimeoutException e) {
            throw GeminiService.error(Response.Status.GATEWAY_TIMEOUT, "El servicio de IA tardó demasiado.");
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw GeminiService.error(Response.Status.BAD_GATEWAY, "La solicitud al servicio de IA fue interrumpida.");
        } catch (WebApplicationException e) {
            throw e;
        } catch (Exception e) {
            LOG.error("Error llamando a Groq", e);
            throw GeminiService.error(Response.Status.BAD_GATEWAY, "No fue posible comunicarse con el servicio de IA.");
        }
    }

    /**
     * Milisegundos a esperar antes de reintentar, o -1 si no conviene reintentar.
     * Se reintenta ante saturación (500/503) o un límite por minuto que se libera en pocos segundos.
     */
    private static long esperaReintento(HttpResponse<String> response) {
        int status = response.statusCode();
        if (status == 500 || status == 503) {
            return 1500;
        }
        if (status == 429) {
            double segundos = response.headers().firstValue("retry-after")
                    .map(v -> {
                        try {
                            return Double.parseDouble(v.trim());
                        } catch (NumberFormatException e) {
                            return -1.0;
                        }
                    })
                    .orElse(-1.0);
            return segundos >= 0 && segundos <= 6 ? (long) (segundos * 1000) + 250 : -1;
        }
        return -1;
    }

    private static String mensajeError(int status) {
        return switch (status) {
            case 400 -> "El servicio de IA rechazó la solicitud.";
            case 401, 403 -> "La clave de Groq no es válida o no tiene permisos.";
            case 404 -> "El modelo de Groq configurado no existe.";
            case 413 -> "La imagen es demasiado grande para el servicio de IA.";
            case 429 -> "Se superó el límite de uso del servicio de IA. Intenta en unos minutos.";
            case 503 -> "El servicio de IA está saturado en este momento. Intenta de nuevo en unos minutos.";
            default -> "El servicio de IA no está disponible en este momento.";
        };
    }
}
