package edu.ucentral.vinni.service;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ValidadorFiltroAlimentarioTest {

    @Test
    void validaCompatibilidadConservadoraPorIngrediente() {
        assertTrue(ValidadorFiltroAlimentario.isCompatible(FiltroAlimentario.VEGANO, "arroz"));
        assertFalse(ValidadorFiltroAlimentario.isCompatible(FiltroAlimentario.VEGANO, "huevo"));
        assertTrue(ValidadorFiltroAlimentario.isCompatible(FiltroAlimentario.VEGETARIANO, "huevo"));
        assertFalse(ValidadorFiltroAlimentario.isCompatible(FiltroAlimentario.SIN_GLUTEN, "harina de trigo"));
        assertFalse(ValidadorFiltroAlimentario.isCompatible(FiltroAlimentario.SIN_GLUTEN, "salsa especial"));
        assertFalse(ValidadorFiltroAlimentario.isCompatible(FiltroAlimentario.SIN_FRUTOS_SECOS, "mani"));
        assertFalse(ValidadorFiltroAlimentario.isCompatible(
                FiltroAlimentario.VEGANO, "tomate con salsa especial"));
    }

    @Test
    void noDeclaraCompatibilidadSiUnIngredienteNoSePuedeVerificar() {
        assertTrue(ValidadorFiltroAlimentario.compatibleFilters(List.of("arroz", "tomate"))
                .contains(FiltroAlimentario.VEGANO));
        assertFalse(ValidadorFiltroAlimentario.compatibleFilters(List.of("arroz", "salsa secreta"))
                .contains(FiltroAlimentario.VEGANO));
    }
}
