package com.ipt.web.service;

import java.util.List;

import com.ipt.web.model.Comment;

public interface CommentService {

	Comment findById(Long id);

	List<Comment> findAll();

	void saveOrUpdate(Comment comment);

	void delete(Long id);

}