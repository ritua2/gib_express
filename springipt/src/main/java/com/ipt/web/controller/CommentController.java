package com.ipt.web.controller;

import java.util.List;

import javax.servlet.http.HttpServletRequest;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import org.springframework.context.annotation.Scope;

import com.ipt.web.model.Comment;
import com.ipt.web.model.Reply;
import com.ipt.web.service.CommentService;
import com.ipt.web.service.ReplyService;

@Controller
public class CommentController {

	private final Logger logger = LoggerFactory.getLogger(CommentController.class);


	
	private CommentService commentService;
	private ReplyService replyService;

	

	@Autowired
	public void setCommentService(CommentService commentService) {
		this.commentService = commentService;
	}
	
	@Autowired
	public void setReplyService(ReplyService replyService) {
		this.replyService = replyService;
	}
	


	/*@RequestMapping(value = "/", method = RequestMethod.GET)
	public String index(Model model) {
		logger.debug("index()");
		//return "redirect:/users";
		return "template/login";
	}*/


	
	// list comments
		@RequestMapping(value = "/comments", method = RequestMethod.GET)
		public String showAllComments(Model model) {

			logger.debug("showAllComments()");
			
			List<Comment> comments = commentService.findAll();
			
			for (Comment comment : comments) {
				comment.setReplies(replyService.findAllRepliesByparentId(comment.getId()));
			}
			
			model.addAttribute("comments", comments);

			return "template/list";

		}

		// save or update reply
		@RequestMapping(value = "/comments/savereply", method = RequestMethod.POST)
		public String saveOrUpdateReply(@ModelAttribute("replyForm") @Validated Reply reply,
				BindingResult result, Model model, final RedirectAttributes redirectAttributes) {

			logger.debug("saveOrUpdateReply() : {}", reply);

			if (result.hasErrors()) {
				//populateDefaultModel(model);
				return "template/replyform";
			} else {

				redirectAttributes.addFlashAttribute("css", "success");
				if(reply.isNew()){
					redirectAttributes.addFlashAttribute("msg", "Reply added successfully!");
				}else{
					redirectAttributes.addFlashAttribute("msg", "Reply updated successfully!");
				}
				
				replyService.saveOrUpdate(reply);
				
				// POST/REDIRECT/GET
				return "redirect:/comments/" + reply.getParentId();

				// POST/FORWARD/GET
				// return "user/list";

			}
		}
	
		
		// save or update comments
		@RequestMapping(value = "/comments", method = RequestMethod.POST)
		public String saveOrUpdateComment(@ModelAttribute("commentForm") @Validated Comment comment,
				BindingResult result, Model model, final RedirectAttributes redirectAttributes) {

			System.out.println("saveOrUpdateComments() : {}"+ comment);

			if (result.hasErrors()) {
				//populateDefaultModel(model);
				return "template/commentform";
			} else {

				redirectAttributes.addFlashAttribute("css", "success");
				if(comment.isNew()){
					redirectAttributes.addFlashAttribute("msg", "Comment added successfully!");
				}else{
					redirectAttributes.addFlashAttribute("msg", "Comment updated successfully!");
				}
				
				commentService.saveOrUpdate(comment);
				
				// POST/REDIRECT/GET
				return "redirect:/comments/" + comment.getId();

				// POST/FORWARD/GET
				// return "user/list";

			}

		}


	// show add user form
	@RequestMapping(value = "/template/addcomment", method = RequestMethod.GET)
	public String showAddCommentForm(Model model) {

		logger.debug("showAddCommentForm()");

		Comment comment = new Comment();

		// set default value
		
		comment.setTitle("ipt123");
		comment.setBody("Your comment goes here...");
		comment.setTag("XYZ");
		

		model.addAttribute("commentForm", comment);

		return "template/commentform";

	}

	
	// show update comment form
	@RequestMapping(value = "/comments/{id}/update", method = RequestMethod.GET)
	public String showUpdateCommentForm(@PathVariable("id") Long id, Model model) {

		logger.debug("showUpdateCommentForm() : {}", id);

		Comment comment = commentService.findById(id);
		model.addAttribute("commentForm", comment);
		
		//populateDefaultModel(model);
		
		return "template/commentform";

	}
	
	// show reply comment form
	@RequestMapping(value = "/comments/{id}/reply", method = RequestMethod.GET)
	public String showAddReplyForm(@PathVariable("id") Long id, Model model) {

		logger.debug("showAddReplyForm() : {}", id);
		logger.debug("showAddReplyForm() : {}"+ id);

		Reply reply = new Reply();

		// set default value
		reply.setTitle("Reply Form");
		reply.setBody("Your comment goes here...");
		reply.setTag("ABC");
		reply.setParentId(id);

		model.addAttribute("replyForm", reply);

		return "template/replyform";
	}

	
	
	// delete comment
	@RequestMapping(value = "/comments/{id}/delete", method = RequestMethod.GET)
	public String deleteComment(@PathVariable("id") Long id, final RedirectAttributes redirectAttributes) {

		logger.debug("deleteComment() : {}", id);

		commentService.delete(id);
		
		redirectAttributes.addFlashAttribute("css", "success");
		redirectAttributes.addFlashAttribute("msg", "Comment is deleted!");
		
		return "redirect:/comments";
	}


	
	// show comment
	@RequestMapping(value = "/comments/{id}", method = RequestMethod.GET)
	public String showComment(@PathVariable("id") Long id, Model model) {

		logger.debug("showComment() id: {}", id);

		Comment comment = commentService.findById(id);
		comment.setReplies(replyService.findAllRepliesByparentId(comment.getId()));
		if (comment == null) {
			model.addAttribute("css", "danger");
			model.addAttribute("msg", "Comment not found");
		}
		model.addAttribute("comment", comment);

		return "template/show";

	}
/*	private void populateDefaultModel(Model model) {

		List<String> frameworksList = new ArrayList<String>();
		frameworksList.add("Spring MVC");
		frameworksList.add("Struts 2");
		frameworksList.add("JSF 2");
		frameworksList.add("GWT");
		frameworksList.add("Play");
		frameworksList.add("Apache Wicket");
		model.addAttribute("frameworkList", frameworksList);

		Map<String, String> skill = new LinkedHashMap<String, String>();
		skill.put("Hibernate", "Hibernate");
		skill.put("Spring", "Spring");
		skill.put("Struts", "Struts");
		skill.put("Groovy", "Groovy");
		skill.put("Grails", "Grails");
		model.addAttribute("javaSkillList", skill);

		List<Integer> numbers = new ArrayList<Integer>();
		numbers.add(1);
		numbers.add(2);
		numbers.add(3);
		numbers.add(4);
		numbers.add(5);
		model.addAttribute("numberList", numbers);

		Map<String, String> country = new LinkedHashMap<String, String>();
		country.put("US", "United Stated");
		country.put("CN", "China");
		country.put("SG", "Singapore");
		country.put("MY", "Malaysia");
		model.addAttribute("countryList", country);

	}*/

	@ExceptionHandler(EmptyResultDataAccessException.class)
	public ModelAndView handleEmptyData(HttpServletRequest req, Exception ex) {

		logger.debug("handleEmptyData()");
		logger.error("Request: {}, error ", req.getRequestURL(), ex);

		ModelAndView model = new ModelAndView();
		model.setViewName("template/comment");
		model.addObject("msg", "user not found");

		return model;

	}

}