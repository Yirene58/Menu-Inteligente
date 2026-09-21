package edu.ucentral.vinni.resource;

import edu.ucentral.vinni.entity.Usuario;
import edu.ucentral.vinni.service.AuthService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.Optional;

@Path("/auth")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AuthResource {

    @Inject
    AuthService authService;

    @POST
    @Path("/register")
    public Response register(RegisterRequest request) {
        if (request == null || request.nombre == null || request.nombre.isBlank() || !correoValido(request.correo) || !contrasenaValida(request.contrasena)) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(new ErrorResponse("Ingresa un correo válido y una contraseña de al menos 8 caracteres con letras y números"))
                    .build();
        }
        Optional<Usuario> usuario = authService.registrar(request.correo, request.nombre, request.organizacion, request.contrasena);
        if (usuario.isEmpty()) {
            return Response.status(Response.Status.CONFLICT)
                    .entity(new ErrorResponse("Ya existe una cuenta con este correo"))
                    .build();
        }
        Usuario creado = usuario.get();
        return Response.status(Response.Status.CREATED)
                .entity(new LoginResponse(creado.getId(), creado.getCorreo(), creado.getToken(), "Cuenta creada. Revisa tu correo de bienvenida."))
                .build();
    }

    // =========================
    // LOGIN
    // =========================

    @POST
    @Path("/login")
    public Response login(LoginRequest request) {

        if (request == null ||
                request.correo == null ||
                request.correo.isBlank() ||
                request.contrasena == null ||
                request.contrasena.isBlank()) {

            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(new ErrorResponse(
                            "Correo y contraseña son obligatorios"
                    ))
                    .build();
        }

        Optional<Usuario> usuario = authService.autenticar(
                request.correo,
                request.contrasena
        );

        if (usuario.isEmpty()) {

            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity(new ErrorResponse(
                            "Credenciales incorrectas"
                    ))
                    .build();
        }

        Usuario usuarioAutenticado = usuario.get();

        return Response.ok(
                new LoginResponse(
                        usuarioAutenticado.getId(),
                        usuarioAutenticado.getCorreo(),
                        usuarioAutenticado.getToken(), "Inicio de sesión correcto"
                )
        ).build();
    }

    // =========================
    // VALIDAR TOKEN
    // =========================

    @GET
    @Path("/validate")
    public Response validarToken(
            @HeaderParam("Authorization") String authorization) {

        if (authorization == null || authorization.isBlank()) {

            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity(new ErrorResponse(
                            "Token no proporcionado"
                    ))
                    .build();
        }

        String token = authorization;

        if (authorization.startsWith("Bearer ")) {
            token = authorization.substring(7);
        }

        Optional<Usuario> usuario = authService.validarToken(token);

        if (usuario.isEmpty()) {

            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity(new ErrorResponse(
                            "Token inválido o sesión expirada"
                    ))
                    .build();
        }

        Usuario usuarioAutenticado = usuario.get();

        return Response.ok(
                new LoginResponse(
                        usuarioAutenticado.getId(),
                        usuarioAutenticado.getCorreo(),
                        usuarioAutenticado.getToken(), "Sesión válida"
                )
        ).build();
    }

    // =========================
    // LOGOUT
    // =========================

    @POST
    @Path("/logout")
    public Response logout(
            @HeaderParam("Authorization") String authorization) {

        if (authorization == null || authorization.isBlank()) {

            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity(new ErrorResponse(
                            "Token no proporcionado"
                    ))
                    .build();
        }

        String token = authorization;

        if (authorization.startsWith("Bearer ")) {
            token = authorization.substring(7);
        }

        boolean cerrado = authService.cerrarSesion(token);

        if (!cerrado) {

            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity(new ErrorResponse(
                            "Token inválido"
                    ))
                    .build();
        }

        return Response.ok(
                new MessageResponse("Sesión cerrada correctamente")
        ).build();
    }

    // =========================
    // REQUEST LOGIN
    // =========================

    public static class LoginRequest {

        public String correo;
        public String contrasena;

        public LoginRequest() {
        }
    }

    public static class RegisterRequest {
        public String correo;
        public String nombre;
        public String organizacion;
        public String contrasena;
        public RegisterRequest() { }
    }

    private boolean correoValido(String correo) {
        return correo != null && correo.trim().matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");
    }

    private boolean contrasenaValida(String contrasena) {
        return contrasena != null && contrasena.length() >= 8
                && contrasena.matches(".*[A-Za-z].*") && contrasena.matches(".*\\d.*");
    }

    // =========================
    // RESPONSE LOGIN
    // =========================

    public static class LoginResponse {

        public Long id;
        public String correo;
        public String token;
        public String mensaje;

        public LoginResponse(
                Long id,
                String correo,
                String token, String mensaje) {

            this.id = id;
            this.correo = correo;
            this.token = token;
            this.mensaje = mensaje;
        }
    }

    // =========================
    // RESPONSE ERROR
    // =========================

    public static class ErrorResponse {

        public String mensaje;

        public ErrorResponse(String mensaje) {
            this.mensaje = mensaje;
        }
    }

    // =========================
    // RESPONSE MESSAGE
    // =========================

    public static class MessageResponse {

        public String mensaje;

        public MessageResponse(String mensaje) {
            this.mensaje = mensaje;
        }
    }
}
