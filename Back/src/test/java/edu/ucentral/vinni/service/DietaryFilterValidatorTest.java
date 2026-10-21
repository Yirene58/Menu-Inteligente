package edu.ucentral.vinni.service;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DietaryFilterValidatorTest {

    @Test
    void validaCompatibilidadConservadoraPorIngrediente() {
        assertTrue(DietaryFilterValidator.isCompatible(DietaryFilter.VEGANO, "arroz"));
        assertFalse(DietaryFilterValidator.isCompatible(DietaryFilter.VEGANO, "huevo"));
        assertTrue(DietaryFilterValidator.isCompatible(DietaryFilter.VEGETARIANO, "huevo"));
        assertFalse(DietaryFilterValidator.isCompatible(DietaryFilter.SIN_GLUTEN, "harina de trigo"));
        assertFalse(DietaryFilterValidator.isCompatible(DietaryFilter.SIN_GLUTEN, "salsa especial"));
        assertFalse(DietaryFilterValidator.isCompatible(DietaryFilter.SIN_FRUTOS_SECOS, "mani"));
        assertFalse(DietaryFilterValidator.isCompatible(DietaryFilter.VEGANO, "tomate con salsa especial"));
    }

    @Test
    void noDeclaraCompatibilidadSiUnIngredienteNoSePuedeVerificar() {
        assertTrue(DietaryFilterValidator.compatibleFilters(List.of("arroz", "tomate"))
                .contains(DietaryFilter.VEGANO));
        assertFalse(DietaryFilterValidator.compatibleFilters(List.of("arroz", "salsa secreta"))
                .contains(DietaryFilter.VEGANO));
    }
}
