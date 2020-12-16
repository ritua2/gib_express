package com.ipt.web.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.ipt.web.model.Reply;

public interface ReplyRepository extends JpaRepository<Reply, Long>{
	
	public List<Reply> findAllRepliesByparentId(Long parentId);

	public void deleteAllRepliesByparentId(Long parentId);

}
