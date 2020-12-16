package com.ipt.web.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import com.ipt.web.model.MappedUser;

@Repository
public interface MappingRepository extends JpaRepository<MappedUser, Long> {
	List<MappedUser> findAll();
	MappedUser findByUser(String user);
}