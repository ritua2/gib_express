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
import com.ipt.web.model.MappedUser;
import com.ipt.web.model.Reply;
import com.ipt.web.repository.MappingRepository;
import com.ipt.web.service.CommentService;
import com.ipt.web.service.ReplyService;

@Controller
public class AdminController {

	private final Logger logger = LoggerFactory.getLogger(CommentController.class);
	
	private CommentService commentService;
	private ReplyService replyService;
	
	@Autowired
    private MappingRepository mappingRepository;
	
	// list logged in users
		@RequestMapping(value = "/admin", method = RequestMethod.GET)
		public String showAllProcesses(Model model) {

			List<MappedUser> users = mappingRepository.findAll();
			
			
			
			model.addAttribute("users", users);

			return "userList";

		}

	
	// delete comment
	@RequestMapping(value = "/admin/{user}/{ip}/delete", method = RequestMethod.GET)
	public String deleteComment(@PathVariable("user") String user, @PathVariable("ip") String ip,final RedirectAttributes redirectAttributes) {
		
		com.ipt.web.service.WaitService.freeInstance(user,ip);
		
		int deleteCount = new com.ipt.web.service.MappingService().deleteMappedUser(user, ip);
		
		if(deleteCount==1){
			redirectAttributes.addFlashAttribute("css", "success");
			redirectAttributes.addFlashAttribute("msg", "User is deleted!");
		}else{
			redirectAttributes.addFlashAttribute("css", "Failure!!!");
			redirectAttributes.addFlashAttribute("msg", "Error in deleting user!!!"); 
		} 
		return "redirect:/admin";
	}



	@ExceptionHandler(EmptyResultDataAccessException.class)
	public ModelAndView handleEmptyData(HttpServletRequest req, Exception ex) {

		

		ModelAndView model = new ModelAndView();
		model.setViewName("template/comment");
		model.addObject("msg", "User not found");

		return model;

	}

}