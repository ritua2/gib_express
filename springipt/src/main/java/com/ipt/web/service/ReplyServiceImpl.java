package com.ipt.web.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.ipt.web.model.Reply;
import com.ipt.web.repository.ReplyRepository;

@Service("replyService")
public class ReplyServiceImpl implements ReplyService {


	@Autowired
    private ReplyRepository replyDao;

	@Autowired
	public void setReplyDao(ReplyRepository replyDao) {
		this.replyDao = replyDao;
	}

	@Override
	public Reply findById(Long id) {
		return replyDao.findOne(id);
	}

	@Override
	public List<Reply> findAll() {
		return replyDao.findAll();
	}

	@Override
	public void saveOrUpdate(Reply reply) {
		
		replyDao.save(reply);

		/*if (findById(reply.getComment().getId()) == null) {
			replyDao.save(reply);
		} else {
			replyDao.update(reply);
		}
*/
	}

	@Override
	public void delete(Long id) {
		replyDao.delete(id);
	}

	@Override
	public List<Reply> findAllRepliesByparentId(Long parentId) {
		// TODO Auto-generated method stub
		return replyDao.findAllRepliesByparentId(parentId);
	}

	@Override
	public void deleteAllRepliesByparentId(Long parentId) {
		// TODO Auto-generated method stub
		replyDao.deleteAllRepliesByparentId(parentId);
	}

}