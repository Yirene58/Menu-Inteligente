package edu.ucentral.vinni.service;

import jakarta.ws.rs.WebApplicationException;
import org.junit.jupiter.api.Test;

import java.util.Base64;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class GeminiServiceTest {

    private static String respuesta(String textoEscapado) {
        return "{\"candidates\":[{\"content\":{\"parts\":[{\"text\":\"" + textoEscapado + "\"}]}}]}";
    }

    @Test
    void rechazaLaSolicitudCuandoFaltaLaClaveDeGemini() {
        var exception = assertThrows(
                WebApplicationException.class,
                () -> new GeminiService().analizarImagen("image-data")
        );

        assertEquals(503, exception.getResponse().getStatus());
        assertTrue(exception.getResponse().hasEntity(), "El error debe incluir un mensaje JSON");
    }

    @Test
    void parseaTodosLosAlimentosReconocidos() {
        var service = new GeminiService();
        var result = service.parsearRespuesta("""
                {"candidates":[{"content":{"parts":[{"text":"{\\"alimentos\\":[{\\"nombre\\":\\"Manzana\\",\\"categoriaNombre\\":\\"Frutas\\",\\"cantidad\\":2,\\"unidadMedida\\":\\"unidad\\",\\"confianza\\":0.9},{\\"nombre\\":\\"Leche\\",\\"categoriaNombre\\":\\"Lácteos\\",\\"cantidad\\":1,\\"unidadMedida\\":\\"litro\\",\\"confianza\\":0.4}]}"}]}}]}
                """);

        var foods = (List<?>) result.get("alimentos");
        assertEquals(2, foods.size());
        var manzana = (Map<?, ?>) foods.get(0);
        var leche = (Map<?, ?>) foods.get(1);
        assertEquals("Manzana", manzana.get("nombre"));
        assertEquals(false, manzana.get("incierto"));
        assertEquals("Leche", leche.get("nombre"));
        assertEquals(true, leche.get("incierto"));
    }

    @Test
    void normalizaCategoriasUnidadesYAgrupaDuplicados() {
        var result = new GeminiService().parsearRespuesta(respuesta(
                "{\\\"alimentos\\\":["
                        + "{\\\"nombre\\\":\\\"tomate\\\",\\\"categoriaNombre\\\":\\\"verduras\\\",\\\"cantidad\\\":2,\\\"unidadMedida\\\":\\\"unidades\\\"},"
                        + "{\\\"nombre\\\":\\\"Tomate\\\",\\\"categoriaNombre\\\":\\\"Verduras\\\",\\\"cantidad\\\":3,\\\"unidadMedida\\\":\\\"unidad\\\"},"
                        + "{\\\"nombre\\\":\\\"Pollo\\\",\\\"categoriaNombre\\\":\\\"Proteinas\\\",\\\"cantidad\\\":1,\\\"unidadMedida\\\":\\\"kilogramos\\\"}"
                        + "]}"));

        var foods = (List<?>) result.get("alimentos");
        assertEquals(2, foods.size());
        var tomate = (Map<?, ?>) foods.get(0);
        assertEquals("Tomate", tomate.get("nombre"));
        assertEquals(5.0, tomate.get("cantidad"));
        assertEquals("Verduras", tomate.get("categoriaNombre"));
        var pollo = (Map<?, ?>) foods.get(1);
        assertEquals("Proteínas", pollo.get("categoriaNombre"));
        assertEquals("kg", pollo.get("unidadMedida"));
    }

    @Test
    void ignoraPartesDeRazonamiento() {
        var result = new GeminiService().parsearRespuesta("""
                {"candidates":[{"content":{"parts":[
                  {"text":"Estoy pensando...","thought":true},
                  {"text":"```json\\n{\\"alimentos\\":[{\\"nombre\\":\\"Huevo\\",\\"categoriaNombre\\":\\"Proteínas\\",\\"cantidad\\":6,\\"unidadMedida\\":\\"unidad\\"}]}\\n```"}
                ]}}]}
                """);

        var foods = (List<?>) result.get("alimentos");
        assertEquals(1, foods.size());
        assertEquals("Huevo", ((Map<?, ?>) foods.get(0)).get("nombre"));
    }

    @Test
    void informaCuandoNoReconoceAlimentos() {
        var exception = assertThrows(
                WebApplicationException.class,
                () -> new GeminiService().parsearRespuesta("""
                        {"candidates":[{"content":{"parts":[{"text":"{\\"alimentos\\":[]}"}]}}]}
                        """)
        );

        assertEquals(422, exception.getResponse().getStatus());
    }

    @Test
    void decodificaDataUriYRechazaBase64Invalido() {
        var service = new GeminiService();
        String datos = Base64.getEncoder().encodeToString(new byte[500]);

        var imagen = service.decodificarImagen("data:image/png;base64," + datos);
        assertEquals("image/png", imagen.mimeType());
        assertEquals(datos, imagen.base64());

        var exception = assertThrows(WebApplicationException.class,
                () -> service.decodificarImagen("esto no es base64!!"));
        assertEquals(400, exception.getResponse().getStatus());
    }

    @Test
    void laPeticionPideJsonEstructurado() {
        var service = new GeminiService();
        var peticion = service.construirPeticion(new GeminiService.ImagenDecodificada("image/jpeg", "abc"));
        var config = peticion.path("generationConfig");
        assertEquals("application/json", config.path("responseMimeType").asText());
        assertFalse(config.path("responseSchema").isMissingNode());
    }
}
