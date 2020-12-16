package com.ipt.web.repository;

import com.ipt.web.model.Role2;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RoleRepository2 extends JpaRepository<Role2, Long>{
}
