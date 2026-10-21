package edu.ucentral.vinni.service;

import jakarta.ws.rs.WebApplicationException;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class RecipeGenerationServiceTest {

    private final RecipeGenerationService service = new RecipeGenerationService();

    @Test
    void interpretaUnaRespuestaDeRecetasEstructurada() throws Exception {
        var recipes = service.parseRecipes("""
                {"recetas":[{"nombre":"Arroz con tomate","categoria":"Plato principal","minutos":25,
                "ingredientes":[{"nombre":"arroz","cantidad":1,"unidad":"taza"}]}]}
                """);

        assertEquals(1, recipes.size());
        assertEquals("Arroz con tomate", recipes.getFirst().nombre());
        assertEquals("arroz", recipes.getFirst().ingredientes().getFirst().nombre());
    }

    @Test
    void limitaLasRecetasParseadasACinco() throws Exception {
        String recipes = java.util.stream.IntStream.range(0, 7)
                .mapToObj(index -> """
                        {"nombre":"Receta %d","categoria":"Plato","minutos":20,
                        "ingredientes":[{"nombre":"arroz","cantidad":1,"unidad":"taza"}]}
                        """.formatted(index))
                .collect(java.util.stream.Collectors.joining(",", "{\"recetas\":[", "]}"));

        assertEquals(5, service.parseRecipes(recipes).size());
    }

    @Test
    void rechazaRecetasIncompletasDevueltasPorLaIa() {
        var exception = assertThrows(WebApplicationException.class, () -> service.parseRecipes("""
                {"recetas":[{"nombre":"Arroz","categoria":"Plato","minutos":0,"ingredientes":[]}]}
                """));

        assertEquals(502, exception.getResponse().getStatus());
    }

    @Test
    void rechazaUnaRespuestaJsonVacia() {
        var exception = assertThrows(WebApplicationException.class, () -> service.parseRecipes("null"));

        assertEquals(502, exception.getResponse().getStatus());
    }

    @Test
    void informaCuandoFaltaConfigurarLaClaveDelServicio() {
        var exception = assertThrows(
                WebApplicationException.class,
                () -> service.generar(java.util.List.of(), java.util.List.of()));

        assertEquals(503, exception.getResponse().getStatus());
    }
}
