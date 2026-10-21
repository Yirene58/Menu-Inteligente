package edu.ucentral.vinni.service;

import edu.ucentral.vinni.entity.Usuario;
import edu.ucentral.vinni.repository.UsuarioRepository;
import edu.ucentral.vinni.security.UsuarioAutenticado;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.NotFoundException;

import java.util.List;
import java.util.Set;

@ApplicationScoped
public class ServicioPreferenciasAlimentarias {

    @Inject
    UsuarioRepository usuarioRepository;

    @Inject
    UsuarioAutenticado usuarioAutenticado;

    @Transactional
    public List<String> getFilters() {
        return currentUser().getFiltrosAlimentarios().stream().sorted().toList();
    }

    @Transactional
    public List<String> updateFilters(Set<String> filters) {
        Usuario usuario = currentUser();
        usuario.setFiltrosAlimentarios(filters);
        return usuario.getFiltrosAlimentarios().stream().sorted().toList();
    }

    private Usuario currentUser() {
        return usuarioRepository.findByIdOptional(usuarioAutenticado.getId())
                .orElseThrow(NotFoundException::new);
    }
}
