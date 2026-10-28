package edu.ucentral.vinni.resource;

import edu.ucentral.vinni.dto.AnalisisRequest;
import edu.ucentral.vinni.service.GeminiService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.OPTIONS;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.Map;

@Path("/api/reconocimiento")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ReconocimientoResource {

    @Inject
    GeminiService geminiService;

    @OPTIONS
    @Path("/{path:.*}")
    public Response handleCorsPreflight() {
        return Response.ok()
                .header("Access-Control-Allow-Origin", "*")
                .header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
                .header("Access-Control-Allow-Headers", "accept, authorization, content-type, x-requested-with, origin")
                .build();
    }

    @POST
    @Path("/analizar")
    public Response analizar(AnalisisRequest request) {
        try {
            if (request == null || request.getImagenBase64() == null || request.getImagenBase64().isBlank()) {
                return Response.status(Response.Status.BAD_REQUEST)
                        .header("Access-Control-Allow-Origin", "*")
                        .entity(new ErrorResponse("La imagen en Base64 es obligatoria."))
                        .build();
            }

            Map<String, Object> resultado = geminiService.analizarImagen(request.getImagenBase64());

            return Response.ok(resultado)
                    .header("Access-Control-Allow-Origin", "*")
                    .build();

        } catch (Exception e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(new ErrorResponse("Error al analizar la imagen: " + e.getMessage()))
                    .build();
        }
    }

    public static class ErrorResponse {
        public String mensaje;

        public ErrorResponse(String mensaje) {
            this.mensaje = mensaje;
        }
    }
}