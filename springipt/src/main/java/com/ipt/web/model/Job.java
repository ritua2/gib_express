package com.ipt.web.model;

import java.util.Date;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;
import javax.persistence.Table;

@Entity
@Table(name = "jobs")
public class Job {
	
	@Id
	@Column(name = "id")
    private String id;
	
	@Column(name = "type")
	private String type;
	
	@Column(name = "status")
	private String status;
	
	@Column(name = "n_cores")
	private Long n_cores;
	
	@Column(name = "n_nodes")
	private Long n_nodes;
	
	@Column(name = "date_submitted", columnDefinition="DATETIME")
	@Temporal(TemporalType.TIMESTAMP)
	private Date date_submitted;
	
	@Column(name = "date_started", columnDefinition="DATETIME")
	@Temporal(TemporalType.TIMESTAMP)
	private Date date_started;
	
	@Column(name = "date_server_received", columnDefinition="DATETIME")
	@Temporal(TemporalType.TIMESTAMP)
	private Date date_server_received;
	
	@Column(name = "sc_execution_time")
	private Double sc_execution_time;
	
	@Column(name = "error")
	private String error;
	
	@Column(name = "username")
	private String username;
	
	public String getId() {
        return id;
    }
	
	public String getType() {
        return type;
    }

	public String getStatus() {
        return status;
    }

	public Long getN_cores() {
        return n_cores;
    }
	
	public Long getN_nodes() {
        return n_nodes;
    }

	public Date getDate_submitted() {
        return date_submitted;
    }

	public Date getDate_started() {
        return date_started;
    }
	
	public Date getDate_server_received() {
        return date_server_received;
    }
	
	public Double getSc_execution_time() {
        return sc_execution_time;
    }
	
	public String getError() {
        return error;
    }
	
	public String getUsername() {
        return username;
    }
}
