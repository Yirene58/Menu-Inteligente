package edu.ucentral.vinni.resource;

import edu.ucentral.vinni.entity.Alimento;
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

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Path("/alimentos")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AlimentoResource {

    @Inject
    AlimentoRepository alimentoRepository;

    @Inject
    CategoriaAlimentoRepository categoriaAlimentoRepository;

    @Inject
    UsuarioAutenticado usuarioAutenticado;

    // ==========================================
    // PREFLIGHT CORS (OPTIONS)
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
    public Response listar() {
        try {
            List<Alimento> alimentos = alimentoRepository.listarDeUsuario(usuarioAutenticado.getId());
            return Response.ok(alimentos)
                    .header("Access-Control-Allow-Origin", "*")
                    .build();
        } catch (Exception e) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(new ErrorResponse("No autorizado o sesión expirada."))
                    .build();
        }
    }

    @POST
    @Transactional
    public Response crear(CrearAlimentoRequest request) {
        try {
            validarNombre(request != null ? request.nombre : null);
            validarCantidad(request != null ? request.cantidad : null);
            validarUnidadMedida(request != null ? request.unidadMedida : null);
            validarCategoria(request != null ? request.idCategoria : null);

            Usuario usuario = usuarioAutenticado.get();
            Optional<CategoriaAlimento> categoria = categoriaAlimentoRepository
                    .buscarDeUsuario(request.idCategoria, usuario.getId());
            if (categoria.isEmpty()) {
                return Response.status(Response.Status.BAD_REQUEST)
                        .header("Access-Control-Allow-Origin", "*")
                        .entity(new ErrorResponse("La categoría seleccionada no existe."))
                        .build();
            }

            Alimento alimento = new Alimento();
            alimento.setUsuario(usuario);
            alimento.setNombre(request.nombre.trim());
            alimento.setCategoria(categoria.get());
            alimento.setDescripcion(request.descripcion == null ? null : request.descripcion.trim());
            alimento.setCantidad(request.cantidad);
            alimento.setUnidadMedida(request.unidadMedida.trim().toLowerCase());

            alimentoRepository.persist(alimento);

            return Response.status(Response.Status.CREATED)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(alimento)
                    .build();
        } catch (IllegalArgumentException e) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(new ErrorResponse(e.getMessage()))
                    .build();
        } catch (Exception e) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(new ErrorResponse("Sesión inválida."))
                    .build();
        }
    }

    @GET
    @Path("/{id}")
    public Response buscarPorId(@PathParam("id") Long id) {
        try {
            Optional<Alimento> alimento = alimentoRepository.buscarDeUsuario(id, usuarioAutenticado.getId());
            if (alimento.isEmpty()) {
                return Response.status(Response.Status.NOT_FOUND)
                        .header("Access-Control-Allow-Origin", "*")
                        .entity(new ErrorResponse("Alimento no encontrado."))
                        .build();
            }
            return Response.ok(alimento.get())
                    .header("Access-Control-Allow-Origin", "*")
                    .build();
        } catch (Exception e) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(new ErrorResponse("Sesión inválida."))
                    .build();
        }
    }

    @PUT
    @Path("/{id}")
    @Transactional
    public Response actualizar(@PathParam("id") Long id, CrearAlimentoRequest request) {
        try {
            validarNombre(request != null ? request.nombre : null);
            validarCantidad(request != null ? request.cantidad : null);
            validarUnidadMedida(request != null ? request.unidadMedida : null);
            validarCategoria(request != null ? request.idCategoria : null);

            Long usuarioId = usuarioAutenticado.getId();
            Optional<Alimento> alimentoOpt = alimentoRepository.buscarDeUsuario(id, usuarioId);
            if (alimentoOpt.isEmpty()) {
                return Response.status(Response.Status.NOT_FOUND)
                        .header("Access-Control-Allow-Origin", "*")
                        .entity(new ErrorResponse("Alimento no encontrado."))
                        .build();
            }

            Optional<CategoriaAlimento> categoria = categoriaAlimentoRepository
                    .buscarDeUsuario(request.idCategoria, usuarioId);
            if (categoria.isEmpty()) {
                return Response.status(Response.Status.BAD_REQUEST)
                        .header("Access-Control-Allow-Origin", "*")
                        .entity(new ErrorResponse("La categoría seleccionada no existe."))
                        .build();
            }

            Alimento alimento = alimentoOpt.get();
            alimento.setNombre(request.nombre.trim());
            alimento.setCategoria(categoria.get());
            alimento.setDescripcion(request.descripcion == null ? null : request.descripcion.trim());
            alimento.setCantidad(request.cantidad);
            alimento.setUnidadMedida(request.unidadMedida.trim().toLowerCase());

            return Response.ok(alimento)
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
                    .entity(new ErrorResponse("Sesión inválida."))
                    .build();
        }
    }

    @DELETE
    @Path("/{id}")
    @Transactional
    public Response eliminar(@PathParam("id") Long id) {
        try {
            Optional<Alimento> alimentoOpt = alimentoRepository.buscarDeUsuario(id, usuarioAutenticado.getId());
            if (alimentoOpt.isEmpty()) {
                return Response.status(Response.Status.NOT_FOUND)
                        .header("Access-Control-Allow-Origin", "*")
                        .entity(new ErrorResponse("Alimento no encontrado."))
                        .build();
            }

            alimentoRepository.delete(alimentoOpt.get());
            return Response.ok(new MessageResponse("Alimento eliminado correctamente."))
                    .header("Access-Control-Allow-Origin", "*")
                    .build();
        } catch (Exception e) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .header("Access-Control-Allow-Origin", "*")
                    .entity(new ErrorResponse("Sesión inválida."))
                    .build();
        }
    }

    public static void validarNombre(String nombre) {
        if (nombre == null || nombre.trim().isEmpty()) {
            throw new IllegalArgumentException("El nombre del alimento es obligatorio.");
        }
    }

    public static void validarCantidad(BigDecimal cantidad) {
        if (cantidad == null) {
            throw new IllegalArgumentException("La cantidad es obligatoria.");
        }
        if (cantidad.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("La cantidad no puede ser negativa.");
        }
    }

    public static void validarUnidadMedida(String unidadMedida) {
        if (unidadMedida == null || unidadMedida.trim().isEmpty()) {
            throw new IllegalArgumentException("La unidad de medida es obligatoria.");
        }

        String unidad = unidadMedida.trim().toLowerCase();
        List<String> unidadesPermitidas = List.of("kg", "g", "unidad", "litro", "ml");
        if (!unidadesPermitidas.contains(unidad)) {
            throw new IllegalArgumentException("La unidad de medida no es válida. Usa: kg, g, unidad, litro o ml.");
        }
    }

    public static void validarCategoria(Long idCategoria) {
        if (idCategoria == null) {
            throw new IllegalArgumentException("Debe seleccionar una categoría válida.");
        }
    }

    public static class CrearAlimentoRequest {
        public String nombre;
        public Long idCategoria;
        public String descripcion;
        public BigDecimal cantidad;
        public String unidadMedida;
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
}