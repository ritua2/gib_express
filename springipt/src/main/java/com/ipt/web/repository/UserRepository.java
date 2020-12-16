package com.ipt.web.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ipt.web.model.LoginUser;

@Repository
public interface UserRepository extends JpaRepository<LoginUser, Long> {
    public LoginUser findByUsername(String username);
	
	public void delete(LoginUser loginUser);
	
	public LoginUser findByEmail(String email);
}
