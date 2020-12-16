<%@ page session="false"%>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib uri = "http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>

<c:set var="contextPath" value="${pageContext.request.contextPath}"/>
<jsp:include page="base.jsp" />

<script src="${contextPath}/resources/js/bootstrap.min.js"></script>


	<div class="container">
		<div class="container-fluid" style=" z-index: 5;  
margin:-35px 0px 0px 0px; 
padding:45px 415px 35px 65px; 
text-align: left; 
font-size: 1.2em; 
border-radius: 0px;">

		<c:if test="${not empty msg}">
			<div class="alert alert-${css} alert-dismissible" role="alert">
				<button type="button" class="close" data-dismiss="alert"
					aria-label="Close">
					<span aria-hidden="true">&times;</span>
				</button>
				<strong>${msg}</strong>
			</div>
		</c:if>

		<h1>All Users</h1>

		<table class="table table-striped">
			<thead>
				<tr>
					<th>User</th>
					<th>Container</th>
					
				</tr>
			</thead>

			<c:forEach var="user" items="${users}">
				<tr>
					<td>${user.user}</td>
					<td><a href="http://${user.ip}/wetty">
					<c:set var = "string1" value = "${user.ip}"/>
					<c:set var = "string2" value = "${fn:substring(string1, 0, 14)}" />
					<c:set var = "string3" value = "${fn:substring(string1, 18, 19)}" />
					${string2}-${string3}
					
					</a></td> 
					

					<td>
						
						<spring:url value="/admin/${user.user}/${user.ip}/delete" var="deleteUrl" />
						

						
						<button class="btn btn-danger"
							onclick="this.disabled=true;location.href='${deleteUrl}'">Delete</button>
				</tr>
				
			</c:forEach>
		</table>

	</div>
	</div>
	<br/>
<br/>
<br/>
<br/>
<br/>
<br/>
<br/>
<br/>
<br/>
<br/>
	<jsp:include page="footer.jsp" />
