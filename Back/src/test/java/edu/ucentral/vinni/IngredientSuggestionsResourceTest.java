package edu.ucentral.vinni;

import jakarta.ws.rs.BadRequestException;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class IngredientSuggestionsResourceTest {

    private final IngredientSuggestionsResource resource = new IngredientSuggestionsResource();

    @Test
    void ordenaAlmacenamientoPorVencimientoYProponeRecetasDisponibles() {
        LocalDate today = LocalDate.of(2026, 10, 14);
        var response = resource.suggest(new IngredientSuggestionsResource.SuggestionsRequest(
                today,
                List.of(
                        new IngredientSuggestionsResource.IngredientInput(
                                "huevo", 2.0, "unidad", today.plusDays(5)),
                        new IngredientSuggestionsResource.IngredientInput(
                                "tomate", 2.0, "unidad", today.plusDays(1))
                )
        ));

        assertEquals("tomate", response.almacenamiento().getFirst().ingrediente());
        assertTrue(response.recetas().stream().anyMatch(recipe -> recipe.id().equals("tortilla")));
    }

    @Test
    void rechazaIngredientesSinNombreOCantidadNegativa() {
        LocalDate today = LocalDate.of(2026, 10, 14);

        assertThrows(BadRequestException.class, () -> resource.suggest(
                new IngredientSuggestionsResource.SuggestionsRequest(today, List.of(
                        new IngredientSuggestionsResource.IngredientInput(" ", 1.0, "unidad", null)
                ))
        ));
        assertThrows(BadRequestException.class, () -> resource.suggest(
                new IngredientSuggestionsResource.SuggestionsRequest(today, List.of(
                        new IngredientSuggestionsResource.IngredientInput("tomate", -1.0, "unidad", null)
                ))
        ));
    }

    @Test
    void informaYOrdenaProductosVencidosYSinFecha() {
        LocalDate today = LocalDate.of(2026, 10, 14);
        var response = resource.suggest(new IngredientSuggestionsResource.SuggestionsRequest(
                today,
                List.of(
                        new IngredientSuggestionsResource.IngredientInput(
                                "arroz", 1.0, "kg", null),
                        new IngredientSuggestionsResource.IngredientInput(
                                "tomate", 2.0, "unidad", today.minusDays(1)),
                        new IngredientSuggestionsResource.IngredientInput(
                                "papa", 2.0, "unidad", today)
                )
        ));

        assertEquals("tomate", response.almacenamiento().getFirst().ingrediente());
        assertEquals(-1, response.almacenamiento().getFirst().diasParaVencer());
        assertEquals(today.minusDays(1), response.almacenamiento().getFirst().fechaVencimiento());
        assertEquals(Integer.MAX_VALUE, response.almacenamiento().getLast().diasParaVencer());
    }
}