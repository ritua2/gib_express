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

import java.io.*;
import java.lang.*;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Connection;

@Service
public class MappingService {
	
	String driverName = "com.mysql.cj.jdbc.Driver";
	String connectionUrl = null;
	String userId = null;
	String password = null;
	String table_name = null;
	
	Connection connection = null;
	Statement statement = null;
	ResultSet resultSet = null;
	int deleteCount=0;
		
		
	
	private void variableReader(){
		String okey=null, baseIP=null;
		File file = new File("/usr/local/tomcat/webapps/envar.txt");
		BufferedReader reader;
		try {
			reader = new BufferedReader(new FileReader(file));
			String line = reader.readLine();
			while (line != null) {
				if(line.contains("MYSQL_USER"))
					userId=line.substring(line.indexOf("=")+1);
				else if(line.contains("MYSQL_PASSWORD"))
					password=line.substring(line.indexOf("=")+1);
				else if(line.contains("MYSQL_CONN_URL"))
					connectionUrl=line.substring(line.indexOf("=")+1);
				else if(line.contains("MYSQL_TABLE"))
					table_name=line.substring(line.indexOf("=")+1);
				
				line = reader.readLine();
			}
			reader.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
		
	}
	
	public int deleteMappedUser(String user, String ip){
		variableReader();
		try {
			Class.forName(driverName);
			} catch (ClassNotFoundException e) {
			e.printStackTrace();
			}

		try{ 
				connection = DriverManager.getConnection(connectionUrl, userId, password);
				statement=connection.createStatement();
				String sql ="DELETE FROM "+table_name+" WHERE ip = '"+ip+ "' AND user = '" +user+"'"  ;

				deleteCount = statement.executeUpdate(sql);
				
			}catch (Exception e) {
				e.printStackTrace();
			}
		return deleteCount;
		
		}
		
		public String findMapping(String user){
			String ip = null;
		variableReader();
		try {
			Class.forName(driverName);
			} catch (ClassNotFoundException e) {
			e.printStackTrace();
			}

		try{ 
				connection = DriverManager.getConnection(connectionUrl, userId, password);
				statement=connection.createStatement();
				String sql ="SELECT ip FROM "+table_name+" WHERE user = '" +user+"'"  ;
				resultSet = statement.executeQuery(sql);
				while(resultSet.next()){
					if (!resultSet.next())
						ip="Null";
				}
				
			}catch (Exception e) {
				e.printStackTrace();
			}
		return ip;
		
		}
	}
	
	
	
