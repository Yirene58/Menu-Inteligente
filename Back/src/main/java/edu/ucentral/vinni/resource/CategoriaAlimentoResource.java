package edu.ucentral.vinni.resource;

import edu.ucentral.vinni.entity.CategoriaAlimento;
import edu.ucentral.vinni.entity.Usuario;
import edu.ucentral.vinni.repository.AlimentoRepository;
import edu.ucentral.vinni.repository.CategoriaAlimentoRepository;
import edu.ucentral.vinni.security.UsuarioAutenticado;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.OPTIONS;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.List;
import java.util.Optional;

@Path("/alimentos/categorias")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class CategoriaAlimentoResource {

    private static final List<CategoriaInicial> CATEGORIAS_INICIALES = List.of(
            new CategoriaInicial("Frutas", "Frutas frescas y deshidratadas"),
            new CategoriaInicial("Verduras", "Verduras y hortalizas"),
            new CategoriaInicial("Proteínas", "Carnes, huevos y legumbres"),
            new CategoriaInicial("Lácteos", "Leche, yogurt y quesos"),
            new CategoriaInicial("Cereales", "Granos, pan y pasta"),
            new CategoriaInicial("Otros", "Alimentos que no encajan en otra categoría")
    );

    @Inject
    CategoriaAlimentoRepository categoriaAlimentoRepository;

    @Inject
    AlimentoRepository alimentoRepository;

    @Inject
    UsuarioAutenticado usuarioAutenticado;

    // ==========================================
    // MANEJO DE PREFLIGHT CORS (OPTIONS)
    // ==========================================
    @OPTIONS
    @Path("/{path:.*}")
    public Response handleCorsPreflight() {
        return Response.ok()
                .header("Access-Control-Allow-Origin", "*")
                .header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
                .header("Access-Control-Allow-Headers", "accept, authorization, content-type, x-requested-with, origin")
                .build();
    }

    @GET
    @Transactional
    public Response listar() {
        try {
            Usuario usuario = usuarioAutenticado.get();
            List<CategoriaAlimento> categorias = categoriaAlimentoRepository.listarDeUsuario(usuario.getId());
            if (categorias.isEmpty()) {
                sembrarCategorias(usuario);
                categorias = categoriaAlimentoRepository.listarDeUsuario(usuario.getId());
            }
            return Response.ok(categorias)
                    .header("Access-Control-Allow-Origin", "*")
                    .build();
        } catch (Exception e) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(new ErrorResponse("No autorizado o sesión inválida."))
                    .build();
        }
    }

    @POST
    @Transactional
    public Response crear(CategoriaRequest request) {
        try {
            String nombre = validarNombre(request != null ? request.nombre : null);
            Usuario usuario = usuarioAutenticado.get();
            if (categoriaAlimentoRepository.buscarPorNombreDeUsuario(nombre, usuario.getId()).isPresent()) {
                return Response.status(Response.Status.CONFLICT)
                        .header("Access-Control-Allow-Origin", "*")
                        .entity(new ErrorResponse("Ya tienes una categoría con ese nombre."))
                        .build();
            }

            CategoriaAlimento categoria = new CategoriaAlimento(
                    usuario,
                    nombre,
                    request.descripcion == null ? null : request.descripcion.trim()
            );
            categoriaAlimentoRepository.persist(categoria);
            return Response.status(Response.Status.CREATED)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(categoria)
                    .build();
        } catch (IllegalArgumentException e) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(new ErrorResponse(e.getMessage()))
                    .build();
        } catch (Exception e) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(new ErrorResponse("Sesión no válida"))
                    .build();
        }
    }

    @PUT
    @Path("/{id}")
    @Transactional
    public Response actualizar(@PathParam("id") Long id, CategoriaRequest request) {
        try {
            String nombre = validarNombre(request != null ? request.nombre : null);
            Long usuarioId = usuarioAutenticado.getId();
            Optional<CategoriaAlimento> categoriaOpt = categoriaAlimentoRepository.buscarDeUsuario(id, usuarioId);
            if (categoriaOpt.isEmpty()) {
                return Response.status(Response.Status.NOT_FOUND)
                        .header("Access-Control-Allow-Origin", "*")
                        .entity(new ErrorResponse("Categoría no encontrada."))
                        .build();
            }

            Optional<CategoriaAlimento> duplicada = categoriaAlimentoRepository.buscarPorNombreDeUsuario(nombre, usuarioId);
            if (duplicada.isPresent() && !duplicada.get().getIdCategoria().equals(id)) {
                return Response.status(Response.Status.CONFLICT)
                        .header("Access-Control-Allow-Origin", "*")
                        .entity(new ErrorResponse("Ya tienes una categoría con ese nombre."))
                        .build();
            }

            CategoriaAlimento categoria = categoriaOpt.get();
            categoria.setNombre(nombre);
            categoria.setDescripcion(request.descripcion == null ? null : request.descripcion.trim());
            return Response.ok(categoria)
                    .header("Access-Control-Allow-Origin", "*")
                    .build();
        } catch (IllegalArgumentException e) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(new ErrorResponse(e.getMessage()))
                    .build();
        } catch (Exception e) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(new ErrorResponse("Sesión no válida"))
                    .build();
        }
    }

    @DELETE
    @Path("/{id}")
    @Transactional
    public Response eliminar(@PathParam("id") Long id) {
        try {
            Long usuarioId = usuarioAutenticado.getId();
            Optional<CategoriaAlimento> categoriaOpt = categoriaAlimentoRepository.buscarDeUsuario(id, usuarioId);
            if (categoriaOpt.isEmpty()) {
                return Response.status(Response.Status.NOT_FOUND)
                        .header("Access-Control-Allow-Origin", "*")
                        .entity(new ErrorResponse("Categoría no encontrada."))
                        .build();
            }

            if (alimentoRepository.contarPorCategoriaDeUsuario(id, usuarioId) > 0) {
                return Response.status(Response.Status.CONFLICT)
                        .header("Access-Control-Allow-Origin", "*")
                        .entity(new ErrorResponse("No se puede eliminar una categoría que aún tiene alimentos."))
                        .build();
            }

            categoriaAlimentoRepository.delete(categoriaOpt.get());
            return Response.ok(new MessageResponse("Categoría eliminada correctamente."))
                    .header("Access-Control-Allow-Origin", "*")
                    .build();
        } catch (Exception e) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(new ErrorResponse("Sesión no válida"))
                    .build();
        }
    }

    private void sembrarCategorias(Usuario usuario) {
        for (CategoriaInicial inicial : CATEGORIAS_INICIALES) {
            categoriaAlimentoRepository.persist(new CategoriaAlimento(usuario, inicial.nombre, inicial.descripcion));
        }
    }

    public static String validarNombre(String nombre) {
        if (nombre == null || nombre.trim().isEmpty()) {
            throw new IllegalArgumentException("El nombre de la categoría es obligatorio.");
        }
        String normalizado = nombre.trim();
        if (normalizado.length() > 100) {
            throw new IllegalArgumentException("El nombre de la categoría no puede superar 100 caracteres.");
        }
        return normalizado;
    }

    public static class CategoriaRequest {
        public String nombre;
        public String descripcion;
    }

    public static class ErrorResponse {
        public String mensaje;

        public ErrorResponse(String mensaje) {
            this.mensaje = mensaje;
        }
    }

    public static class MessageResponse {
        public String mensaje;

        public MessageResponse(String mensaje) {
            this.mensaje = mensaje;
        }
    }

    private record CategoriaInicial(String nombre, String descripcion) {
    }
}