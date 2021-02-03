package com.ipt.web.controller;

import java.util.*;

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
import com.ipt.web.model.Job;
import com.ipt.web.model.MappedUser;
import com.ipt.web.model.Reply;
import com.ipt.web.repository.JobHistoryRepository;
import com.ipt.web.service.CommentService;
import com.ipt.web.service.ReplyService;

@Controller
public class MainController {

		
	@Autowired
    private JobHistoryRepository jobHistoryRepository;
	
		//Under construction
		@RequestMapping(value = "/jobHistory", method = RequestMethod.GET)
		public String showJobHistory(Model model, HttpServletRequest request) {

			//List<Job> jobs = jobHistoryRepository.findAll();

			List<Job> jobs = null;
			if(request.getSession().getAttribute("is_cilogon").toString()=="true")
			jobs = jobHistoryRepository.findByUserName(request.getSession().getAttribute("curusername").toString());
			else
			jobs = jobHistoryRepository.findByUserName(request.getUserPrincipal().getName());
			//List<MappedUser> jobs = jobHistoryRepository.findAll();
			//List<Job> jobs = new ArrayList<Job>();
			model.addAttribute("jobs", jobs);
			return "jobHistory";

		}
		//Under construction
		@RequestMapping(value = "/help", method = RequestMethod.GET)
		public String showHelp(Model model) {

			
			return "help";

		}
		
		@RequestMapping(value = "/aboutus", method = RequestMethod.GET)
		public String showAboutUs(Model model) {

			
			return "about-us";

		}
		
		@RequestMapping(value = "/faq", method = RequestMethod.GET)
		public String showFaq(Model model) {

			
			return "faq";

		}
		
		@RequestMapping(value = "/vdemos", method = RequestMethod.GET)
		public String showVDemo(Model model) {

			
			return "vdemos";

		}
		
		@RequestMapping(value = "/contactus", method = RequestMethod.GET)
		public String showContactUs(Model model) {

			
			return "contactus";

		}
		
		@RequestMapping(value = "/accessDenied", method = RequestMethod.GET)
		public String accessDenied(){
			return "accessDenied";
		}
	
		@RequestMapping(value = "/pagenotfound", method = RequestMethod.GET)
		public String pagenotfound(){
			return "pagenotfound";
		}
		
		@RequestMapping(value = "/forgotPassword", method = RequestMethod.GET)
		public String showForgotPassword(Model model) {
			return "forgotPassword";
		}

	

}
