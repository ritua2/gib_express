<%@ page session="true"%>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>

<c:set var="contextPath" value="${pageContext.request.contextPath}"/>
<jsp:include page="../base.jsp" />



<div class="container" style="padding-left: 80px;padding-right: 630px">

	<c:choose>
		<c:when test="${commentForm['new']}">
			<h1>Add Comment</h1>
		</c:when>
		<c:otherwise>
			<h1>Edit Comment</h1>
		</c:otherwise>
	</c:choose>
	<br />

	<spring:url value="/comments" var="commentActionUrl" />

	<form:form class="form-horizontal" method="post"
		modelAttribute="commentForm" action="${commentActionUrl}">

		<form:hidden path="id" />
		<c:if test="${sessionScope.is_cilogon == true}">
		<form:hidden path="createdby" value = "${sessionScope.curusername}"/>
		</c:if>
		<c:if test="${sessionScope.is_cilogon != true}">
		<form:hidden path="createdby" value = "${pageContext.request.userPrincipal.name}"/>
		</c:if>

		<spring:bind path="title">
			<div class="form-group ${status.error ? 'has-error' : ''}">
				<label class="col-sm-2 control-label">Title</label>
				<div class="col-sm-10">
					<form:input path="title" type="text" class="form-control"
						id="title" placeholder="Title" />
					<form:errors path="title" class="control-label" />
				</div>
			</div>
		</spring:bind>

		<spring:bind path="body">
			<div class="form-group ${status.error ? 'has-error' : ''}">
				<label class="col-sm-2 control-label">Comment</label>
				<div class="col-sm-10">
					<form:textarea path="body" rows="5" class="form-control" id="body"
						placeholder="body" />
					<form:errors path="body" class="control-label" />
				</div>
			</div>
		</spring:bind>

		<spring:bind path="tag">
			<div class="form-group ${status.error ? 'has-error' : ''}">
				<label class="col-sm-2 control-label">Tag</label>
				<div class="col-sm-10">
					<form:input path="tag" type="text" class="form-control " id="tag"
						placeholder="tag" />
					<form:errors path="tag" class="control-label" />
				</div>
			</div>
		</spring:bind>

		<div class="form-group">
			<div class="col-sm-offset-2 col-sm-10">
				<c:choose>
					<c:when test="${commentForm['new']}">
						<button type="submit" class="btn-lg btn-primary pull-right">Add</button>
					</c:when>
					<c:otherwise>
						<button type="submit" class="btn-lg btn-primary pull-right">Update</button>
					</c:otherwise>
				</c:choose>
			</div>
		</div>
	</form:form>
</div>

<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="${contextPath}/resources/js/bootstrap.min.js"></script>


<jsp:include page="../footer.jsp" />
