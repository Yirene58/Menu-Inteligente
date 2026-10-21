package edu.ucentral.vinni;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;

import edu.ucentral.vinni.security.UsuarioAutenticado;
import edu.ucentral.vinni.service.FiltroAlimentario;
import edu.ucentral.vinni.service.ValidadorFiltroAlimentario;
import edu.ucentral.vinni.service.ServicioPreferenciasAlimentarias;
import edu.ucentral.vinni.service.ServicioGeneracionRecetas;
import edu.ucentral.vinni.service.ServicioGeneracionRecetas.GeneratedRecipe;
import edu.ucentral.vinni.service.ServicioGeneracionRecetas.PantryIngredient;
import edu.ucentral.vinni.service.ServicioGeneracionRecetas.RecipeIngredient;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

/** Builds storage and recipe suggestions from the ingredients supplied by the user's pantry. */
@Path("/api/sugerencias")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class IngredientSuggestionsResource {

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

    @Inject
    ServicioGeneracionRecetas recipeGenerationService;

    @Inject
    UsuarioAutenticado usuarioAutenticado;

    @Inject
    ServicioPreferenciasAlimentarias dietaryPreferenceService;

    @POST
    public SuggestionsResponse suggest(SuggestionsRequest request) {
        List<Ingredient> ingredients = validatedIngredients(request);
        List<FiltroAlimentario> filters = usuarioAutenticado.get().getFiltrosAlimentarios().stream()
                .map(FiltroAlimentario::valueOf)
                .sorted()
                .toList();
        List<PantryIngredient> pantry = ingredients.stream()
                .map(ingredient -> new PantryIngredient(
                        ingredient.nombre(), ingredient.cantidad(), ingredient.unidad()))
                .toList();
        List<GeneratedRecipe> generatedRecipes = ingredients.isEmpty()
                ? List.of()
                : recipeGenerationService.generar(pantry, filters);
        return buildResponse(request, ingredients, filters, generatedRecipes);
    }

    @GET
    @Path("/filtros")
    public FilterPreferences getFilters() {
        return new FilterPreferences(dietaryPreferenceService.getFilters());
    }

    @PUT
    @Path("/filtros")
    public FilterPreferences updateFilters(FilterRequest request) {
        if (request == null || request.filtros() == null) {
            throw new BadRequestException("Debes enviar la lista de filtros alimentarios.");
        }
        LinkedHashSet<String> filters = request.filtros().stream()
                .map(this::normalizeFilter)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        return new FilterPreferences(dietaryPreferenceService.updateFilters(filters));
    }

    private String normalizeFilter(String value) {
        if (value == null) {
            throw new BadRequestException("Cada filtro alimentario debe ser válido.");
        }
        try {
            return FiltroAlimentario.valueOf(value.trim().toUpperCase(Locale.ROOT)).name();
        } catch (IllegalArgumentException exception) {
            throw new BadRequestException("El filtro alimentario no está disponible.");
        }
    }

    List<Ingredient> validatedIngredients(SuggestionsRequest request) {
        if (request == null || request.ingredientes() == null) {
            throw new BadRequestException("Debes enviar la lista de ingredientes guardados.");
        }
        LocalDate today = request.fechaActual() == null ? LocalDate.now() : request.fechaActual();
        return request.ingredientes().stream()
                .filter(Objects::nonNull)
                .map(item -> normalize(item, today))
                .toList();
    }

    SuggestionsResponse buildResponse(
            SuggestionsRequest request,
            List<Ingredient> ingredients,
            List<FiltroAlimentario> filters,
            List<GeneratedRecipe> generatedRecipes) {
        LocalDate today = request.fechaActual() == null ? LocalDate.now() : request.fechaActual();
        List<StorageSuggestion> storage = ingredients.stream()
                .map(this::storageSuggestion)
                .sorted(Comparator.comparingInt(StorageSuggestion::diasParaVencer))
                .toList();
        List<RecipeSuggestion> recipes = generatedRecipes.stream()
                .map(recipe -> recipeSuggestion(recipe, ingredients))
                .filter(recipe -> recipe.coincidencias() > 0)
                .filter(recipe -> filters.isEmpty()
                        || recipe.filtrosCompatibles().stream()
                        .map(FiltroAlimentario::valueOf).anyMatch(filters::contains))
                .sorted(Comparator.comparingInt(RecipeSuggestion::prioridadVencimiento).reversed()
                        .thenComparing(Comparator.comparingInt(RecipeSuggestion::coincidencias).reversed())
                        .thenComparingInt(RecipeSuggestion::faltantes))
                .limit(5)
                .toList();
        return new SuggestionsResponse(today, storage, recipes, filters.stream().map(Enum::name).toList());
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

    private RecipeSuggestion recipeSuggestion(GeneratedRecipe recipe, List<Ingredient> ingredients) {
        Map<String, Ingredient> pantry = ingredients.stream().collect(Collectors.toMap(
                ingredient -> ValidadorFiltroAlimentario.normalize(ingredient.nombre()), Function.identity(),
                (first, later) -> first));
        List<String> available = new ArrayList<>();
        List<MissingIngredient> missing = new ArrayList<>();
        List<String> requiredNames = new ArrayList<>();
        int score = 0;
        for (RecipeIngredient required : recipe.ingredientes()) {
            String normalizedName = ValidadorFiltroAlimentario.normalize(required.nombre());
            requiredNames.add(required.nombre());
            Ingredient found = pantry.get(normalizedName);
            if (found == null) {
                missing.add(new MissingIngredient(required.nombre(), required.cantidad(), required.unidad()));
                continue;
            }
            available.add(found.nombre());
            if (found.daysUntilExpiry() <= 3) score += Math.max(1, 4 - Math.max(0, found.daysUntilExpiry()));
            if (found.cantidad() != null && found.cantidad() < required.cantidad()) {
                missing.add(new MissingIngredient(
                        required.nombre(), required.cantidad() - found.cantidad(), required.unidad()));
            }
        }
        List<FiltroAlimentario> compatibleFilters = ValidadorFiltroAlimentario.compatibleFilters(requiredNames);
        String id = ValidadorFiltroAlimentario.normalize(recipe.nombre()).replace(' ', '-');
        return new RecipeSuggestion(id, recipe.nombre(), recipe.categoria(), recipe.minutos(),
                recipe.ingredientes(), available, missing, available.size(), missing.size(), score,
                compatibleFilters.stream().map(Enum::name).toList());
    }

    public record SuggestionsRequest(LocalDate fechaActual, List<IngredientInput> ingredientes) {}
    public record IngredientInput(String nombre, Double cantidad, String unidad, LocalDate fechaVencimiento) {}
    public record Ingredient(String nombre, Double cantidad, String unidad, LocalDate fechaVencimiento, int daysUntilExpiry) {}
    public record SuggestionsResponse(LocalDate fechaAnalisis, List<StorageSuggestion> almacenamiento,
                                     List<RecipeSuggestion> recetas, List<String> filtrosActivos) {}
    public record StorageSuggestion(String ingrediente, Double cantidad, String unidad, LocalDate fechaVencimiento,
                                    int diasParaVencer, String condicion, String metodo, String instruccion) {}
    public record RecipeSuggestion(String id, String nombre, String categoria, int minutos,
                                   List<RecipeIngredient> ingredientes, List<String> ingredientesDisponibles,
                                   List<MissingIngredient> ingredientesFaltantes, int coincidencias, int faltantes,
                                   int prioridadVencimiento, List<String> filtrosCompatibles) {}
    public record MissingIngredient(String nombre, double cantidad, String unidad) {}
    public record FilterRequest(List<String> filtros) {}
    public record FilterPreferences(List<String> filtros) {}
    private record StorageAdvice(String condicion, String metodo, String instruccion) {}
}
