package edu.ucentral.vinni;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.notNullValue;

@QuarkusTest
public class ReconocimientoResourceTest {

    @Test
    public void testAnalizarImagenEndpoint() {
        // Un payload JSON sencillo para validar que el endpoint responda un 200 o estructura valida
        String jsonRequest = """
            {
              "imagenBase64": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==",
              "nombreArchivo": "prueba.png"
            }
            """;

        given()
          .contentType(ContentType.JSON)
          .body(jsonRequest)
          .when()
          .post("/api/reconocimiento/analizar")
          .then()
             .statusCode(200)
             .body("objeto", notNullValue());
    }
}