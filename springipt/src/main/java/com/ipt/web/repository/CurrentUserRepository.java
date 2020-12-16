package com.ipt.web.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ipt.web.model.CurrentUser;

@Repository
public interface CurrentUserRepository extends JpaRepository<CurrentUser, Long> {
    //CurrentUser findByUsername(String username);
}