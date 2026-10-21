package edu.ucentral.vinni.service;

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

public final class DietaryFilterValidator {

    private static final Set<String> PLANT_INGREDIENTS = Set.of(
            "aceite", "aceite de oliva", "aceite vegetal", "agua", "aguacate", "ajo", "albahaca",
            "arandano", "arroz", "avena", "azucar", "batata", "berenjena", "brocoli", "calabacin",
            "calabaza", "canela", "cebolla", "champiñon", "champiñones", "chile", "chocolate negro",
            "cilantro", "comino", "cous cous", "curcuma", "datil", "durazno", "espinaca", "fresa",
            "frijol", "frijoles", "garbanzo", "garbanzos", "guisante", "guisantes", "harina de arroz",
            "harina de maiz", "harina de trigo", "hierbabuena", "jengibre", "lenteja", "lentejas",
            "limon", "maiz", "mango", "manzana", "mantequilla de mani", "miel", "naranja", "oregano",
            "papa", "paprika", "pepino", "perejil", "pimienta", "pimiento", "platano", "quinoa",
            "sal", "salsa de soja", "tomate", "tomillo", "vainilla", "vinagre", "zanahoria",
            "caldo de verduras", "leche de coco", "leche de soya", "leche de almendra",
            "leche de avena", "leche de arroz", "tofu"
    );

    private static final Set<String> VEGETARIAN_INGREDIENTS = Set.of(
            "huevo", "huevos", "leche", "queso", "mantequilla", "crema", "yogur", "yogurt",
            "nata", "requeson"
    );

    private static final Set<String> GLUTEN_FREE_INGREDIENTS = Set.of(
            "aceite", "aceite de oliva", "agua", "aguacate", "ajo", "albahaca", "arandano",
            "arroz", "azucar", "batata", "berenjena", "brocoli", "calabacin", "calabaza", "canela",
            "cebolla", "champiñon", "champiñones", "chile", "chocolate negro", "cilantro", "comino",
            "curcuma", "datil", "durazno", "espinaca", "fresa", "frijol", "frijoles", "garbanzo",
            "garbanzos", "guisante", "guisantes", "harina de arroz", "harina de maiz", "jengibre",
            "lenteja", "lentejas", "limon", "maiz", "mango", "manzana", "naranja", "oregano",
            "papa", "paprika", "pepino", "perejil", "pimienta", "pimiento", "platano", "quinoa",
            "sal", "tomate", "tomillo", "vainilla", "vinagre", "zanahoria", "huevo", "huevos",
            "leche", "queso", "mantequilla", "crema", "yogur", "yogurt", "nata", "requeson",
            "leche de coco", "leche de soya", "leche de almendra", "leche de avena", "leche de arroz",
            "tofu", "aceite vegetal", "caldo de verduras"
    );

    private static final Set<String> NUT_FREE_INGREDIENTS = Set.of(
            "aceite", "aceite de oliva", "aceite vegetal", "agua", "aguacate", "ajo", "albahaca",
            "arandano", "arroz", "avena", "azucar", "batata", "berenjena", "brocoli", "calabacin",
            "calabaza", "canela", "cebolla", "champiñon", "champiñones", "chile", "cilantro", "comino",
            "curcuma", "datil", "durazno", "espinaca", "fresa", "frijol", "frijoles", "garbanzo",
            "garbanzos", "guisante", "guisantes", "harina de arroz", "harina de maiz", "harina de trigo",
            "jengibre", "lenteja", "lentejas", "limon", "maiz", "mango", "manzana", "naranja",
            "oregano", "papa", "paprika", "pepino", "perejil", "pimienta", "pimiento", "platano",
            "quinoa", "sal", "tomate", "tomillo", "vainilla", "vinagre", "zanahoria", "huevo", "huevos",
            "leche", "queso", "mantequilla", "crema", "yogur", "yogurt", "nata", "requeson", "tofu",
            "caldo de verduras"
    );

    private static final Map<DietaryFilter, Set<String>> FORBIDDEN_INGREDIENTS = Map.of(
            DietaryFilter.VEGANO, Set.of("carne", "pollo", "pescado", "marisco", "camar", "huevo", "leche",
                    "queso", "mantequilla", "crema", "yogur", "yogurt", "miel", "gelatina", "caldo de pollo",
                    "caldo de carne", "caldo de pescado", "jamon", "tocino", "salchicha", "camaron",
                    "camarones"),
            DietaryFilter.VEGETARIANO, Set.of("carne", "pollo", "pescado", "marisco", "camar", "jamon",
                    "tocino", "salchicha", "caldo de pollo", "caldo de carne", "caldo de pescado",
                    "camaron", "camarones"),
            DietaryFilter.SIN_GLUTEN, Set.of("trigo", "cebada", "centeno", "malta", "seitan", "cuscus",
                    "salsa de soja"),
            DietaryFilter.SIN_LACTEOS, Set.of("leche", "queso", "mantequilla", "crema", "yogur", "yogurt",
                    "nata", "requeson", "suero de leche", "caseina"),
            DietaryFilter.SIN_LACTOSA, Set.of("leche", "queso", "mantequilla", "crema", "yogur", "yogurt",
                    "nata", "requeson", "suero de leche", "caseina"),
            DietaryFilter.SIN_FRUTOS_SECOS, Set.of("almendra", "nuez", "nueces", "avellana", "pistacho",
                    "anacardo", "castana", "nuez de macadamia", "nuez pecana", "mani", "cacahuate",
                    "mantequilla de mani", "mantequilla de cacahuate", "praline", "mazapan")
    );

    private static final Pattern WORD_SEPARATOR = Pattern.compile("[^\\p{L}\\p{N}]+");

    private DietaryFilterValidator() {}

    public static List<DietaryFilter> compatibleFilters(List<String> ingredients) {
        return java.util.Arrays.stream(DietaryFilter.values())
                .filter(filter -> ingredients.stream().allMatch(ingredient -> isCompatible(filter, ingredient)))
                .toList();
    }

    public static boolean isCompatible(DietaryFilter filter, String ingredient) {
        String normalized = normalize(ingredient);
        if (normalized.isBlank() || containsForbidden(filter, normalized)) {
            return false;
        }
        return switch (filter) {
            case VEGANO -> isKnown(normalized, PLANT_INGREDIENTS);
            case VEGETARIANO -> isKnown(normalized, PLANT_INGREDIENTS)
                    || isKnown(normalized, VEGETARIAN_INGREDIENTS);
            case SIN_GLUTEN -> isKnown(normalized, GLUTEN_FREE_INGREDIENTS);
            case SIN_LACTEOS, SIN_LACTOSA -> isKnown(normalized, PLANT_INGREDIENTS);
            case SIN_FRUTOS_SECOS -> isKnown(normalized, NUT_FREE_INGREDIENTS);
        };
    }

    public static String normalize(String value) {
        String withoutAccents = Normalizer.normalize(value == null ? "" : value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "");
        return WORD_SEPARATOR.matcher(withoutAccents.toLowerCase(Locale.ROOT)).replaceAll(" ").trim();
    }

    private static boolean isKnown(String ingredient, Set<String> knownIngredients) {
        return knownIngredients.stream().map(DietaryFilterValidator::normalize).anyMatch(ingredient::equals);
    }

    private static boolean containsForbidden(DietaryFilter filter, String ingredient) {
        return FORBIDDEN_INGREDIENTS.get(filter).stream()
                .map(DietaryFilterValidator::normalize)
                .filter(forbidden -> !isPlantBasedDairyAlternative(filter, ingredient, forbidden))
                .anyMatch(forbidden -> ingredient.equals(forbidden) || ingredient.startsWith(forbidden + " ")
                        || ingredient.endsWith(" " + forbidden) || ingredient.contains(" " + forbidden + " "));
    }

    private static boolean isPlantBasedDairyAlternative(
            DietaryFilter filter, String ingredient, String forbidden) {
        boolean dairyFilter = filter == DietaryFilter.VEGANO || filter == DietaryFilter.SIN_LACTEOS
                || filter == DietaryFilter.SIN_LACTOSA;
        if (!dairyFilter) {
            return false;
        }
        boolean plantMilk = ingredient.startsWith("leche de ")
                && Set.of("leche de coco", "leche de soya", "leche de almendra", "leche de avena",
                        "leche de arroz").stream().anyMatch(ingredient::startsWith);
        boolean peanutButter = ingredient.startsWith("mantequilla de mani")
                || ingredient.startsWith("mantequilla de cacahuate");
        return (plantMilk && forbidden.equals("leche")) || (peanutButter && forbidden.equals("mantequilla"));
    }
}
