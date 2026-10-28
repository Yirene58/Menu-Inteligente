package edu.ucentral.vinni;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;

import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.OPTIONS;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

/** Builds storage and recipe suggestions from the ingredients supplied by the user's pantry. */
@Path("/api/sugerencias")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class IngredientSuggestionsResource {

    // ==========================================
    // PREFLIGHT CORS (OPTIONS)
    // ==========================================
    @OPTIONS
    @Path("/{path:.*}")
    public Response handleCorsPreflight() {
        return Response.ok()
                .header("Access-Control-Allow-Origin", "*")
                .header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
                .header("Access-Control-Allow-Headers", "accept, authorization, content-type, x-requested-with, origin")
                .build();
    }

    private static final List<Recipe> RECIPES = List.of(
            new Recipe("tortilla", "Tortilla de papa", "Plato principal", 30,
                    Map.of("huevo", 2.0, "papa", 2.0, "cebolla", 0.5)),
            new Recipe("ensalada-tomate", "Ensalada de tomate y aguacate", "Ensalada", 15,
                    Map.of("tomate", 2.0, "aguacate", 1.0, "cebolla", 0.25)),
            new Recipe("arroz-verduras", "Arroz con verduras", "Plato principal", 35,
                    Map.of("arroz", 1.0, "zanahoria", 1.0, "cebolla", 0.5, "tomate", 1.0)),
            new Recipe("crema-zanahoria", "Crema de zanahoria", "Sopa", 30,
                    Map.of("zanahoria", 3.0, "papa", 1.0, "leche", 1.0, "cebolla", 0.5)),
            new Recipe("pasta-tomate", "Pasta con salsa de tomate", "Plato principal", 25,
                    Map.of("pasta", 1.0, "tomate", 3.0, "cebolla", 0.5, "ajo", 1.0))
    );

    private static final Map<String, StorageAdvice> STORAGE = Map.ofEntries(
            Map.entry("leche", new StorageAdvice("Refrigerada", "Manténla entre 1 y 4 °C, bien cerrada y en un estante interior; respeta la fecha del envase.", "Refrigerar")),
            Map.entry("huevo", new StorageAdvice("Refrigerado", "Guárdalos en su caja en un estante interior del refrigerador.", "Refrigerar")),
            Map.entry("carne", new StorageAdvice("Refrigerada o congelada", "Refrigera en un recipiente cerrado y separado de alimentos listos para comer; congela si no la usarás pronto.", "Refrigerar o congelar")),
            Map.entry("pollo", new StorageAdvice("Refrigerado o congelado", "Refrigera en un recipiente cerrado en la parte baja; congela si no lo usarás pronto.", "Refrigerar o congelar")),
            Map.entry("pescado", new StorageAdvice("Refrigerado o congelado", "Consérvalo bien cerrado en la zona más fría y úsalo pronto; congélalo si hace falta.", "Refrigerar o congelar")),
            Map.entry("tomate", new StorageAdvice("A temperatura ambiente", "Déjalo sin lavar, en un lugar fresco y ventilado. Refrigéralo cuando esté muy maduro o cortado.", "Lugar fresco")),
            Map.entry("papa", new StorageAdvice("A temperatura ambiente", "Guárdala seca, en un lugar oscuro, fresco y ventilado; no la refrigeres.", "Lugar oscuro y ventilado")),
            Map.entry("cebolla", new StorageAdvice("A temperatura ambiente", "Guárdala seca y ventilada, separada de las papas. Refrigera la cebolla cortada.", "Lugar seco y ventilado")),
            Map.entry("aguacate", new StorageAdvice("A temperatura ambiente o refrigerado", "Deja madurar a temperatura ambiente. Una vez maduro, refrigéralo; guarda la mitad cortada tapada.", "Según maduración")),
            Map.entry("zanahoria", new StorageAdvice("Refrigerada", "Guárdala sin lavar en una bolsa o recipiente en el cajón de verduras.", "Refrigerar")),
            Map.entry("arroz", new StorageAdvice("A temperatura ambiente", "Conserva el arroz seco en un recipiente hermético, en un sitio fresco y sin humedad.", "Despensa seca")),
            Map.entry("pasta", new StorageAdvice("A temperatura ambiente", "Guarda la pasta seca en un recipiente hermético, en un lugar fresco y seco.", "Despensa seca")),
            Map.entry("ajo", new StorageAdvice("A temperatura ambiente", "Guarda las cabezas enteras en un lugar seco, oscuro y ventilado.", "Lugar seco y ventilado"))
    );

    @POST
    public Response suggest(SuggestionsRequest request) {
        try {
            if (request == null || request.ingredientes() == null) {
                return Response.status(Response.Status.BAD_REQUEST)
                        .header("Access-Control-Allow-Origin", "*")
                        .entity(new ErrorResponse("Debes enviar la lista de ingredientes guardados."))
                        .build();
            }
            LocalDate today = request.fechaActual() == null ? LocalDate.now() : request.fechaActual();
            List<Ingredient> ingredients = request.ingredientes().stream()
                    .filter(Objects::nonNull)
                    .map(item -> normalize(item, today))
                    .toList();
            List<StorageSuggestion> storage = ingredients.stream()
                    .map(this::storageSuggestion)
                    .sorted(Comparator.comparingInt(StorageSuggestion::diasParaVencer))
                    .toList();
            List<RecipeSuggestion> recipes = RECIPES.stream()
                    .map(recipe -> recipeSuggestion(recipe, ingredients))
                    .filter(recipe -> recipe.coincidencias() > 0)
                    .sorted(Comparator.comparingInt(RecipeSuggestion::prioridadVencimiento).reversed()
                            .thenComparing(Comparator.comparingInt(RecipeSuggestion::coincidencias).reversed())
                            .thenComparingInt(RecipeSuggestion::faltantes))
                    .limit(10)
                    .toList();

            SuggestionsResponse body = new SuggestionsResponse(today, storage, recipes);

            return Response.ok(body)
                    .header("Access-Control-Allow-Origin", "*")
                    .build();
        } catch (BadRequestException e) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(new ErrorResponse(e.getMessage()))
                    .build();
        } catch (Exception e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(new ErrorResponse("Error interno procesando las sugerencias."))
                    .build();
        }
    }

    private Ingredient normalize(IngredientInput input, LocalDate today) {
        if (input.nombre() == null || input.nombre().isBlank()) {
            throw new BadRequestException("Cada ingrediente debe tener un nombre.");
        }
        if (input.cantidad() != null && input.cantidad() < 0) {
            throw new BadRequestException("La cantidad de un ingrediente no puede ser negativa.");
        }
        int days = input.fechaVencimiento() == null ? Integer.MAX_VALUE
                : Math.toIntExact(ChronoUnit.DAYS.between(today, input.fechaVencimiento()));
        return new Ingredient(input.nombre().trim(), input.cantidad(), input.unidad(), input.fechaVencimiento(), days);
    }

    private StorageSuggestion storageSuggestion(Ingredient ingredient) {
        String key = ingredient.nombre().toLowerCase(Locale.ROOT);
        StorageAdvice advice = STORAGE.getOrDefault(key, new StorageAdvice("Según el envase",
                "Conserva el alimento siguiendo las indicaciones de su etiqueta. Manténlo cerrado y revisa su estado.", "Revisar etiqueta"));
        return new StorageSuggestion(ingredient.nombre(), ingredient.cantidad(), ingredient.unidad(),
                ingredient.fechaVencimiento(), ingredient.daysUntilExpiry(), advice.condicion(), advice.metodo(), advice.instruccion());
    }

    private RecipeSuggestion recipeSuggestion(Recipe recipe, List<Ingredient> ingredients) {
        Map<String, Ingredient> pantry = ingredients.stream().collect(Collectors.toMap(
                ingredient -> ingredient.nombre().toLowerCase(Locale.ROOT), Function.identity(),
                (first, later) -> first));
        List<String> available = new ArrayList<>();
        List<MissingIngredient> missing = new ArrayList<>();
        int score = 0;
        for (Map.Entry<String, Double> required : recipe.ingredients().entrySet()) {
            Ingredient found = pantry.get(required.getKey());
            if (found == null) {
                missing.add(new MissingIngredient(required.getKey(), required.getValue()));
                continue;
            }
            available.add(found.nombre());
            if (found.daysUntilExpiry() <= 3) score += Math.max(1, 4 - Math.max(0, found.daysUntilExpiry()));
            if (found.cantidad() != null && found.cantidad() < required.getValue()) {
                missing.add(new MissingIngredient(required.getKey(), required.getValue() - found.cantidad()));
            }
        }
        return new RecipeSuggestion(recipe.id(), recipe.nombre(), recipe.categoria(), recipe.minutos(),
                available, missing, available.size(), missing.size(), score);
    }

    public record SuggestionsRequest(LocalDate fechaActual, List<IngredientInput> ingredientes) {}
    public record IngredientInput(String nombre, Double cantidad, String unidad, LocalDate fechaVencimiento) {}
    public record Ingredient(String nombre, Double cantidad, String unidad, LocalDate fechaVencimiento, int daysUntilExpiry) {}
    public record SuggestionsResponse(LocalDate fechaAnalisis, List<StorageSuggestion> almacenamiento,
                                     List<RecipeSuggestion> recetas) {}
    public record StorageSuggestion(String ingrediente, Double cantidad, String unidad, LocalDate fechaVencimiento,
                                    int diasParaVencer, String condicion, String metodo, String instruccion) {}
    public record RecipeSuggestion(String id, String nombre, String categoria, int minutos,
                                   List<String> ingredientesDisponibles, List<MissingIngredient> ingredientesFaltantes,
                                   int coincidencias, int faltantes, int prioridadVencimiento) {}
    public record MissingIngredient(String nombre, double cantidad) {}
    private record Recipe(String id, String nombre, String categoria, int minutos, Map<String, Double> ingredients) {}
    private record StorageAdvice(String condicion, String metodo, String instruccion) {}

    public static class ErrorResponse {
        public String mensaje;

        public ErrorResponse(String mensaje) {
            this.mensaje = mensaje;
        }
    }
}