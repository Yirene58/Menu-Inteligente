package edu.ucentral.vinni;

import edu.ucentral.vinni.resource.AlimentoResource;
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
}
