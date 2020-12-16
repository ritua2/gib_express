package com.ipt.web.service;
import java.io.IOException;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.File;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

import org.springframework.stereotype.Service;

import java.sql.Connection;

@Service
public class CurrentUserService {
	
	String driverName = "com.mysql.cj.jdbc.Driver";
	String connectionUrl = null;
	String userId = null;
	String password = null;
	String table_name = "current_users";
	
	Connection connection = null;
	Statement statement = null;
	ResultSet resultSet = null;
	int deleteCount=0;
	
	private void variableReader()
	{
		File file = new File("/usr/local/tomcat/webapps/envar.txt");
		BufferedReader reader;
		try 
		{
			reader = new BufferedReader(new FileReader(file));
			String line = reader.readLine();
			while (line != null) 
			{
				if(line.contains("MYSQL_USER"))
					userId=line.substring(line.indexOf("=")+1);
				else if(line.contains("MYSQL_PASSWORD"))
					password=line.substring(line.indexOf("=")+1);
				else if(line.contains("MYSQL_CONN_URL"))
					connectionUrl=line.substring(line.indexOf("=")+1);
				
				line = reader.readLine();
			}
			reader.close();
		} 
		catch (IOException e) 
		{
			e.printStackTrace();
		}
		
	}
	
	public int deleteCurrentUser(String user)
	{
		variableReader();
		try
		{
			Class.forName(driverName);
			connection = DriverManager.getConnection(connectionUrl, userId, password);
			statement=connection.createStatement();
			String sql ="DELETE FROM "+table_name+" WHERE username = '"+user+ "'";
			deleteCount = statement.executeUpdate(sql);				
		}
		catch (Exception e) 
		{
			e.printStackTrace();
		}
		return deleteCount;
		
	}

}
