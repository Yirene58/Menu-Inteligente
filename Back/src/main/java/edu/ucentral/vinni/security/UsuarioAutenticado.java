package edu.ucentral.vinni.security;

import edu.ucentral.vinni.entity.Usuario;
import jakarta.enterprise.context.RequestScoped;

@RequestScoped
public class UsuarioAutenticado {

    private Usuario usuario;

    public void establecer(Usuario usuario) {
        this.usuario = usuario;
    }

    public Usuario get() {
        if (usuario == null) {
            throw new IllegalStateException("No hay un usuario autenticado en la petición.");
        }
        return usuario;
    }

    public Long getId() {
        return get().getId();
    }
}
