package edu.ucentral.vinni.repository;

import edu.ucentral.vinni.entity.Alimento;
import io.quarkus.hibernate.orm.panache.PanacheRepository;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.List;
import java.util.Optional;

@ApplicationScoped
public class AlimentoRepository implements PanacheRepository<Alimento> {

    public List<Alimento> listarDeUsuario(Long usuarioId) {
        return list("usuario.id = ?1 order by idAlimento", usuarioId);
    }

    public Optional<Alimento> buscarDeUsuario(Long idAlimento, Long usuarioId) {
        return find("idAlimento = ?1 and usuario.id = ?2", idAlimento, usuarioId).firstResultOptional();
    }

    public long contarPorCategoriaDeUsuario(Long idCategoria, Long usuarioId) {
        return count("categoria.idCategoria = ?1 and usuario.id = ?2", idCategoria, usuarioId);
    }
}
