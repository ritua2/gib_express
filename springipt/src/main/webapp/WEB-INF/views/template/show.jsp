<%@ page session="false"%>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>

<c:set var="contextPath" value="${pageContext.request.contextPath}"/>
<jsp:include page="../base.jsp" />




<div class="container" style="padding-left: 80px;padding-right: 130px">

	<c:if test="${not empty msg}">
		<div class="alert alert-${css} alert-dismissible" role="alert">
			<button type="button" class="close" data-dismiss="alert" aria-label="Close">
				<span aria-hidden="true">&times;</span>
			</button>
			<strong>${msg}</strong>
		</div>
	</c:if>

	<h1>Comment Details</h1>
	<br />

	<div class="row">
		<label class="col-sm-2">ID</label>
		<div class="col-sm-10">${comment.id}</div>
	</div>

	<div class="row">
		<label class="col-sm-2">Title</label>
		<div class="col-sm-10">${comment.title}</div>
	</div>

	<div class="row">
		<label class="col-sm-2">Body</label>
		<div class="col-sm-10" style="padding-right: 130px;text-align: justify;">${comment.body}</div>
	</div>

	<div class="row">
		<label class="col-sm-2">Tag</label>
		<div class="col-sm-10">${comment.tag}</div>
	</div>
	
	<br><br><br>
		
		<spring:url value="/comments/${comment.id}" var="userUrl" />
						<spring:url value="/comments/${comment.id}/update" var="updateUrl" />
						<spring:url value="/comments/${comment.id}/delete" var="deleteUrl" />
						<spring:url value="/comments/${comment.id}/reply" var="replyUrl" />

						
						<c:if test="${pageContext.request.userPrincipal.name != null}">
						<c:if test="${pageContext.request.userPrincipal.name == comment.createdby}">
						<button class="btn btn-primary"
							onclick="location.href='${updateUrl}'">Edit</button>
						<button class="btn btn-danger"
							onclick="this.disabled=true;location.href='${deleteUrl}'">Delete</button>
							</c:if>
						
						<button class="btn btn-success"
							onclick="this.disabled=true;location.href='${replyUrl}'">Reply</button>
						</c:if>
						
						<h1>Comment Replies</h1>
						<table>
						<tr>
					<th>#ID</th>
					<th>Title</th>
					<th>Body</th>
					<th>Tag</th>
				</tr>
						<c:forEach var="reply" items="${comment.replies}">
					<tr>
						<td></td>
						<td>${reply.title}</td>
						<td>${reply.body}</td>
						<td>${reply.tag}</td>
						<td></td>
					</tr>
				</c:forEach>
				</table>

</div>
<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>

<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="${contextPath}/resources/js/bootstrap.min.js"></script>


<jsp:include page="../footer.jsp" />