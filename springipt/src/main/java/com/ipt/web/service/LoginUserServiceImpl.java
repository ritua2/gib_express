package com.ipt.web.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import com.ipt.web.model.LoginUser;
import com.ipt.web.repository.RoleRepository;
import com.ipt.web.repository.UserRepository;

@Service
public class LoginUserServiceImpl implements LoginUserService {
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private RoleRepository roleRepository;
    @Autowired
    private BCryptPasswordEncoder bCryptPasswordEncoder;

    @Override
    public void save(LoginUser loginUser) {
		loginUser.setRole(roleRepository.findOne(1L));
        userRepository.save(loginUser);
    }

    @Override
    public LoginUser findByUsername(String loginUsername) {
        return userRepository.findByUsername(loginUsername);
    }
	
	@Override
    public void delete(LoginUser loginUser) {
    	userRepository.delete(loginUser);
    }
	
	@Override
	public LoginUser findByEmail(String email) {
		return userRepository.findByEmail(email);
	}
}
