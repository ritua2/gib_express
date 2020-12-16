package com.ipt.web.service;

import com.ipt.web.controller.LoginUserController;
import com.ipt.web.model.LoginUser;
import com.ipt.web.model.MappedUser;
import com.ipt.web.repository.MappingRepository;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.File;
import java.net.*;
import java.util.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Scope;
import org.springframework.stereotype.Component; 
import org.springframework.stereotype.Controller;
import org.springframework.beans.factory.annotation.Configurable;
import org.springframework.stereotype.Service;

@Service
public class WaitService {
	
	@Autowired
    private static MappingRepository mappingRepository;
	
	private static String keyReader(){
		String okey=null, baseIP=null;
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
		return okey;
	}
	
	private static String IPReader(){
		String baseIP=null;
		File file = new File("/usr/local/tomcat/webapps/envar.txt");
		BufferedReader reader;
		try {
			reader = new BufferedReader(new FileReader(file));
			String line = reader.readLine();
			while (line != null) {
				if(line.contains("URL_BASE"))
					baseIP=line.substring(line.indexOf("=")+1);
				
				line = reader.readLine();
			}
			reader.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return baseIP;
	}
	
    public static void wait(String username){
		
		URL url = null;
		String jsonInputString=null;
		StringBuilder result = new StringBuilder();
		
		
		
		try{
			url = new URL("http://"+IPReader()+":5000/api/users/container_wait");
			HttpURLConnection conn = (HttpURLConnection) url.openConnection();
			conn.setRequestMethod("POST");
			conn.setRequestProperty("Content-Type", "application/json; utf-8");
			conn.setDoOutput(true);
			
			jsonInputString = "{\"key\":\""+keyReader()+"\", \"username\":\""+username+"\"}";
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
			File file = new File("Wait.txt");
			FileWriter fileWriter = new FileWriter(file);
			fileWriter.write(result.toString());
			fileWriter.flush();
			fileWriter.close();
		}catch(IOException e){
			e.printStackTrace();
			}}
			/*if(result.toString().equals("False")){
				ip_returned="False";
			}else{
				ip_returned=result.toString();
			}*/
		}catch(MalformedURLException e){
			e.printStackTrace();
		}catch(ProtocolException e){
			e.printStackTrace();
		}catch(IOException e){
			e.printStackTrace();
		}
	}
	
	public static String returnWaitKey(String username){
		
		URL url = null;
		String jsonInputString=null, key=null;
		StringBuilder result = new StringBuilder();
		
		
		
		try{
			url = new URL("http://"+IPReader()+":5000/api/users/wetty_wait_key");
			HttpURLConnection conn = (HttpURLConnection) url.openConnection();
			conn.setRequestMethod("POST");
			conn.setRequestProperty("Content-Type", "application/json; utf-8");
			conn.setDoOutput(true);
			
			jsonInputString = "{\"key\":\""+keyReader()+"\", \"username\":\""+username+"\"}";
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
			File file = new File("Key.txt");
			FileWriter fileWriter = new FileWriter(file);
			fileWriter.write(result.toString());
			fileWriter.flush();
			fileWriter.close();
		}catch(IOException e){
			e.printStackTrace();
			}}
			if(result.toString().equals("False")){
				key="False";
			}else{
				key=result.toString();
			}
		}catch(MalformedURLException e){
			e.printStackTrace();
		}catch(ProtocolException e){
			e.printStackTrace();
		}catch(IOException e){
			e.printStackTrace();
		}
		
		return key;
	}
	
	public static void freeInstance(String user, String IPandPort){
		
		MappedUser mappedUser = new MappedUser();
		URL url = null;
		String jsonInputString=null, key=null;
		StringBuilder result = new StringBuilder();
		
		
				
		try{
			url = new URL("http://"+IPReader()+":5000/api/instance/free");
			HttpURLConnection conn = (HttpURLConnection) url.openConnection();
			conn.setRequestMethod("POST");
			conn.setRequestProperty("Content-Type", "application/json; utf-8");
			conn.setDoOutput(true);
			
			jsonInputString = "{\"key\":\""+keyReader()+"\", \"IP\":\""+IPandPort.substring(0,IPandPort.indexOf(":"))+"\",\"Port\":\""+IPandPort.substring(IPandPort.indexOf(":")+1)+"\"}";
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
			File file = new File("Release.txt");
			FileWriter fileWriter = new FileWriter(file);
			fileWriter.write(result.toString());
			fileWriter.write("\n");
			fileWriter.write("User: "+user);
			fileWriter.write("\n");
			fileWriter.write("JSON: "+jsonInputString);
			fileWriter.write("\n");
			fileWriter.write("IP: "+IPandPort.substring(0,IPandPort.indexOf(":")));
			fileWriter.write("\n");
			fileWriter.write("Port: "+IPandPort.substring(IPandPort.indexOf(":")+1));
			fileWriter.write("\n");
			fileWriter.flush();
			fileWriter.close();
		}catch(IOException e){
			e.printStackTrace();
			}}
			/*if(result.toString().equals("False")){
				key="False";
			}else{
				key=result.toString();
			}*/
		}catch(MalformedURLException e){
			e.printStackTrace();
		}catch(ProtocolException e){
			e.printStackTrace();
		}catch(IOException e){
			e.printStackTrace();
		}
	}
	
	
}