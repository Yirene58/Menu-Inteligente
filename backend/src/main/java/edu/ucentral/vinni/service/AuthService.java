package edu.ucentral.vinni.service;

import edu.ucentral.vinni.entity.Usuario;
import edu.ucentral.vinni.repository.UsuarioRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import io.quarkus.elytron.security.common.BcryptUtil;
import io.quarkus.mailer.Mail;
import io.quarkus.mailer.Mailer;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class AuthService {

    @Inject
    UsuarioRepository usuarioRepository;

    @Inject
    Mailer mailer;

    @ConfigProperty(name = "quarkus.mailer.from")
    String sender;

    @Transactional
    public Optional<Usuario> registrar(String correo, String nombre, String organizacion, String contrasena) {
        String emailNormalizado = correo.trim().toLowerCase();
        if (usuarioRepository.buscarPorCorreo(emailNormalizado).isPresent()) {
            return Optional.empty();
        }

        Usuario usuario = new Usuario(emailNormalizado, nombre.trim(), organizacion == null ? null : organizacion.trim(), BcryptUtil.bcryptHash(contrasena), true);
        usuario.setToken(crearToken());
        usuarioRepository.persist(usuario);
        enviarBienvenida(usuario.getCorreo());
        return Optional.of(usuario);
    }

    @Transactional
    public Optional<Usuario> autenticar(String correo, String contrasena) {

        Optional<Usuario> usuario = usuarioRepository.buscarPorCorreo(correo.trim().toLowerCase());

        if (usuario.isEmpty()) {
            return Optional.empty();
        }

        Usuario usuarioEncontrado = usuario.get();

        if (!Boolean.TRUE.equals(usuarioEncontrado.getActivo())) {
            return Optional.empty();
        }

        if (!BcryptUtil.matches(contrasena, usuarioEncontrado.getContrasena())) {
            return Optional.empty();
        }

        String token = crearToken();

        usuarioEncontrado.setToken(token);

        usuarioRepository.persist(usuarioEncontrado);

        return Optional.of(usuarioEncontrado);
    }

    private String crearToken() {
        return UUID.randomUUID() + "-" + UUID.randomUUID();
    }

    private void enviarBienvenida(String correo) {
        String html = "<div style='font-family:Arial,sans-serif;padding:28px;color:#153b4a'>"
                + "<h1 style='color:#159a77'>Bienvenido a NaturaGrid</h1>"
                + "<p>Tu cuenta fue creada correctamente. Ya puedes acceder a tu espacio de tecnología sostenible.</p>"
                + "<p style='color:#52717d'>Innovación que cuida el futuro.</p></div>";
        mailer.send(Mail.withHtml(correo, "Bienvenido a NaturaGrid", html).setFrom(sender));
    }

    public Optional<Usuario> validarToken(String token) {

        if (token == null || token.isBlank()) {
            return Optional.empty();
        }

        Optional<Usuario> usuario = usuarioRepository.buscarPorToken(token);

        if (usuario.isEmpty()) {
            return Optional.empty();
        }

        Usuario usuarioEncontrado = usuario.get();

        if (!Boolean.TRUE.equals(usuarioEncontrado.getActivo())) {
            return Optional.empty();
        }

        return Optional.of(usuarioEncontrado);
    }

    @Transactional
    public boolean cerrarSesion(String token) {

        Optional<Usuario> usuario = usuarioRepository.buscarPorToken(token);

        if (usuario.isEmpty()) {
            return false;
        }

        Usuario usuarioEncontrado = usuario.get();

        usuarioEncontrado.setToken(null);

        usuarioRepository.persist(usuarioEncontrado);

        return true;
    }
}
