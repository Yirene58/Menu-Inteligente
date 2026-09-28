package edu.ucentral.vinni.repository;

import edu.ucentral.vinni.entity.Usuario;
import io.quarkus.hibernate.orm.panache.PanacheRepository;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.Optional;

@ApplicationScoped
public class UsuarioRepository implements PanacheRepository<Usuario> {

    public Optional<Usuario> buscarPorCorreo(String correo) {
        return find("correo", correo).firstResultOptional();
    }

    public Optional<Usuario> buscarPorToken(String token) {
        return find("token", token).firstResultOptional();
    }
}