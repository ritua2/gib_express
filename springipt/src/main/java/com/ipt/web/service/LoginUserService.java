package com.ipt.web.service;

import com.ipt.web.model.LoginUser;

public interface LoginUserService {
    void save(LoginUser loginUser);

    LoginUser findByUsername(String loginUser);
	
	void delete(LoginUser loginUser);
	
	LoginUser findByEmail (String email);
}
