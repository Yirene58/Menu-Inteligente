package edu.ucentral.vinni.repository;

import edu.ucentral.vinni.entity.Alimento;
import io.quarkus.hibernate.orm.panache.PanacheRepository;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class AlimentoRepository implements PanacheRepository<Alimento> {
}
