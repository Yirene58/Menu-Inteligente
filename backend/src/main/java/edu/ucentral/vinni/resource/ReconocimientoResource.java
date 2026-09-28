package edu.ucentral.vinni.resource;

import edu.ucentral.vinni.dto.AnalisisRequest;
import edu.ucentral.vinni.service.GeminiService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.Map;

@Path("/api/reconocimiento")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ReconocimientoResource {

    @Inject
    GeminiService geminiService;

    // Manejar explícitamente las peticiones OPTIONS (Preflight de CORS del navegador)
    @OPTIONS
    @Path("/analizar")
    public Response optionsAnalizar() {
        return Response.ok()
                .header("Access-Control-Allow-Origin", "*")
                .header("Access-Control-Allow-Headers", "Content-Type, Authorization, Accept")
                .header("Access-Control-Allow-Methods", "POST, OPTIONS, GET")
                .build();
    }

    @POST
    @Path("/analizar")
    public Response analizarImagen(AnalisisRequest request) {
        if (request == null || request.getImagenBase64() == null || request.getImagenBase64().isEmpty()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(Map.of("error", "No se proporcionó la imagen en Base64"))
                    .build();
        }

        Map<String, String> resultado = geminiService.analizarImagen(request.getImagenBase64());

        return Response.ok(resultado)
                .header("Access-Control-Allow-Origin", "*")
                .build();
    }
}