CREATE USER IF NOT EXISTS '<db_user>'@'localhost';
ALTER USER '<db_user>'@'localhost' IDENTIFIED WITH mysql_native_password BY '<DB user\'s Password>';

CREATE DATABASE  IF NOT EXISTS iptweb;
GRANT ALL PRIVILEGES ON iptweb.* to '<db_user>'@'localhost';

use iptweb;

DROP TABLE IF EXISTS prevalidation;
CREATE TABLE prevalidation (
  id 				INT(11) 		NOT NULL AUTO_INCREMENT,
  username 			VARCHAR(255) 	NOT NULL,
  password			VARCHAR(255) 	DEFAULT NULL,
  email 			varchar(255) 	DEFAULT NULL,
  name 				VARCHAR(500) 	NOT NULL,
  institution 		VARCHAR(1000) 	NOT NULL,
  country 			VARCHAR(255) 	NOT NULL,
  validation_key  	VARCHAR(255)	DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS user;
CREATE TABLE user (
  id 				INT(11) 		NOT NULL AUTO_INCREMENT,
  username 			VARCHAR(255) 	DEFAULT NULL,
  password			VARCHAR(255) 	DEFAULT NULL,
  email 			varchar(255) 	NOT NULL,
  name 				VARCHAR(500) 	NOT NULL,
  institution 		VARCHAR(1000) 	NOT NULL,
  country 			VARCHAR(255) 	NOT NULL,
  validation_key  	VARCHAR(255)	DEFAULT NULL,
  validation_state  	VARCHAR(255)	DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS role;
CREATE TABLE role (
  id 	INT(11) 	NOT NULL AUTO_INCREMENT,
  name 	VARCHAR(45) DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS user_role;
CREATE TABLE user_role (
  user_id INT(11) NOT NULL,
  role_id INT(11) NOT NULL,
  PRIMARY KEY (user_id,role_id),
  KEY fk_user_role_roleid_idx (role_id),
  CONSTRAINT fk_user_role_roleid FOREIGN KEY (role_id) REFERENCES role (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_user_role_userid FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS user_role2;
CREATE TABLE user_role2 (
  user_id INT(11) NOT NULL,
  role_id INT(11) NOT NULL,
  PRIMARY KEY (user_id,role_id),
  KEY fk_user_role_roleid_idx (role_id),
  CONSTRAINT fk_prevalidation_role_roleid FOREIGN KEY (role_id) REFERENCES role (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_prevalidation_role_userid FOREIGN KEY (user_id) REFERENCES prevalidation (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS comment;
CREATE TABLE comment (
  id 			INT(11) NOT NULL AUTO_INCREMENT,
  title 		VARCHAR(255) NOT NULL,
  body			text NOT NULL,
  tag 			VARCHAR(255) NOT NULL,
  created 		timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  lastUpdated 	timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  createdby 	VARCHAR(255) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS reply;
CREATE TABLE reply (
  id 			INT(11) NOT NULL AUTO_INCREMENT,
  title 		VARCHAR(255) NOT NULL,
  body 			text NOT NULL,
  tag 			VARCHAR(255) NOT NULL,
  created 		timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  lastUpdated 	timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  parentid 		INT(11) DEFAULT NULL,
  PRIMARY KEY 	(id),
  KEY 			fk_comment_replies (parentid),
  CONSTRAINT 	fk_comment_replies FOREIGN KEY (parentid) REFERENCES comment (id)	ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS assignment;	
CREATE TABLE assignment (
  user 	varchar(255) NOT NULL,
  ip 	varchar(255) NOT NULL,
  PRIMARY KEY (ip)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS jobs;
CREATE TABLE jobs (
    id                      VARCHAR(255) UNIQUE NOT NULL, # UUID
    username                VARCHAR(255)        NOT NULL,
    compile_commands        VARCHAR(3000),
    run_commands            VARCHAR(3000),
    modules                 VARCHAR(3000)       NOT NULL,
    type                    VARCHAR(255)        NOT NULL,
    status                  VARCHAR(255)        NOT NULL,
    output_files            VARCHAR(1000)       NOT NULL,
    directory_location      VARCHAR(255)        NOT NULL,
    sc_system               VARCHAR(255),
    sc_queue                VARCHAR(255),
    n_cores                 INT,
    n_nodes                 INT,
    date_submitted          DATETIME,
    date_started            DATETIME,
    date_sc_upload          DATETIME,
    date_server_received    DATETIME,
    sc_execution_time       DOUBLE, # seconds
    submission_method       VARCHAR(255),
    notes_user              VARCHAR(255),
    notes_sc                VARCHAR(255),
    notes_server            VARCHAR(255),
    error                   VARCHAR(255),

    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO iptweb.role (id, name) VALUES (1, 'ROLE_USER');
INSERT INTO iptweb.role (id, name) VALUES (2, 'ROLE_ADMIN');


CREATE TABLE current_users (
    username     VARCHAR(255) UNIQUE NOT NULL,
    user_type    VARCHAR(255) NOT NULL,

    PRIMARY KEY (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



CREATE TABLE news (
    id                  VARCHAR(255) UNIQUE NOT NULL,
    published_date      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_date       DATETIME NOT NULL ON UPDATE CURRENT_TIMESTAMP,
    user_type           VARCHAR(2500) NOT NULL,

    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


alter table user drop primary key, add primary key(id, email);

DROP TABLE IF EXISTS terminal;
CREATE TABLE terminal (
    ip              varchar(20)     NOT NULL,
    address         varchar(40)     NOT NULL,
    available       tinyint(1)      NOT NULL,
    ports           int             DEFAULT NULL,
    PRIMARY KEY (ip)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS port;
CREATE TABLE port (
    ip              varchar(20)     NOT NULL,
    port            varchar(5)      NOT NULL,
    id              varchar(50)     DEFAULT NULL,
    currentuser     varchar(25)     DEFAULT NULL,
    available       tinyint(1)      DEFAULT NULL,
    waitkey         varchar(35)     DEFAULT NULL,
    PRIMARY KEY (ip,port)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ;  

DROP TABLE IF EXISTS redirect_cache;
CREATE TABLE redirect_cache (
    ip              varchar(20)     NOT NULL,
    port            varchar(5)      NOT NULL,
    username        varchar(25)     NOT NULL,
    timeout         datetime        DEFAULT NULL,
    PRIMARY KEY (ip,port)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS ip_to_hostname;
CREATE TABLE ip_to_hostname (
    ip              varchar(20)     NOT NULL,
    hostname        varchar(30)     NOT NULL,
    PRIMARY KEY (ip)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS greykeys;
CREATE TABLE greykeys (
    username        varchar(20)     NOT NULL,
    token           varchar(24)     NOT NULL,
    timeout         datetime        DEFAULT NULL,
    PRIMARY KEY (token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE DEFINER=`root`@`localhost` EVENT `DELETE_REDIRECT_CACHE` ON SCHEDULE EVERY 10 SECOND STARTS NOW() ON COMPLETION NOT PRESERVE ENABLE DO DELETE FROM redirect_cache WHERE timeout < NOW();
CREATE DEFINER=`root`@`localhost` EVENT `DELETE_GREYKEYS` ON SCHEDULE EVERY 10 SECOND STARTS NOW() ON COMPLETION NOT PRESERVE ENABLE DO DELETE FROM greykeys WHERE timeout < NOW();

