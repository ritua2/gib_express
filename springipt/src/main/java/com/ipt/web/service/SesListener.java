package com.ipt.web.service;
import javax.servlet.*;
import javax.servlet.http.*;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import javax.servlet.annotation.WebListener;
import javax.servlet.http.HttpSessionListener;
import com.ipt.web.model.MappedUser;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.context.request.ServletRequestAttributes;
import org.springframework.web.context.request.RequestContextHolder;
import javax.servlet.http.HttpServletRequest;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.RequestContextHolder;
import java.util.*; 
import com.ipt.web.controller.LoginUserController;
import java.io.*;
import java.lang.*;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Connection;


@WebListener
public class SesListener implements HttpSessionListener {
	
	String user=null, ip=null;
	//public MappedUser mappedUser = new MappedUser();
	
	
	@Override	
  public void sessionCreated(HttpSessionEvent se) {
	  
	try{
			File file = new File("Created.txt");
			FileWriter fileWriter = new FileWriter(file);
			fileWriter.write("\n");
			/*if(mappedUser.getUser()==null){
				do{fileWriter.write(mappedUser.getUser());}while(mappedUser.getUser()==null);
			}else
				fileWriter.write(mappedUser.getUser());*/
			
			fileWriter.write("\n");
			fileWriter.flush();
			fileWriter.close();
		}catch(IOException e){
			e.printStackTrace();
			}
	
  }
  
	@Override
  public void sessionDestroyed(HttpSessionEvent se) {
		
		int deleteCount = 0;
	    
		if(se.getSession().getAttribute("curusername")!=null)
        {
			deleteCount =  new com.ipt.web.service.CurrentUserService().deleteCurrentUser(se.getSession().getAttribute("curusername").toString());
        }
		
   		if(se.getSession().getAttribute("uIP")!=null)
   		{
   			
   		 if(!(se.getSession().getAttribute("uIP").toString().contains("Error")))
   		 {
   			 com.ipt.web.service.WaitService.freeInstance(se.getSession().getAttribute("uName").toString(),se.getSession().getAttribute("uIP").toString());
   		 }
   		 deleteCount =  new com.ipt.web.service.MappingService().deleteMappedUser(se.getSession().getAttribute("uName").toString(), se.getSession().getAttribute("uIP").toString());
   		 try
		 {
			 File file = new File("Destroyed.txt");
			 FileWriter fileWriter = new FileWriter(file);
			 fileWriter.write("\n");
			 fileWriter.write("Session destroyed...");
			 fileWriter.write("\n");
			 fileWriter.write(deleteCount);
			 fileWriter.write("\n");
			 fileWriter.write("Session destroyed...");
			 fileWriter.write("\n");
			 fileWriter.flush();
			 fileWriter.close();
		 }
		 catch(IOException e)
		 {
			 e.printStackTrace();
		 }
   		 
   		}
}
}