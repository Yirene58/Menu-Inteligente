package edu.ucentral.vinni.service;

import jakarta.ws.rs.WebApplicationException;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class GeminiServiceTest {

    @Test
    void rechazaLaSolicitudCuandoFaltaLaClaveDeGemini() {
        var exception = assertThrows(
                WebApplicationException.class,
                () -> new GeminiService().analizarImagen("image-data")
        );

        assertEquals(503, exception.getResponse().getStatus());
    }

    @Test
    void parseaTodosLosAlimentosReconocidos() {
        var service = new GeminiService();
        var result = service.parsearRespuesta("""
                {"candidates":[{"content":{"parts":[{"text":"{\\"alimentos\\":[{\\"nombre\\":\\"Manzana\\",\\"categoriaNombre\\":\\"Frutas\\",\\"cantidad\\":2,\\"unidadMedida\\":\\"unidad\\"},{\\"nombre\\":\\"Leche\\",\\"categoriaNombre\\":\\"Lácteos\\",\\"cantidad\\":1,\\"unidadMedida\\":\\"litro\\"}]}"}]}}]}
                """);

        var foods = (java.util.List<?>) result.get("alimentos");
        assertEquals(2, foods.size());
        assertEquals("Manzana", ((java.util.Map<?, ?>) foods.get(0)).get("nombre"));
        assertEquals("Leche", ((java.util.Map<?, ?>) foods.get(1)).get("nombre"));
    }

    @Test
    void noDevuelveUnaListaDeRespaldoCuandoNoReconoceAlimentos() {
        var exception = assertThrows(
                WebApplicationException.class,
                () -> new GeminiService().parsearRespuesta("""
                        {"candidates":[{"content":{"parts":[{"text":"{\\"alimentos\\":[]}"}]}}]}
                        """)
        );

        assertEquals(502, exception.getResponse().getStatus());
    }
}