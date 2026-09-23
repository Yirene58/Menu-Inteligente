package edu.ucentral.vinni.repository;

import edu.ucentral.vinni.entity.CategoriaAlimento;
import io.quarkus.hibernate.orm.panache.PanacheRepository;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class CategoriaAlimentoRepository implements PanacheRepository<CategoriaAlimento> {
}
