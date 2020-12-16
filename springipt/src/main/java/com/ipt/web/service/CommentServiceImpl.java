package com.ipt.web.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.ipt.web.model.Comment;
import com.ipt.web.repository.CommentRepository;

@Service("commentService")
public class CommentServiceImpl implements CommentService {

    @Autowired
    private CommentRepository commentDao;

	@Autowired
	public void setCommentDao(CommentRepository commentDao) {
		this.commentDao = commentDao;
	}

	@Override
	public Comment findById(Long id) {
		return commentDao.findById(id);
	}

	@Override
	public List<Comment> findAll() {
		return commentDao.findAll();
	}

	@Override
	public void saveOrUpdate(Comment comment) {

		commentDao.save(comment);
	/*	if (findById(comment.getId()) == null) {
			commentDao.save(comment);
		} else {
			commentDao.update(comment);
		}*/
	}

	@Override
	public void delete(Long id) {
		commentDao.delete(id);
	}

}