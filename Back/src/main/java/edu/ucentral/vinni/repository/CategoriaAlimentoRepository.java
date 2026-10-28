package edu.ucentral.vinni.repository;

import edu.ucentral.vinni.entity.CategoriaAlimento;
import io.quarkus.hibernate.orm.panache.PanacheRepository;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.List;
import java.util.Optional;

@ApplicationScoped
public class CategoriaAlimentoRepository implements PanacheRepository<CategoriaAlimento> {

    public List<CategoriaAlimento> listarDeUsuario(Long usuarioId) {
        return list("usuario.id = ?1 order by nombre", usuarioId);
    }

    public Optional<CategoriaAlimento> buscarDeUsuario(Long idCategoria, Long usuarioId) {
        return find("idCategoria = ?1 and usuario.id = ?2", idCategoria, usuarioId).firstResultOptional();
    }

    public Optional<CategoriaAlimento> buscarPorNombreDeUsuario(String nombre, Long usuarioId) {
        return find("nombre = ?1 and usuario.id = ?2", nombre, usuarioId).firstResultOptional();
    }
}
