package edu.ucentral.vinni;

import edu.ucentral.vinni.service.DietaryFilter;
import edu.ucentral.vinni.service.RecipeGenerationService.GeneratedRecipe;
import edu.ucentral.vinni.service.RecipeGenerationService.RecipeIngredient;
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
    void calculaAlmacenamientoConRecetasGeneradasSegunLosIngredientes() {
        LocalDate today = LocalDate.of(2026, 10, 14);
        var request = new IngredientSuggestionsResource.SuggestionsRequest(today, List.of(
                new IngredientSuggestionsResource.IngredientInput("tomate", 2.0, "unidad", today.plusDays(1)),
                new IngredientSuggestionsResource.IngredientInput("arroz", 1.0, "kg", null)
        ));
        List<GeneratedRecipe> generated = List.of(
                recipe("Arroz con tomate", "Plato principal", "arroz", "tomate"),
                recipe("Ensalada de pepino", "Ensalada", "arroz", "pepino")
        );

        var response = resource.buildResponse(request, resource.validatedIngredients(request), List.of(), generated);

        assertEquals("tomate", response.almacenamiento().getFirst().ingrediente());
        assertEquals(List.of("Arroz con tomate", "Ensalada de pepino"),
                response.recetas().stream().map(IngredientSuggestionsResource.RecipeSuggestion::nombre).toList());
        assertTrue(response.recetas().getFirst().ingredientesDisponibles().contains("arroz"));
        assertTrue(response.recetas().get(1).ingredientesFaltantes().stream()
                .anyMatch(missing -> missing.nombre().equals("pepino")));
    }

    @Test
    void combinaFiltrosConReglaOrYDescartaRecetasNoAptas() {
        LocalDate today = LocalDate.of(2026, 10, 14);
        var request = new IngredientSuggestionsResource.SuggestionsRequest(today, List.of(
                new IngredientSuggestionsResource.IngredientInput("arroz", 2.0, "kg", null)
        ));
        List<GeneratedRecipe> generated = List.of(
                recipe("Arroz con tomate", "Plato principal", "arroz", "tomate"),
                recipe("Arroz con huevo", "Plato principal", "arroz", "huevo"),
                recipe("Arroz con carne y trigo", "Plato principal", "arroz", "carne", "harina de trigo")
        );

        var response = resource.buildResponse(
                request,
                resource.validatedIngredients(request),
                List.of(DietaryFilter.VEGANO, DietaryFilter.SIN_GLUTEN),
                generated);

        assertEquals(List.of("Arroz con tomate", "Arroz con huevo"),
                response.recetas().stream().map(IngredientSuggestionsResource.RecipeSuggestion::nombre).toList());
        assertTrue(response.recetas().get(1).filtrosCompatibles().contains("SIN_GLUTEN"));
        assertEquals(List.of("VEGANO", "SIN_GLUTEN"), response.filtrosActivos());
    }

    @Test
    void noClasificaComoAptaUnaRecetaConIngredienteDesconocido() {
        LocalDate today = LocalDate.of(2026, 10, 14);
        var request = new IngredientSuggestionsResource.SuggestionsRequest(today, List.of(
                new IngredientSuggestionsResource.IngredientInput("arroz", 2.0, "kg", null)
        ));
        var generated = List.of(recipe("Arroz especial", "Plato principal", "arroz", "salsa especial"));

        var response = resource.buildResponse(
                request,
                resource.validatedIngredients(request),
                List.of(DietaryFilter.VEGANO),
                generated);

        assertTrue(response.recetas().isEmpty());
    }

    @Test
    void limitaLasRecetasDevueltasACinco() {
        LocalDate today = LocalDate.of(2026, 10, 14);
        var request = new IngredientSuggestionsResource.SuggestionsRequest(today, List.of(
                new IngredientSuggestionsResource.IngredientInput("tomate", 2.0, "unidad", null)
        ));
        List<GeneratedRecipe> generated = java.util.stream.IntStream.range(0, 7)
                .mapToObj(index -> recipe("Receta " + index, "Ensalada", "tomate"))
                .toList();

        var response = resource.buildResponse(request, resource.validatedIngredients(request), List.of(), generated);

        assertEquals(5, response.recetas().size());
    }

    @Test
    void rechazaIngredientesSinNombreOCantidadNegativa() {
        LocalDate today = LocalDate.of(2026, 10, 14);

        assertThrows(BadRequestException.class, () -> resource.validatedIngredients(
                new IngredientSuggestionsResource.SuggestionsRequest(today, List.of(
                        new IngredientSuggestionsResource.IngredientInput(" ", 1.0, "unidad", null)
                ))
        ));
        assertThrows(BadRequestException.class, () -> resource.validatedIngredients(
                new IngredientSuggestionsResource.SuggestionsRequest(today, List.of(
                        new IngredientSuggestionsResource.IngredientInput("tomate", -1.0, "unidad", null)
                ))
        ));
    }

    @Test
    void informaYOrdenaProductosVencidosYSinFecha() {
        LocalDate today = LocalDate.of(2026, 10, 14);
        var request = new IngredientSuggestionsResource.SuggestionsRequest(today, List.of(
                new IngredientSuggestionsResource.IngredientInput("arroz", 1.0, "kg", null),
                new IngredientSuggestionsResource.IngredientInput("tomate", 2.0, "unidad", today.minusDays(1)),
                new IngredientSuggestionsResource.IngredientInput("papa", 2.0, "unidad", today)
        ));

        var response = resource.buildResponse(request, resource.validatedIngredients(request), List.of(), List.of());

        assertEquals("tomate", response.almacenamiento().getFirst().ingrediente());
        assertEquals(-1, response.almacenamiento().getFirst().diasParaVencer());
        assertEquals(today.minusDays(1), response.almacenamiento().getFirst().fechaVencimiento());
        assertEquals(Integer.MAX_VALUE, response.almacenamiento().getLast().diasParaVencer());
    }

    private GeneratedRecipe recipe(String name, String category, String... ingredients) {
        return new GeneratedRecipe(
                name,
                category,
                20,
                java.util.Arrays.stream(ingredients)
                        .map(ingredient -> new RecipeIngredient(ingredient, 1.0, "unidad"))
                        .toList());
    }
}
