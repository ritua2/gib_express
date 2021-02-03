package com.ipt.web.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ipt.web.model.UnconfirmedUser;

@Repository
public interface UnconfirmedUserRepository extends JpaRepository<UnconfirmedUser, Long> {
    UnconfirmedUser findByUsername(String username);
    UnconfirmedUser findByEmail(String email);
}
