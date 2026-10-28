package edu.ucentral.vinni.service;

import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@QuarkusTest
public class GeminiServiceTest {

    @Inject
    GeminiService geminiService;

    @Test
    @DisplayName("Devuelve lista estructurada de alimentos al analizar imagen base64")
    public void testAnalizarImagenEstructuraValida() {
        // Imagen Base64 de prueba (simulación de 1px PNG transparente)
        String dummyBase64 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==";

        Map<String, Object> resultado = geminiService.analizarImagen(dummyBase64);

        assertNotNull(resultado, "El resultado del servicio no debe ser nulo");
        assertTrue(resultado.containsKey("alimentos"), "El mapa devuelto debe contener la llave 'alimentos'");

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> alimentos = (List<Map<String, Object>>) resultado.get("alimentos");

        assertNotNull(alimentos, "La lista de alimentos no debe ser nula");
        assertFalse(alimentos.isEmpty(), "Debe retornar al menos un alimento detectado o de respaldo");

        Map<String, Object> primerAlimento = alimentos.get(0);

        assertTrue(primerAlimento.containsKey("nombre"), "Debe contener la propiedad 'nombre'");
        assertTrue(primerAlimento.containsKey("categoriaNombre"), "Debe contener la propiedad 'categoriaNombre'");
        assertTrue(primerAlimento.containsKey("cantidad"), "Debe contener la propiedad 'cantidad'");
        assertTrue(primerAlimento.containsKey("unidadMedida"), "Debe contener la propiedad 'unidadMedida'");
    }

    @Test
    @DisplayName("Valida la inclusión de prefijos data URI en el Base64")
    public void testAnalizarImagenConPrefijoDataUri() {
        String base64ConPrefijo = "data:image/jpeg;base64,aW1hZ2VuZGVwcnVlYmE=";

        assertDoesNotThrow(() -> {
            Map<String, Object> res = geminiService.analizarImagen(base64ConPrefijo);
            assertNotNull(res);
        }, "No debe lanzar excepciones al limpiar prefijos data:image/...;base64,");
    }
}