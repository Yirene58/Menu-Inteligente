package edu.ucentral.vinni;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;

@QuarkusTest
class RootResourceTest {

    @Test
    void rootReturnsServiceStatus() {
        given()
          .when().get("/")
          .then()
             .statusCode(200)
             .body("service", is("menu-inteligente-api"))
             .body("status", is("running"));
    }
}
