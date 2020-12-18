<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>
	<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
	<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
	<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>
<c:set var="contextPath" value="${pageContext.request.contextPath}"/>
<jsp:include page="base.jsp" />

<div class="container"   style="padding-left: 80px;padding-right: 130px">	
<h1>FAQs</h1>
<h5>
1. Does GIB support LDAP integration?
<br>
-  Yes. Uncomment the ladp configuration from appconfig-security.xml, update credentials for ldap and follow the instructions from the code by searching for comments with keywords "enable ldap".
<br>
<br>
2. How can the batch computing mode be set-up on GIB?
<br>
-  If the ldap is enabled on the portal then only ldap users can access batch mode, otherwise all the users have access to batch computing mode by default.
<br>
<br>
3. What if we need more Wetty containers than what can be provisioned on one VM?
<br>
 - Multiple VMs with more containers can be registered to accomplish this. In the next release of the code, Docker Swarm and the code for orchestration of the VMs will be added to GIB.
<br>
<br>
4. How many minimum VMs do we need for setting up a web-portal with GIB?
<br>
-  Two VMs are needed. One for the GIB web-portal and other for multiple Wetty terminals.
<br>
<br>
5. How can we add SSL certificates and make the web-portal secure?
<br>
-  As a first step, you will need to have domain-names secured for your IP addresses associated with the VMs. As a next step, you will need to request for SSL certificates from your organization or purchase them. You will need to add the SSL certificates to the /etc/ssl/certs and keys to /etc/ssl/private.
<br>
<br>
6. Is Docker swarm supported?
<br>
-  Currently it is under development and testing. It will be available very soon.
<br>
<br>
7. What are some of the projects that use GIB?
<br>
-  Interactive Parallelization Tool at TACC uses GIB: https://iptweb.tacc.utexas.edu/entry
<br>
<br>
8. What are the tools and technologies used to build GIB?
<br>
-  The GIB portal is developed using Java Spring, MYSQL, python flask APIs, Bash scripting, Greyfish(https://github.com/ritua2/greyfish). Interactive access is provided using Wetty terminals. 
<br>
</h5>
                

</div>	
	
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="${contextPath}/resources/js/bootstrap.min.js"></script>

<jsp:include page="footer.jsp" />
