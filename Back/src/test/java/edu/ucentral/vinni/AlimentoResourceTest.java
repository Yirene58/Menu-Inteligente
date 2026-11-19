package edu.ucentral.vinni;

import edu.ucentral.vinni.resource.AlimentoResource;
import edu.ucentral.vinni.resource.CategoriaAlimentoResource;
import edu.ucentral.vinni.security.AuthFilter;
import edu.ucentral.vinni.security.AuthorizationTokens;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

public class AlimentoResourceTest {

    @Test
    void validarCantidadNoNegativa() {
        IllegalArgumentException ex = Assertions.assertThrows(
                IllegalArgumentException.class,
                () -> AlimentoResource.validarCantidad(BigDecimal.valueOf(-1))
        );

        Assertions.assertTrue(ex.getMessage().contains("no puede ser negativa"));
    }

    @Test
    void validarUnidadValida() {
        Assertions.assertDoesNotThrow(() -> AlimentoResource.validarUnidadMedida("kg"));
        Assertions.assertThrows(IllegalArgumentException.class, () -> AlimentoResource.validarUnidadMedida("caja"));
    }

    @Test
    void validarNombreObligatorio() {
        IllegalArgumentException ex = Assertions.assertThrows(
                IllegalArgumentException.class,
                () -> AlimentoResource.validarNombre(null)
        );

        Assertions.assertTrue(ex.getMessage().contains("obligatorio"));
    }

    @Test
    void extraerTokenBearer() {
        Assertions.assertEquals("abc-123", AuthorizationTokens.extraer("Bearer abc-123"));
        Assertions.assertEquals("abc-123", AuthorizationTokens.extraer("bearer abc-123"));
        Assertions.assertNull(AuthorizationTokens.extraer("   "));
        Assertions.assertNull(AuthorizationTokens.extraer(null));
    }

    @Test
    void rutasPublicasDeAutenticacion() {
        Assertions.assertTrue(AuthFilter.esRutaPublica("auth/login"));
        Assertions.assertTrue(AuthFilter.esRutaPublica("/auth/register"));
        Assertions.assertTrue(AuthFilter.esRutaPublica("hello"));
        Assertions.assertFalse(AuthFilter.esRutaPublica("alimentos"));
        Assertions.assertFalse(AuthFilter.esRutaPublica("alimentos/categorias"));
        Assertions.assertFalse(AuthFilter.esRutaPublica("auth/validate"));
        Assertions.assertFalse(AuthFilter.esRutaPublica("auth/logout"));
    }

    @Test
    void validarNombreCategoria() {
        Assertions.assertEquals("Frutas", CategoriaAlimentoResource.validarNombre("  Frutas  "));
        Assertions.assertThrows(IllegalArgumentException.class, () -> CategoriaAlimentoResource.validarNombre(" "));
    }
}
