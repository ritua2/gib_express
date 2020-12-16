<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>
	<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
	<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
	<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>
<c:set var="contextPath" value="${pageContext.request.contextPath}"/>
<jsp:include page="base.jsp" />

<div class="container"   style="padding-left: 80px;padding-right: 130px">	
<h1>FAQs</h1>
<h5>
What is the difference between logging in as an IPT user vs TACC user?
<br>
Answer: TACC users are users with TACC allocations and have created accounts through the TACC portal. Any user who meets these requirements should log in as a TACC user. All other users should create IPT user accounts and log in as an IPT user.
<br>
<br>
Does it matter which account - TACC or IPT - I use to login? 
<br>
Answer: Yes, users with TACC accounts should log in as TACC users. All other users should log in as IPT users. 
<br>
<br>
I just uploaded a file but when I type 'ls' in the terminal I do not see my file?
<br>
Answer: Hit the Refresh List button and look for your file in the select dropdown. 
<br>
<br>
How do I know if my files successfully uploaded? 
<br>
Answer: Type "ls" (as in list) in the directory that the files were uploaded in.
<br>
<br>
What directory to files get uploaded to?
<br>
Answer: /home/gib/
<br>
It does not matter if this is not the current directory that the user is in. 
<br>
<br>
What types of actions can you perform in the terminal?
<br>
Answer: Any basic linux commands, create and edit files, as well as compile and run programs. 
<br>
<br>
How do I submit a job?
<br>
Answer: You can only submit compile and run jobs if you are logged in with your TACC user account. All other users will only be able to run IPT to generate parallel code but not compile and run the generated code on Stampede2 or Comet.
<br>
<br>
How can I use IPT from this web portal?
<br>
Answer: The steps for using IPT from this web portal are presented at the following link: <a href="https://www.youtube.com/watch?v=AypWQf-yJus" target="_blank">https://www.youtube.com/watch?v=AypWQf-yJus</a> .
<!-- I do not see my job showing in the list?
<br>
Answer: The job hasn't been stored in DB, please check your DB connection.
<br> -->
</h5>
                

</div>	
	
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="${contextPath}/resources/js/bootstrap.min.js"></script>

<jsp:include page="footer.jsp" />
