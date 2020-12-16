package com.ipt.web.model;


import javax.persistence.*;

@Entity
@Table(name = "user")
public class LoginUser {
    private Long id;
    private String username;
    private String password;
	private String email;
	private String name;
	private String institution;
	private String country;
    private String passwordConfirm;
    private String validation_key;
    private String validation_state;
	
    private Role role;

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

    @Transient
    public String getPasswordConfirm() {
        return passwordConfirm;
    }

    public void setPasswordConfirm(String passwordConfirm) {
        this.passwordConfirm = passwordConfirm;
    }

    @ManyToOne
    @JoinTable(name = "user_role", joinColumns = @JoinColumn(name = "user_id"), inverseJoinColumns = @JoinColumn(name = "role_id"))
    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }
    
    public String getValidation_key() {
        return validation_key;
    }

    public void setValidation_key(String validation_key) {
        this.validation_key = validation_key;
    }

    public String getValidation_state() {
        return validation_state;
    }

    public void setValidation_state(String validation_state) {
        this.validation_state = validation_state;
    }
	
	
}
