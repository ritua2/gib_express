package com.ipt.web.controller;
import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.OutputStream;
import java.io.FileNotFoundException;
import java.lang.Exception;
import java.net.*;
import java.security.Principal;
import java.util.*; 
import javax.inject.Inject;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Scope;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.ipt.web.model.CurrentUser;
import com.ipt.web.model.LoginUser;
import com.ipt.web.model.MappedUser;
import com.ipt.web.model.UnconfirmedUser;
import com.ipt.web.repository.CurrentUserRepository;
import com.ipt.web.repository.UserRepository;
import com.ipt.web.repository.MappingRepository;
import com.ipt.web.repository.RoleRepository;
import com.ipt.web.repository.UnconfirmedUserRepository;

import com.ipt.web.service.LoginUserService;
import com.ipt.web.service.UserService;
import com.ipt.web.service.SecurityService;
import com.ipt.web.validator.LoginUserValidator;
import com.ipt.web.validator.UnconfirmedUserValidator;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import com.ipt.web.service.SesListener;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

@Controller
  @Scope("session")
  public class LoginUserController {
    @Autowired
    private LoginUserService loginUserService;
    
    @Autowired
      private UserService userService;
    
    @Autowired
      private SecurityService securityService;
    
    @Autowired
      private LoginUserValidator userValidator;
    
    @Autowired
      private UnconfirmedUserValidator unconfirmedUserValidator;
    
    @Autowired
      private UserRepository userRepository;
    
    @Autowired
      private RoleRepository roleRepository;
    
    @Autowired
      private UnconfirmedUserRepository unconfirmedUserRepository;
    
    @Autowired
      private CurrentUserRepository currentUserRepository;
    
    @Autowired
      private MappingRepository mappingRepository;
    
    //@Autowired
    //private LoginUser loginUser;
    
    private String ip_returned=null;
    
    public static MappedUser mappedUser=new MappedUser();
    private File file1 = new File("Output1.txt");
    
    @GetMapping(value = "/registration")
      public String registration(Model model) {
        model.addAttribute("userForm", new UnconfirmedUser());
        
        return "registration";
      }
    
    @PostMapping(value = "/registration")
      public String registration(@ModelAttribute("userForm") UnconfirmedUser userForm, BindingResult bindingResult, Model model) {
        
        String jsonInputString=null, okey=null, baseIP=null;
        BufferedReader reader=null;
        URL url = null;
        StringBuilder result = new StringBuilder();
        
        //userValidator.validate(userForm, bindingResult);
        unconfirmedUserValidator.validate(userForm, bindingResult);
        
        
        
        if (bindingResult.hasErrors()) {
          return "registration";
        }
        
        try {
          File envar = new File("/usr/local/tomcat/webapps/envar.txt");
          reader = new BufferedReader(new FileReader(envar));
          String line = reader.readLine();
          while (line != null) {
            if(line.contains("orchestra_key"))
              okey=line.substring(line.indexOf("=")+1);
            else if(line.contains("URL_BASE"))
              baseIP=line.substring(line.indexOf("=")+1);
            line = reader.readLine();
          }
          reader.close();
        } catch (IOException e) {
          e.printStackTrace();
        }
        
        String token = UUID.randomUUID().toString();
        //userForm.setValidation_state("no");
        userForm.setValidation_key(token);
        
        //loginUserService.save(userForm);
        userService.save(userForm);
        
        
        final String confirmationUrl = "http://"+baseIP+":9090/registrationConfirmation?user="+userForm.getUsername()+"&token="+token;
        //final String confirmationUrl = "https://iptweb.tacc.utexas.edu/registrationConfirmation?user="+userForm.getUsername()+"&token="+token;
        
        //String message= "Welcome to GIB,"+"\\n"+"\\n"+"Thank you for registering!"+"\\n"+"\\n"+"Please verify your email by clicking or copying the following link into your browser's search bar: "+confirmationUrl;
        String message= "Welcome to the IPT Web Portal!"+"\\n"+"\\n"+"Thank you for registering!"+"\\n"+"\\n"+"Please verify your email by clicking or copying the following link into your browser's search bar: "+confirmationUrl;
        
        
        try{
          jsonInputString = "{\"key\":\""+okey+"\",\"subject\":\"Registration Confirmation for "+userForm.getUsername()+"\", \"email_address\": \""+userForm.getEmail()+"\", \"text\":\""+message+"\"}"; 
          
          url = new URL("http://"+baseIP+":5000/api/email/send");
        } catch(MalformedURLException e){
          e.printStackTrace();
        } catch (IOException e) {
          e.printStackTrace();
        } 	
        
        try{
          
          HttpURLConnection conn = (HttpURLConnection) url.openConnection();
          conn.setRequestMethod("POST");
          conn.setRequestProperty("Content-Type", "application/json; utf-8");
          conn.setDoOutput(true);
          
          File file4 = new File("EmailValidation_submit.txt");
          
          FileWriter fileWriter = new FileWriter(file4);
          
          fileWriter.write("\n");
          fileWriter.write("Base IP: "+ baseIP);
          fileWriter.write("\n");
          fileWriter.write("Message: "+ message);
          fileWriter.write("\n");
          fileWriter.write("URL: "+ url.toString());
          fileWriter.write("\n");
          fileWriter.write("\n");
          fileWriter.write(jsonInputString);
          fileWriter.write("\n");
          fileWriter.flush();
          fileWriter.close();
          
          try(OutputStream os = conn.getOutputStream()) {
            byte[] input = jsonInputString.getBytes("utf-8");
            os.write(input, 0, input.length);           
          }
          BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
          String line;
          while ((line = rd.readLine()) != null) {
            result.append(line);
          }
          rd.close();
          
          try{
            File file3 = new File("ValidationResult.txt");
            FileWriter fileWriter2 = new FileWriter(file3);
            fileWriter2.write(result.toString());
            fileWriter2.write("\n");
            fileWriter2.flush();
            fileWriter2.close();
          }catch(IOException e){
            e.printStackTrace();
          }
          
        }catch(ProtocolException e){
          e.printStackTrace();
        }catch(IOException e){
          e.printStackTrace();
        }
        
        // Creates the user directory
        new File("/home/greyfish/users/sandbox/DIR_"+userForm.getUsername()).mkdirs();
        new File("/home/greyfish/users/sandbox/DIR_"+userForm.getUsername()+"/home").mkdirs();
        new File("/home/greyfish/users/sandbox/DIR_"+userForm.getUsername()+"/home/gib").mkdirs();
        new File("/home/greyfish/users/sandbox/DIR_"+userForm.getUsername()+"/home/gib/home").mkdirs();
        new File("/home/greyfish/users/sandbox/DIR_"+userForm.getUsername()+"/home/gib/home/gib").mkdirs();
        //securityService.autologin(userForm.getUsername(), userForm.getPasswordConfirm());
        
        //return "redirect:/welcome";
        return "redirect:/sentlink";
      }
    
    @GetMapping(value = "/sentlink")
      public String sentLink() {
        
        return "sentlink";
      }
    
    @GetMapping(value = "/registrationConfirmation")
      public String registrationConfirmation(@RequestParam("user") String userName, @RequestParam("token") String code) {
        
        //Boolean check=false;
        //check=null == auth.getPrincipal();
        
        try{
          File file3 = new File("Valid_Link.txt");
          FileWriter fileWriter2 = new FileWriter(file3);
          fileWriter2.write("\n");
          fileWriter2.write(userName);
          fileWriter2.write("\n");
          fileWriter2.write(code);
          fileWriter2.write("\n");
          fileWriter2.flush();
          fileWriter2.close();
        }catch(IOException e){
          e.printStackTrace();
        }
        
        if(unconfirmedUserRepository.findByUsername(userName)!=null){
          if(unconfirmedUserRepository.findByUsername(userName).getValidation_key().equals(code)){
            LoginUser lu= new LoginUser();
            lu.setId(unconfirmedUserRepository.findByUsername(userName).getId());
            lu.setUsername(unconfirmedUserRepository.findByUsername(userName).getUsername());
            lu.setEmail(unconfirmedUserRepository.findByUsername(userName).getEmail());
            lu.setName(unconfirmedUserRepository.findByUsername(userName).getName());
            lu.setInstitution(unconfirmedUserRepository.findByUsername(userName).getInstitution());
            lu.setCountry(unconfirmedUserRepository.findByUsername(userName).getCountry());
            lu.setPassword(unconfirmedUserRepository.findByUsername(userName).getPassword());
            //lu.setPasswordConfirm(unconfirmedUserRepository.findByUsername(userName).getPassword());
            lu.setRole(roleRepository.findOne(1L));
            userRepository.save(lu);
            unconfirmedUserRepository.delete(unconfirmedUserRepository.findByUsername(userName));
            return "registrationConfirmation2";
          }else{
            if(unconfirmedUserRepository.findByUsername(userName)!=null)
              unconfirmedUserRepository.delete(unconfirmedUserRepository.findByUsername(userName));
            return "registrationError";
          }
        }else
          return "registrationError";
      }
    
    /*@GetMapping(value = "/registrationConfirmation")
    public String registrationConfirmation(@RequestParam("user") String userName, @RequestParam("token") String code, Authentication auth, HttpServletRequest request) {
    
    Boolean check=false;
    check=null == auth.getPrincipal();
    
    try{
    File file3 = new File("Valid_Link.txt");
    FileWriter fileWriter2 = new FileWriter(file3);
    fileWriter2.write("\n");
    fileWriter2.write(userName);
    fileWriter2.write("\n");
    fileWriter2.write(code);
    fileWriter2.write("\n");
    fileWriter2.flush();
    fileWriter2.close();
    }catch(IOException e){
    e.printStackTrace();
    }
    
    if(loginUserService.findByUsername(userName).getValidation_key().equals(code)){
    LoginUser lu=loginUserService.findByUsername(userName);
    lu.setValidation_state("verified");
    loginUserService.save(lu);
    if(!check)
    return "registrationConfirmation1";
    else
    return "registrationConfirmation2";
    }else{
    loginUserService.delete(loginUserService.findByUsername(userName));
    HttpSession session = request.getSession(true);
    session.invalidate();
    return "registrationError";
    }
    
    }*/
    
    
    
    
    /*@GetMapping(value = "/login")
    public String login(Model model, String error, String logout, HttpServletRequest request) { 
    
    RequestAttributes attribs = RequestContextHolder.getRequestAttributes();
    HttpServletRequest request1=null;
    
    if (RequestContextHolder.getRequestAttributes() != null) {
    request1 = ((ServletRequestAttributes) attribs).getRequest();
    }
    
    
    try{
    File file4 = new File("Test.txt");
    FileWriter fileWriter = new FileWriter(file4);
    fileWriter.write("\n");
    fileWriter.write("Khwaab");
    //fileWriter.write("auth: "+SecurityContextHolder.getContext().getAuthentication().getDetails());
    fileWriter.write("\n");
    fileWriter.flush();
    fileWriter.close();
    }catch(IOException e){
    e.printStackTrace();
    }
    
    /*if (error != null)
    model.addAttribute("error", "Your username and password is invalid.");
    
    if (logout != null){
    model.addAttribute("name", logout);
    model.addAttribute("message", "You have been logged out successfully.");
    }*/	
    
    /*  return "redirect:/welcome";
    }*/
    @RequestMapping(value = "/test1")
      public void test1(HttpSession session, HttpServletRequest request) { 
        
        try{
          File file4 = new File("Abc.txt");
          FileWriter fileWriter = new FileWriter(file4);
          fileWriter.append("\n");
          fileWriter.append("LDAP User");
          fileWriter.append("\n");
          fileWriter.flush();
          fileWriter.close();
          
        }catch(IOException e){
          e.printStackTrace();
        }
      }
    @RequestMapping(value = "/test2")
      public void test2(HttpSession session, HttpServletRequest request) { 
        
        try{
          File file4 = new File("Abc2.txt");
          FileWriter fileWriter = new FileWriter(file4);
          fileWriter.append("\n");
          fileWriter.append("DB User");
          fileWriter.append("\n");
          fileWriter.flush();
          fileWriter.close();
        }catch(IOException e){
          e.printStackTrace();
        }
      }
    @GetMapping(value = "/entry")
      public String entry() {
        return "login_v7";
      }
    
    @GetMapping(value = "/login_normal")
      public String login_normal(Model model, String error, String logout) {
        
        if (error != null)
          model.addAttribute("error", "Your username and password is invalid.");
        
        if (logout != null){
          model.addAttribute("name", logout);
          model.addAttribute("message", "You have been logged out successfully.");
        }	
        
        
        return "login_normal";
      }
    
     @GetMapping(value = "/login_cilogon")
      public String login_cilogon(Model model, String error, String logout) {
	      String client_id="cilogon:/client_id/59a97b6d0be2e7f15032531bce7eb9aa";
	      String scope="openid+profile+email+org.cilogon.userinfo+edu.uiuc.ncsa.myproxy.getcert";
	      String redirect_uri="https://149.165.156.109:8443/welcome";
	      String redirecturl="https://cilogon.org/authorize/?response_type=code&client_id="+client_id+"&redirect_uri="+redirect_uri+"&scope="+scope;
	      return "redirect:" + redirecturl;
      }
    
    
    
    @GetMapping(value = "/perform_logout")
      public String logout1(HttpServletRequest request) {
        
        if(request.getSession().getAttribute("mySessionAttribute")!=null && !(request.getSession().getAttribute("mySessionAttribute").toString().contains("Error")))
	{
		if(request.getSession().getAttribute("is_cilogon").toString()=="true")
			com.ipt.web.service.WaitService.freeInstance(request.getSession().getAttribute("curusername").toString(),request.getSession().getAttribute("mySessionAttribute").toString());
		else
			com.ipt.web.service.WaitService.freeInstance(request.getUserPrincipal().getName(),request.getSession().getAttribute("mySessionAttribute").toString());
	}
        CurrentUser currentUser = new CurrentUser();
	if(request.getSession().getAttribute("is_cilogon").toString()=="true")
	{
		currentUser.setUsername(request.getSession().getAttribute("curusername").toString());
	}
	else
	{
		currentUser.setUsername(request.getUserPrincipal().getName().toString().replace(" ","_"));
	}
        currentUser.setUser_type(request.getSession().getAttribute("is_ldap").toString());
        
        currentUserRepository.delete(currentUser);
        
        HttpSession session = request.getSession(false);
        session.invalidate();
        
        return "redirect:/login?logout";
        
      }
    
    @GetMapping(value = {"/", "/welcome"})
      public String welcome(@RequestParam(defaultValue="empty") String code,HttpServletRequest request, Model model, HttpSession session, Principal principal, Authentication authentication) {
	
	Boolean is_cilogon=false;
        Boolean abc=false;
        Boolean is_ldap=false;
        Boolean check=false;
        check=null == principal;
 
        if(!code.equals("empty"))
	{
		System.out.println("Code :"+code);
		String client_id="cilogon:/client_id/59a97b6d0be2e7f15032531bce7eb9aa";
		String client_secret="7F9KZuY21mTUT2anuAxec4Ui4Sm75BBrPtAm5NqsFTlmws2hI0xLcYOFiXeWLqIc8k0UTl9MQF3HqDAFmbYdZw";
		String redirect_uri="https://149.165.156.109:8443/welcome";
		StringBuilder result2 = new StringBuilder();
		try{
			URL url=new URL("https://cilogon.org/oauth2/token?grant_type=authorization_code&client_id="+client_id+"&client_secret="+client_secret+"&code="+code+"&redirect_uri="+redirect_uri);
			HttpURLConnection conn = (HttpURLConnection)url.openConnection();
			conn.setRequestMethod("GET");
			BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
			String line=null;
			while ((line = rd.readLine()) != null) 
			{
				result2.append(line);
			}
			rd.close();
			String[] substr=result2.toString().split(",");
			String access_token=substr[0].substring(substr[0].indexOf(":")+2,substr[0].length()-1);
			//System.out.println("token:  "+access_token);

			url=new URL("https://cilogon.org/oauth2/userinfo?access_token="+access_token);
			conn = (HttpURLConnection)url.openConnection();
			conn.setRequestMethod("GET");
			rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
			line=null;
			while ((line = rd.readLine()) != null) 
			{
				result2.append(line);
			}
			rd.close();
			System.out.println("\n\nBefore info: ");
			substr=result2.toString().split(",");
			
			String name=null, email=null, institute=null;
			for(String tmp:substr) 
			{
				if(tmp.contains("\"name\""))
					name=tmp.substring(tmp.indexOf(":")+2,tmp.length()-1);
					//System.out.println("Name: "+name);
				if(tmp.contains("email"))
					email=tmp.substring(tmp.indexOf(":")+2,tmp.length()-2);
					//System.out.println("Email: "+email);
				if(tmp.contains("idp_name"))
					institute=tmp.substring(tmp.indexOf(":")+2,tmp.length()-1);
					//System.out.println("Institute: "+institute);
			}
			
			if((name == null) || (email == null)) return "loginwithother";
			String[] access_tokens=access_token.split("/");
			LoginUser lu = null;
			UnconfirmedUser uc = null;
			lu = loginUserService.findByEmail(email);
			uc = userService.findByEmail(email);
			String userName=email.substring(0,email.indexOf('@'))+email.substring(email.indexOf('@')+1,email.indexOf('@')+3);

			if((lu == null) && (uc == null))
			{
				uc = new UnconfirmedUser();
				uc.setUsername(userName);
				uc.setEmail(email);
				uc.setName(name);
				uc.setInstitution("InstitutionCIL");
				uc.setCountry("CountryCIL");
				uc.setPassword(access_tokens[access_tokens.length-1]);
				uc.setValidation_key("KeyCIL");
				userService.save(uc);
		
				if(unconfirmedUserRepository.findByUsername(userName)!=null)
				{
					lu= new LoginUser();
					lu.setId(unconfirmedUserRepository.findByUsername(userName).getId());
					lu.setUsername(unconfirmedUserRepository.findByUsername(userName).getUsername());
					lu.setEmail(unconfirmedUserRepository.findByUsername(userName).getEmail());
					lu.setName(unconfirmedUserRepository.findByUsername(userName).getName());
					lu.setInstitution(unconfirmedUserRepository.findByUsername(userName).getInstitution());
					lu.setCountry(unconfirmedUserRepository.findByUsername(userName).getCountry());
					lu.setPassword(unconfirmedUserRepository.findByUsername(userName).getPassword());
					lu.setRole(roleRepository.findOne(1L));
					userRepository.save(lu);
					unconfirmedUserRepository.delete(unconfirmedUserRepository.findByUsername(userName));
				}
				else return "registrationError";
			}
			else
			{
				if(uc != null)
				{
					return "accountexist";
				}
				else if(lu.getCountry().equals("CountryCIL"))
				{
					BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(12);
					lu.setPassword(encoder.encode(access_tokens[access_tokens.length-1]));
					userRepository.save(lu);
				}
				else
				{
					return "accountexist";
				}
			}	
			is_cilogon=true;
			session.setAttribute("curusername", userName.toString().replace(" ","_"));
                	session.setAttribute("is_ldap", is_ldap.toString());
                	session.setAttribute("is_cilogon", is_cilogon.toString());
			
			CurrentUser currentUser = new CurrentUser();
			currentUser.setUsername(userName.toString().replace(" ","_"));
			currentUser.setUser_type(is_ldap.toString());
			new File("/home/greyfish/users/sandbox/DIR_"+userName.toString().replace(" ","_")).mkdirs();
			new File("/home/greyfish/users/sandbox/DIR_"+userName.toString().replace(" ","_")+"/home").mkdirs();
			new File("/home/greyfish/users/sandbox/DIR_"+userName.toString().replace(" ","_")+"/home/gib").mkdirs();
			new File("/home/greyfish/users/sandbox/DIR_"+userName.toString().replace(" ","_")+"/home/gib/home").mkdirs();
			new File("/home/greyfish/users/sandbox/DIR_"+userName.toString().replace(" ","_")+"/home/gib/home/gib").mkdirs();
	
			currentUserRepository.save(currentUser);          
			return "welcome";
		}
		catch(MalformedURLException e){
			e.printStackTrace();
		}
		catch(IOException e){
			e.printStackTrace();
		}

	}
       
        if(!check){
          abc=request.isUserInRole("ROLE_ADMIN");
          session.setAttribute("is_admin", abc.toString());
          if(authentication.getPrincipal().toString().contains("Not granted any authorities")){
            if(authentication.getPrincipal().toString().substring(0,65).equals("org.springframework.security.ldap.userdetails.LdapUserDetailsImpl")){
              is_ldap=true;
              new File("/home/greyfish/users/sandbox/DIR_"+authentication.getName().toString().replace(" ","_")).mkdirs();
              new File("/home/greyfish/users/sandbox/DIR_"+authentication.getName().toString().replace(" ","_")+"/home").mkdirs();
              new File("/home/greyfish/users/sandbox/DIR_"+authentication.getName().toString().replace(" ","_")+"/home/gib").mkdirs();
              new File("/home/greyfish/users/sandbox/DIR_"+authentication.getName().toString().replace(" ","_")+"/home/gib/home").mkdirs();
              new File("/home/greyfish/users/sandbox/DIR_"+authentication.getName().toString().replace(" ","_")+"/home/gib/home/gib").mkdirs();
            }				
          }
          session.setAttribute("curusername", authentication.getName().toString().replace(" ","_"));
          session.setAttribute("is_ldap", is_ldap.toString());
          session.setAttribute("is_cilogon", is_cilogon.toString());           
          CurrentUser currentUser = new CurrentUser();
          currentUser.setUsername(authentication.getName().toString().replace(" ","_"));
          currentUser.setUser_type(is_ldap.toString());
          
          currentUserRepository.save(currentUser);
          
          
          
          return "welcome";
        }else 			
          return "redirect:/entry";
      }
    
    @GetMapping(value = "/terminal")
      public String terminal(Model model,HttpServletRequest request, HttpSession session, Authentication authentication) {
        
        String curl_output=null;
        String loggedin_user=null;
        String curl_output2=null;
        String newip=null;
        String baseIP0=null;
        
        File file0 = new File("/usr/local/tomcat/webapps/envar.txt");
        BufferedReader reader0;
        try {
          reader0 = new BufferedReader(new FileReader(file0));
          String line = reader0.readLine();
          while (line != null) {
            if(line.contains("URL_BASE"))
              baseIP0=line.substring(line.indexOf("=")+1);
            line = reader0.readLine();
          }
          reader0.close();
        } catch (IOException e) {
          e.printStackTrace();
        }
        
        if(session.getAttribute("is_ldap")=="true"){
          if(authentication.getName().toString().contains(" "))
            loggedin_user=authentication.getName().toString().replace(" ","_");
        }else if(session.getAttribute("is_cilogon")=="true"){
            loggedin_user=session.getAttribute("curusername").toString().replace(" ","_");	
	}else
          loggedin_user=request.getUserPrincipal().getName();
        
        
        if(session.getAttribute("mySessionAttribute")==null || ((session.getAttribute("mySessionAttribute")!=null)&& ((new com.ipt.web.service.MappingService().findMapping(loggedin_user))!="Null"))){
          
          
          StringBuilder result = new StringBuilder();
          StringBuilder result2 = new StringBuilder();
          
          URL url = null;
          String okey=null, jsonInputString=null, baseIP=null;
          
          File file = new File("/usr/local/tomcat/webapps/envar.txt");
          BufferedReader reader;
          try {
            reader = new BufferedReader(new FileReader(file));
            String line = reader.readLine();
            while (line != null) {
              if(line.contains("orchestra_key"))
                okey=line.substring(line.indexOf("=")+1);
              else if(line.contains("URL_BASE"))
                baseIP=line.substring(line.indexOf("=")+1);
              line = reader.readLine();
            }
            reader.close();
          } catch (IOException e) {
            e.printStackTrace();
          }
          
          //Principal principal = request.getUserPrincipal();
          
          try{
            url = new URL("http://"+baseIP+":5000/api/assign/users/"+loggedin_user);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; utf-8");
            conn.setDoOutput(true);
            
            jsonInputString = "{\"key\":\""+okey+"\", \"sender\":\"carlos\"}";
            try(OutputStream os = conn.getOutputStream()) {
              byte[] input = jsonInputString.getBytes("utf-8");
              os.write(input, 0, input.length);           
            }
            BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
            String line;
            //curl_output=abc;
            while ((line = rd.readLine()) != null) {
              result.append(line);
            }
            rd.close();
            if(result!=null){
              try{
                File file1 = new File("Assign.txt");
                FileWriter fileWriter = new FileWriter(file1);
                fileWriter.write(result.toString());
                fileWriter.write("\n");
                fileWriter.write("User:"+loggedin_user);
                fileWriter.write("\n");
                fileWriter.flush();
                fileWriter.close();
              }catch(IOException e){
                e.printStackTrace();
              }
            }
            if(result.toString().equals("False")){
              ip_returned="False";
            }else{
              ip_returned=result.toString();
            }
            
          }catch(MalformedURLException e){
            e.printStackTrace();
          }catch(ProtocolException e){
            e.printStackTrace();
          }catch(IOException e){
            e.printStackTrace();
          }
          
          if(ip_returned.equals("False")){
            curl_output="Error!!!";
            curl_output2="Error!!!";
          }else{
            try{
              url = new URL("http://"+baseIP+":5000/api/redirect/users/"+loggedin_user+"/"+ip_returned.substring(0,ip_returned.indexOf(':')));
              HttpURLConnection conn = (HttpURLConnection) url.openConnection();
              conn.setRequestMethod("GET");
              conn.setInstanceFollowRedirects( false );
              BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
              String line=null;;
              while ((line = rd.readLine()) != null) {
                result2.append(line);
              } 
              rd.close();
              if(result2!=null){
                try{
                  //Boolean abc=request.isUserInRole("ROLE_ADMIN");
                  File file2 = new File("Redirect.txt");
                  FileWriter fileWriter = new FileWriter(file2);
                  fileWriter.write(result2.toString());
                  //fileWriter.write(abc.toString());
                  fileWriter.flush();
                  fileWriter.close();
                }catch(IOException e){
                  e.printStackTrace();
                }
              }
              curl_output=result2.toString();
              
            }catch(MalformedURLException e){
              e.printStackTrace();
            }catch(ProtocolException e){
              e.printStackTrace();
            }catch(IOException e){
              e.printStackTrace();
            }	
            
            if(curl_output.contains("Redirecting")){
              //curl_output=curl_output.substring(curl_output.indexOf("https://")+8, curl_output.indexOf("/wetty"));
              curl_output=curl_output.substring(curl_output.indexOf("https://"));
              curl_output2 = curl_output;
              try{
                curl_output2= curl_output2.substring(8);
                curl_output2 = curl_output2.substring(0, curl_output2.indexOf("/"));
                File co2 = new File("curl_output2.txt");
                FileWriter fileWriter2 = new FileWriter(co2);
                fileWriter2.write(curl_output2.toString());
                fileWriter2.flush();
                fileWriter2.close();
                
                Runtime r = Runtime.getRuntime();
                String cmd = "nslookup " + curl_output2.substring(0, curl_output2.indexOf(":"));
                Process p = r.exec(cmd);
                p.waitFor();
                BufferedReader b = new BufferedReader(new InputStreamReader(p.getInputStream()));
                String line = "";
                File ipfromhostname = new File("ipfromhostname.txt");
                FileWriter fileWriter3 = new FileWriter(ipfromhostname);
                int count = 0;
                String tmp = "";
                while ((line = b.readLine()) != null) {
                  count++;
                  if(count == 6){
                    tmp = line;
                    fileWriter3.write(line);
                    tmp = tmp.replaceAll("Address:", " ");
                    tmp = tmp.trim();
                  }
                }
                fileWriter3.flush();
                fileWriter3.close();
                b.close();
                if (tmp != null){
                  File co4 = new File("curl_output4.txt");
                  FileWriter fileWriter4 = new FileWriter(co4);
                  tmp = tmp + curl_output2.substring(curl_output2.indexOf(":"));
                  curl_output2 = tmp;
                  fileWriter4.write(curl_output2.toString());
                  fileWriter4.flush();
                  fileWriter4.close();
                  
                }
              }catch (Exception e){
                try{
                  PrintWriter pw = new PrintWriter(new File("error_trace.txt"));
                  e.printStackTrace(pw);
                  pw.close();
                  //e.printStackTrace();
                }catch (FileNotFoundException ex)  
                {
                  ex.printStackTrace();
                }
              }
            }else{
              curl_output = "Error!! All the terminal instances are currently in use.";		
              curl_output2 = "Error!! All the terminal instances are currently in use."; 
            }
          }
          session.setAttribute("mySessionAttribute", curl_output2);
          mappedUser.setUser(loggedin_user);
          mappedUser.setIp(curl_output2);	
          session.setAttribute("uName", loggedin_user);
          session.setAttribute("uIP", curl_output2);
          session.setAttribute("newip", curl_output);
          mappingRepository.save(mappedUser);
          
          //List<MappedUser> list=mappingRepository.findAll();
          
        }else{
          //com.ipt.web.service.WaitService.wait(request.getUserPrincipal().getName());
          com.ipt.web.service.WaitService.wait(loggedin_user);
          
          //String str = com.ipt.web.service.WaitService.returnWaitKey(request.getUserPrincipal().getName());
          String str = com.ipt.web.service.WaitService.returnWaitKey(loggedin_user);
          if(session.getAttribute("key")==null && session.getAttribute("key1")==null){
            
            session.setAttribute("key1", str);
          }else{
            session.setAttribute("key", session.getAttribute("key1") );
            session.setAttribute("key1", str);
          }
          
        }
        try{
          model.addAttribute("ip", (String) session.getAttribute("mySessionAttribute"));
          model.addAttribute("baseip", baseIP0);
          
          model.addAttribute("newip", (String) session.getAttribute("newip"));
        }catch(Exception e){
          e.printStackTrace();
        }
        
        return "terminal";
      }
    
    @GetMapping(value = "/redirect")
      public String redirect(Model model, HttpSession session) {
        model.addAttribute("ip", (String) session.getAttribute("mySessionAttribute"));
        
        model.addAttribute("newip", (String) session.getAttribute("newip"));
        return "redirect";
      }
    
    
    @PostMapping(value = "/passwordReset2")
      public String passwordReset2(@RequestParam("password") String password, @RequestParam("username") String username) {
        
        LoginUser testuser = loginUserService.findByUsername(username);
        
        try{
          File file3 = new File("Setting_newPass.txt");
          FileWriter fileWriter2 = new FileWriter(file3);
          fileWriter2.write("\n");
          fileWriter2.write(username);
          fileWriter2.write("\n");
          //fileWriter2.write(password);
          fileWriter2.write("\n");
          fileWriter2.flush();
          fileWriter2.close();
        }catch(IOException e){
          e.printStackTrace();
        }
        
        if(testuser != null){
          BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(12);
          testuser.setPassword(encoder.encode(password));
          loginUserService.save(testuser);
          return "passwordReset2";
        }else{
          return "registrationError";
        } 
        
        
      }
    
    
    @GetMapping(value = "/passwordReset")
      public String passwordReset(@RequestParam("user") String username, @RequestParam("token") String token) {
        
        LoginUser testuser = loginUserService.findByUsername(username);
        
        try{
          File file3 = new File("Valid_User.txt");
          FileWriter fileWriter2 = new FileWriter(file3);
          fileWriter2.write("\n");
          fileWriter2.write(username);
          fileWriter2.write("\n");
          fileWriter2.write(token);
          fileWriter2.write("\n");
          fileWriter2.write(testuser.getValidation_key());
          fileWriter2.write("\n");
          fileWriter2.flush();
          fileWriter2.close();
        }catch(IOException e){
          e.printStackTrace();
        }
        
        if(token.equals(testuser.getValidation_key()) ){
          return "passwordReset";
        }else{
          return "registrationError";
          
        }
      }    
    
    @PostMapping(value = "/forgotPassword")
      public String resetPassword(Model model, @RequestParam("email") String email, HttpServletRequest request) {
        LoginUser existingUser = loginUserService.findByEmail(email);
        String jsonInputString=null, okey=null, baseIP=null;
        BufferedReader reader=null;
        URL url = null;
        StringBuilder result = new StringBuilder();
        if (existingUser != null) {
          
          try{
            File file44 = new File("password_reset.txt");
            
            FileWriter fileWriter44 = new FileWriter(file44);
            
            fileWriter44.write("\n");
            fileWriter44.write("Username is: "+ existingUser.getUsername());
            
            fileWriter44.write("\n");
            
            try {
              File envar = new File("/usr/local/tomcat/webapps/envar.txt");
              reader = new BufferedReader(new FileReader(envar));
              String line = reader.readLine();
              while (line != null) {
                if(line.contains("orchestra_key"))
                  okey=line.substring(line.indexOf("=")+1);
                else if(line.contains("URL_BASE"))
                  baseIP=line.substring(line.indexOf("=")+1);
                line = reader.readLine();
              }
              reader.close();
            } catch (IOException e) {
              e.printStackTrace();
            }
            
            String token = UUID.randomUUID().toString();
            existingUser.setValidation_key(token);
            loginUserService.save(existingUser);
            
            //final String confirmationUrl = "https://iptweb.tacc.utexas.edu/passwordReset?user="+existingUser.getUsername()+"&token="+token;
            final String confirmationUrl = "http://"+baseIP+":9090/passwordReset?user="+existingUser.getUsername()+"&token="+token;
            String message= "Please verify your email for resetting the IPT web portal password by clicking or copying the following link into your browser's search bar: "+confirmationUrl;
            
            fileWriter44.write("Message is: "+ message);
            
            
            fileWriter44.write("\n");
            
            try{
              jsonInputString = "{\"key\":\""+okey+"\",\"subject\":\"Password reset confirmation for "+existingUser.getUsername()+"\", \"email_address\": \""+existingUser.getEmail()+"\", \"text\":\""+message+"\"}";
              
              url = new URL("http://"+baseIP+":5000/api/email/send");
            } catch(MalformedURLException e){
              e.printStackTrace();
            } catch (IOException e) {
              e.printStackTrace();
            }
            
            fileWriter44.flush();
            fileWriter44.close();
          }catch (Exception e){
            
          }
          
        }
        
        if (existingUser != null) {
          
          try{
            
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; utf-8");
            conn.setDoOutput(true);
            
            try(OutputStream os = conn.getOutputStream()) {
              byte[] input = jsonInputString.getBytes("utf-8");
              os.write(input, 0, input.length);
            }
            BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
            String line;
            while ((line = rd.readLine()) != null) {
              result.append(line);
            }
            rd.close();
            
            
          }catch (Exception e){
            e.printStackTrace();
          } 
          
          
        }
        return "redirect:/sentlink";
      }
    }
