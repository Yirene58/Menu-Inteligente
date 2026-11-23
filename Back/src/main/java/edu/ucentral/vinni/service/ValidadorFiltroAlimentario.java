package edu.ucentral.vinni.service;

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

public final class ValidadorFiltroAlimentario {

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

    /** Vegetales, frutas y condimentos comunes adicionales (sin gluten, lácteos ni frutos secos). */
    private static final Set<String> EXTRA_PLANT_INGREDIENTS = Set.of(
            "nectarina", "pera", "piña", "uva", "sandia", "melon", "papaya", "kiwi", "mora", "guayaba",
            "maracuya", "lulo", "lechuga", "repollo", "coliflor", "apio", "cebolla morada", "cebolla larga",
            "cebollin", "puerro", "ajo en polvo", "pimienta negra", "laurel", "romero", "arveja", "habichuela",
            "frijol negro", "frijol rojo", "yuca", "platano verde", "platano maduro", "mazorca", "pimenton",
            "aceite de girasol", "aceite de canola", "azucar morena", "panela", "limon verde", "lima",
            "jugo de limon", "agua caliente", "hielo", "nuez moscada"
    );

    /** Proteínas animales sin procesar: no son veganas, pero no tienen lácteos, gluten ni frutos secos. */
    private static final Set<String> NON_DAIRY_ANIMAL_INGREDIENTS = Set.of(
            "huevo", "clara de huevo", "yema de huevo", "pollo", "pechuga de pollo", "muslo de pollo",
            "carne", "carne de res", "carne molida", "res", "cerdo", "lomo de cerdo", "pavo",
            "pescado", "filete de pescado", "atun", "salmon", "tilapia", "camaron"
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

    private static final Map<FiltroAlimentario, Set<String>> FORBIDDEN_INGREDIENTS = Map.of(
            FiltroAlimentario.VEGANO, Set.of("carne", "pollo", "pescado", "marisco", "camar", "huevo", "leche",
                    "queso", "mantequilla", "crema", "yogur", "yogurt", "miel", "gelatina", "caldo de pollo",
                    "caldo de carne", "caldo de pescado", "jamon", "tocino", "salchicha", "camaron",
                    "camarones"),
            FiltroAlimentario.VEGETARIANO, Set.of("carne", "pollo", "pescado", "marisco", "camar", "jamon",
                    "tocino", "salchicha", "caldo de pollo", "caldo de carne", "caldo de pescado",
                    "camaron", "camarones"),
            FiltroAlimentario.SIN_GLUTEN, Set.of("trigo", "cebada", "centeno", "malta", "seitan", "cuscus",
                    "salsa de soja"),
            FiltroAlimentario.SIN_LACTEOS, Set.of("leche", "queso", "mantequilla", "crema", "yogur", "yogurt",
                    "nata", "requeson", "suero de leche", "caseina"),
            FiltroAlimentario.SIN_LACTOSA, Set.of("leche", "queso", "mantequilla", "crema", "yogur", "yogurt",
                    "nata", "requeson", "suero de leche", "caseina"),
            FiltroAlimentario.SIN_FRUTOS_SECOS, Set.of("almendra", "nuez", "nueces", "avellana", "pistacho",
                    "anacardo", "castana", "nuez de macadamia", "nuez pecana", "mani", "cacahuate",
                    "mantequilla de mani", "mantequilla de cacahuate", "praline", "mazapan")
    );

    private static final Pattern WORD_SEPARATOR = Pattern.compile("[^\\p{L}\\p{N}]+");

    private ValidadorFiltroAlimentario() {}

    public static List<FiltroAlimentario> compatibleFilters(List<String> ingredients) {
        return java.util.Arrays.stream(FiltroAlimentario.values())
                .filter(filter -> ingredients.stream().allMatch(ingredient -> isCompatible(filter, ingredient)))
                .toList();
    }

    public static boolean isCompatible(FiltroAlimentario filter, String ingredient) {
        String normalized = normalize(ingredient);
        String singular = singular(ingredient);
        if (normalized.isBlank() || containsForbidden(filter, normalized) || containsForbidden(filter, singular)) {
            return false;
        }
        return isKnownFor(filter, normalized) || isKnownFor(filter, singular);
    }

    private static boolean isKnownFor(FiltroAlimentario filter, String name) {
        boolean plant = isKnown(name, PLANT_INGREDIENTS) || isKnown(name, EXTRA_PLANT_INGREDIENTS);
        // Huevo, carnes y pescados sin procesar no contienen lácteos, gluten ni frutos secos.
        boolean animalSinLacteos = isKnown(name, NON_DAIRY_ANIMAL_INGREDIENTS);
        return switch (filter) {
            case VEGANO -> plant;
            case VEGETARIANO -> plant || isKnown(name, VEGETARIAN_INGREDIENTS);
            case SIN_GLUTEN -> isKnown(name, GLUTEN_FREE_INGREDIENTS) || isKnown(name, EXTRA_PLANT_INGREDIENTS)
                    || animalSinLacteos;
            case SIN_LACTEOS, SIN_LACTOSA -> plant || animalSinLacteos;
            case SIN_FRUTOS_SECOS -> isKnown(name, NUT_FREE_INGREDIENTS) || isKnown(name, EXTRA_PLANT_INGREDIENTS)
                    || animalSinLacteos;
        };
    }

    /** Normaliza (minúsculas, sin tildes) y lleva cada palabra a singular de forma aproximada. */
    public static String singular(String name) {
        return java.util.Arrays.stream(normalize(name).split(" "))
                .map(word -> {
                    if (word.length() > 4 && word.endsWith("ces")) return word.substring(0, word.length() - 3) + "z";
                    if (word.length() > 4 && word.matches(".*[lnrdj]es")) return word.substring(0, word.length() - 2);
                    if (word.length() > 3 && word.endsWith("s")) return word.substring(0, word.length() - 1);
                    return word;
                })
                .collect(java.util.stream.Collectors.joining(" "));
    }

    public static String normalize(String value) {
        String withoutAccents = Normalizer.normalize(value == null ? "" : value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "");
        return WORD_SEPARATOR.matcher(withoutAccents.toLowerCase(Locale.ROOT)).replaceAll(" ").trim();
    }

    private static boolean isKnown(String ingredient, Set<String> knownIngredients) {
        return knownIngredients.stream().map(ValidadorFiltroAlimentario::normalize).anyMatch(ingredient::equals);
    }

    private static boolean containsForbidden(FiltroAlimentario filter, String ingredient) {
        return FORBIDDEN_INGREDIENTS.get(filter).stream()
                .map(ValidadorFiltroAlimentario::normalize)
                .filter(forbidden -> !isPlantBasedDairyAlternative(filter, ingredient, forbidden))
                .anyMatch(forbidden -> ingredient.equals(forbidden) || ingredient.startsWith(forbidden + " ")
                        || ingredient.endsWith(" " + forbidden) || ingredient.contains(" " + forbidden + " "));
    }

    private static boolean isPlantBasedDairyAlternative(
            FiltroAlimentario filter, String ingredient, String forbidden) {
        boolean dairyFilter = filter == FiltroAlimentario.VEGANO || filter == FiltroAlimentario.SIN_LACTEOS
                || filter == FiltroAlimentario.SIN_LACTOSA;
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
