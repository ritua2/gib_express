package com.ipt.web.model;

import javax.persistence.*;

@Entity
@Table(name = "prevalidation")
public class UnconfirmedUser {
    private Long id;
    private String username;
    private String password;
	private String email;
	private String name;
	private String institution;
	private String country;
	private String validation_key;
	private String passwordConfirm;
	private Role2 role;
    

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }
	
	public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
	
	public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
	
	public String getInstitution() {
        return institution;
    }

    public void setInstitution(String institution) {
        this.institution = institution;
    }
	
	public String getCountry() {
        return country;
    }

    public void setCountry(String country) {
        this.country = country;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
	
	public String getValidation_key() {
        return validation_key;
    }

    public void setValidation_key(String validation_key) {
        this.validation_key = validation_key;
    }
	
	@Transient
    public String getPasswordConfirm() {
        return passwordConfirm;
    }

    public void setPasswordConfirm(String passwordConfirm) {
        this.passwordConfirm = passwordConfirm;
    }
	
	@ManyToOne
    @JoinTable(name = "user_role2", joinColumns = @JoinColumn(name = "user_id"), inverseJoinColumns = @JoinColumn(name = "role_id"))
    public Role2 getRole() {
        return role;
    }

    public void setRole(Role2 role) {
        this.role = role;
    }

    
}
