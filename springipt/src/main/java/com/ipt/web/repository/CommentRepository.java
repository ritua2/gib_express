package com.ipt.web.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ipt.web.model.Comment;

@Repository
public interface CommentRepository extends JpaRepository<Comment, Long>{
	
	Comment findById(Long id);

	List<Comment> findAll();

	//void save(Comment comment);

	//void update(Comment comment);

	void delete(Long id);


}
