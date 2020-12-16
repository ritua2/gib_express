<%@ page session="false"%>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>

<c:set var="contextPath" value="${pageContext.request.contextPath}"/>
<jsp:include page="../base.jsp" />


	<div class="container" style="padding-left: 80px;padding-right: 130px">

		<c:if test="${not empty msg}">
			<div class="alert alert-${css} alert-dismissible" role="alert">
				<button type="button" class="close" data-dismiss="alert"
					aria-label="Close">
					<span aria-hidden="true">&times;</span>
				</button>
				<strong>${msg}</strong>
			</div>
		</c:if>
		
		<c:if test="${pageContext.request.userPrincipal.name != null}">
		<button class="btn btn-primary"
							onclick="location.href='/template/addcomment'">Post Comment</button>
		<!--<h3>Click <a href="/springipt/template/addcomment">here</a> to post a comment</h3>-->
		</c:if>
		<table class="table table-striped">
			<thead>
				<tr>
					<th>#ID</th>
					<th>Title</th>
					<th>Body</th>
					<th>Tag</th>
				</tr>
			</thead>

			<c:forEach var="comment" items="${comments}">
				<tr>
					<td>${comment.id}</td>
					<td>${comment.title}</td>
					<td style="max-width: 100px;overflow: hidden;text-overflow: ellipsis;white-space: nowrap;">${comment.body}</td>
					<td>${comment.tag}</td>

					<td><spring:url value="/comments/${comment.id}" var="userUrl" />
						<spring:url value="/comments/${comment.id}/update" var="updateUrl" />
						<spring:url value="/comments/${comment.id}/delete" var="deleteUrl" />
						<spring:url value="/comments/${comment.id}/reply" var="replyUrl" />

						<button class="btn btn-info" onclick="location.href='${userUrl}'">Details</button>
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
					</td>
				</tr>
				<c:forEach var="reply" items="${comment.replies}">
					<tr>
						<td></td>
						<td>${reply.title}</td>
						<td style="max-width: 100px;overflow: hidden;text-overflow: ellipsis;white-space: nowrap;">${reply.body}</td>
						<td>${reply.tag}</td>
						<td></td>
					</tr>
				</c:forEach>
			</c:forEach>
		</table>

	</div>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="${contextPath}/resources/js/bootstrap.min.js"></script>
	


<jsp:include page="../footer.jsp" />