package com.ipt.web.model;

import javax.persistence.*;

@Entity
@Table(name = "current_users")
public class CurrentUser {
	
	@Id
    private String username;
    private String user_type;
	
    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }
	
	public String getUser_type() {
        return user_type;
    }

    public void setUser_type(String user_type) {
        this.user_type = user_type;
    }
}
