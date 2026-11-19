package edu.ucentral.vinni.security;

import edu.ucentral.vinni.Aplicacion.AuthService;
import edu.ucentral.vinni.entity.Usuario;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;

import java.util.Optional;

@Provider
@Priority(Priorities.AUTHENTICATION)
public class AuthFilter implements ContainerRequestFilter {

    @Inject
    AuthService authService;

    @Inject
    UsuarioAutenticado usuarioAutenticado;

    @Override
    public void filter(ContainerRequestContext requestContext) {
        if ("OPTIONS".equalsIgnoreCase(requestContext.getMethod())) {
            return;
        }

        String path = requestContext.getUriInfo().getPath();
        if (esRutaPublica(path)) {
            return;
        }

        String token = AuthorizationTokens.extraer(requestContext.getHeaderString("Authorization"));
        if (token == null) {
            abortar(requestContext, "Token no proporcionado");
            return;
        }

        Optional<Usuario> usuario = authService.validarToken(token);
        if (usuario.isEmpty()) {
            abortar(requestContext, "Token inválido o sesión expirada");
            return;
        }

        usuarioAutenticado.establecer(usuario.get());
    }

    public static boolean esRutaPublica(String path) {
        if (path == null || path.isBlank()) {
            return false;
        }
        String normalizado = path.startsWith("/") ? path.substring(1) : path;
        return normalizado.equals("hello")
                || normalizado.equals("auth/login")
                || normalizado.equals("auth/register")
                || normalizado.startsWith("q/");
    }

    private void abortar(ContainerRequestContext requestContext, String mensaje) {
        requestContext.abortWith(Response.status(Response.Status.UNAUTHORIZED)
                .type(MediaType.APPLICATION_JSON)
                .entity(new ErrorBody(mensaje))
                .build());
    }

    public static class ErrorBody {
        public String mensaje;

        public ErrorBody(String mensaje) {
            this.mensaje = mensaje;
        }
    }
}
