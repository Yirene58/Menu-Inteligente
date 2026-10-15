package edu.ucentral.vinni.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "usuarios")
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String correo;

    // Se deja nullable para que Hibernate pueda migrar cuentas existentes.
    // El endpoint de registro exige el campo para las cuentas nuevas.
    @Column
    private String nombre;

    private String organizacion;

    @Column(nullable = false)
    private String contrasena;

    @Column(nullable = false)
    private Boolean activo = true;

    @Column(unique = true)
    private String token;

    public Usuario() {
    }

    public Usuario(String correo, String nombre, String organizacion, String contrasena, Boolean activo) {
        this.correo = correo;
        this.nombre = nombre;
        this.organizacion = organizacion;
        this.contrasena = contrasena;
        this.activo = activo;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getCorreo() {
        return correo;
    }

    public void setCorreo(String correo) {
        this.correo = correo;
    }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public String getOrganizacion() { return organizacion; }
    public void setOrganizacion(String organizacion) { this.organizacion = organizacion; }

    public String getContrasena() {
        return contrasena;
    }

    public void setContrasena(String contrasena) {
        this.contrasena = contrasena;
    }

    public Boolean getActivo() {
        return activo;
    }

    public void setActivo(Boolean activo) {
        this.activo = activo;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }
}
