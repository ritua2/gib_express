package com.ipt.web.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import com.ipt.web.model.UnconfirmedUser;
import com.ipt.web.repository.RoleRepository2;
import com.ipt.web.repository.UnconfirmedUserRepository;

@Service
public class UserServiceImpl implements UserService {
    @Autowired
    private UnconfirmedUserRepository unconfirmedUserRepository;
	
	@Autowired
    private BCryptPasswordEncoder bCryptPasswordEncoder;
    
	
	@Autowired
    private RoleRepository2 roleRepository;

    @Override
    public void save(UnconfirmedUser user) {
		user.setPassword(bCryptPasswordEncoder.encode(user.getPassword()));
        user.setRole(roleRepository.findOne(1L));
    	unconfirmedUserRepository.save(user);
    }

    @Override
    public UnconfirmedUser findByUsername(String username) {
        return unconfirmedUserRepository.findByUsername(username);
    }
}
