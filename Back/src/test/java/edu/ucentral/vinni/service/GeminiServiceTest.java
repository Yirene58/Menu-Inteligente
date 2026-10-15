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
}