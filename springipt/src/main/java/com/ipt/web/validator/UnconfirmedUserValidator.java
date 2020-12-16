package com.ipt.web.validator;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;


import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.validation.Errors;
import org.springframework.validation.ValidationUtils;
import org.springframework.validation.Validator;

import com.ipt.web.model.LoginUser;
import com.ipt.web.model.UnconfirmedUser;

import com.ipt.web.repository.UserRepository;

import com.ipt.web.service.LoginUserService;
import com.ipt.web.service.UserService;

@Component
public class UnconfirmedUserValidator implements Validator {
    @Autowired
    private UserService userService;
	
	@Autowired
    private LoginUserService loginUserService;
	
	 @Autowired
    private UserRepository userRepository;

    @Override
    public boolean supports(Class<?> aClass) {
        return UnconfirmedUser.class.equals(aClass);
    }

    @Override
    public void validate(Object o, Errors errors) {
    	UnconfirmedUser user = (UnconfirmedUser) o;

        ValidationUtils.rejectIfEmptyOrWhitespace(errors, "username", "NotEmpty");
        if (user.getUsername().length() < 5 || user.getUsername().length() > 32) {
            errors.rejectValue("username", "Size.userForm.username");
        }
        /*if (userService.findByUsername(user.getUsername()) != null) {
            errors.rejectValue("username", "Duplicate.userForm.username");
        }
		if (userService.findByUsername(user.getUsername()).getEmail() != null) {
            errors.rejectValue("email", "Duplicate.userForm.email");
        }*/
		
		if (loginUserService.findByUsername(user.getUsername()) != null) {
            errors.rejectValue("username", "Duplicate.userForm.username");
        }
		
		Boolean flag=false;
		
		try{
			File file4 = new File("Users.txt");
			FileWriter fileWriter = new FileWriter(file4);
			fileWriter.write("\n");
			fileWriter.write("Input Email:"+user.getEmail());
			if(userRepository.findAll().size()!=0){
			for(LoginUser lu:userRepository.findAll()){
				fileWriter.write("\n");
				fileWriter.write("Email: "+ lu.getEmail());
				if(lu.getEmail()!=null){
					if(lu.getEmail().equals(user.getEmail())){
						flag=true;
						break;
					}
				}
			}
		}
			fileWriter.flush();
			fileWriter.close();
		}catch(IOException e){
			e.printStackTrace();
		}
		
		if(flag)
			errors.rejectValue("email", "Duplicate.userForm.email");
			
			
			
			
		

        ValidationUtils.rejectIfEmptyOrWhitespace(errors, "password", "NotEmpty");
        if (user.getPassword().length() < 5 || user.getPassword().length() > 32) {
            errors.rejectValue("password", "Size.userForm.password");
        }

        if (!user.getPasswordConfirm().equals(user.getPassword())) {
            errors.rejectValue("passwordConfirm", "Diff.userForm.passwordConfirm");
        }
    }
}
