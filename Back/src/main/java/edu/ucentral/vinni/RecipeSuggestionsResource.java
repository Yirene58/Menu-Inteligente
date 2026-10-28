package edu.ucentral.vinni;

import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import javax.sql.DataSource;

import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.ServerErrorException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

/** Recommends catalog recipes using the ingredients persisted in the user's pantry. */
@Path("/api/sugerencias/recetas")
@Produces(MediaType.APPLICATION_JSON)
public class RecipeSuggestionsResource {

    @Inject
    DataSource dataSource;

    @GET
    public List<RecipeSuggestion> suggest(@QueryParam("usuarioId") Long usuarioId) {
        if (usuarioId == null || usuarioId <= 0) {
            throw new BadRequestException("Debes indicar un usuarioId válido.");
        }
        try (var connection = dataSource.getConnection()) {
            Set<String> pantry = new HashSet<>();
            try (var statement = connection.prepareStatement(
                    "SELECT DISTINCT nombre FROM ingredientes WHERE usuario_id = ?")) {
                statement.setLong(1, usuarioId);
                try (ResultSet rows = statement.executeQuery()) {
                    while (rows.next()) pantry.add(normalize(rows.getString("nombre")));
                }
            }

            Map<Long, RecipeBuilder> recipes = new HashMap<>();
            String sql = "SELECT r.id, r.nombre, r.descripcion, r.categoria, r.minutos, r.imagen_url, "
                    + "ri.nombre AS ingrediente, ri.cantidad, ri.unidad "
                    + "FROM recetas r JOIN receta_ingredientes ri ON ri.receta_id = r.id "
                    + "ORDER BY r.id, ri.nombre";
            try (var statement = connection.prepareStatement(sql); ResultSet rows = statement.executeQuery()) {
                while (rows.next()) {
                    RecipeBuilder recipe = recipes.computeIfAbsent(rowsLong(rows, "id"), ignored -> builder(rows));
                    String ingredientName = rows.getString("ingrediente");
                    BigDecimal needed = rows.getBigDecimal("cantidad");
                    boolean hasEnough = pantry.contains(normalize(ingredientName));
                    recipe.ingredients.add(new RecipeIngredient(ingredientName, needed, rows.getString("unidad"), hasEnough));
                    if (hasEnough) recipe.matches++;
                }
            }
            return recipes.values().stream()
                    .filter(recipe -> recipe.matches > 0)
                    .map(RecipeBuilder::build)
                    .sorted((first, second) -> {
                        int byMatches = Integer.compare(second.coincidencias(), first.coincidencias());
                        if (byMatches != 0) return byMatches;
                        int byCompleteness = Integer.compare(first.faltantes(), second.faltantes());
                        return byCompleteness != 0 ? byCompleteness : first.nombre().compareToIgnoreCase(second.nombre());
                    })
                    .toList();
        } catch (SQLException exception) {
            throw new ServerErrorException("No fue posible consultar las recetas y el inventario.",
                    Response.Status.INTERNAL_SERVER_ERROR, exception);
        }
    }

    private static long rowsLong(ResultSet rows, String column) {
        try { return rows.getLong(column); }
        catch (SQLException exception) { throw new IllegalStateException(exception); }
    }

    private static RecipeBuilder builder(ResultSet rows) {
        try {
            return new RecipeBuilder(rows.getLong("id"), rows.getString("nombre"), rows.getString("descripcion"),
                    rows.getString("categoria"), rows.getInt("minutos"), rows.getString("imagen_url"));
        } catch (SQLException exception) { throw new IllegalStateException(exception); }
    }

    private static String normalize(String value) {
        return Normalizer.normalize(value == null ? "" : value.trim(), Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "").toLowerCase(Locale.ROOT);
    }

    public record RecipeIngredient(String nombre, BigDecimal cantidad, String unidad, boolean disponible) {}
    public record RecipeSuggestion(long id, String nombre, String descripcion, String categoria, int minutos,
                                  String imagenUrl, List<RecipeIngredient> ingredientes,
                                  int coincidencias, int totalIngredientes, int faltantes, int porcentajeDisponible) {}

    private static final class RecipeBuilder {
        final long id;
        final String nombre, descripcion, categoria, imagenUrl;
        final int minutos;
        final List<RecipeIngredient> ingredients = new ArrayList<>();
        int matches;

        RecipeBuilder(long id, String nombre, String descripcion, String categoria, int minutos, String imagenUrl) {
            this.id = id; this.nombre = nombre; this.descripcion = descripcion;
            this.categoria = categoria; this.minutos = minutos; this.imagenUrl = imagenUrl;
        }

        RecipeSuggestion build() {
            int total = ingredients.size();
            return new RecipeSuggestion(id, nombre, descripcion, categoria, minutos, imagenUrl,
                    List.copyOf(ingredients), matches, total, total - matches, total == 0 ? 0 : matches * 100 / total);
        }
    }
}
