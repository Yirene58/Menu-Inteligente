package edu.ucentral.vinni.resource;

import edu.ucentral.vinni.dto.AnalisisRequest;
import edu.ucentral.vinni.service.GeminiService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
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

    @POST
    @Path("/analizar")
    public Response analizarImagen(AnalisisRequest request) {
        if (request == null || request.getImagenBase64() == null || request.getImagenBase64().isBlank()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(Map.of("error", "No se proporcionó la imagen en Base64"))
                    .build();
        }

        Map<String, String> resultado = geminiService.analizarImagen(request.getImagenBase64());

        return Response.ok(resultado).build();
    }
}