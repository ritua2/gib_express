package com.ipt.web.service;

import java.util.List;

import com.ipt.web.model.Reply;

public interface ReplyService {

	Reply findById(Long id);

	List<Reply> findAll();

	void saveOrUpdate(Reply reply);

	void delete(Long id);

	List<Reply> findAllRepliesByparentId(Long parentId);
	
	void deleteAllRepliesByparentId(Long parentId);
}