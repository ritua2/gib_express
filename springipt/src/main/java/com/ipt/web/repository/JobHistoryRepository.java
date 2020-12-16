package com.ipt.web.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import com.ipt.web.model.Job;
import com.ipt.web.model.MappedUser;

@Repository
public interface JobHistoryRepository extends JpaRepository<Job, Long>{
	
	//Job findById(Long id);

	//List<MappedUser> findAll();
	List<Job> findAll();
	
	@Query("select j from Job j where j.username = ?1 order by j.date_submitted desc")
	List<Job> findByUserName(String username);
	//@Query("select j from Job j where j.username = ?1")
	

	//void save(Comment comment);

	//void update(Comment comment);

	//void delete(Long id);


}
