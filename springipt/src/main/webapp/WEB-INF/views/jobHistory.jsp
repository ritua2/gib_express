<%@ page session="false"%>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib uri = "http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>


<c:set var="contextPath" value="${pageContext.request.contextPath}"/>
<jsp:include page="base.jsp" />


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

		

		<table class="table table-striped">
			<thead>
				<tr>
					<th>ID</th>
					<th>Type</th>
					<th>Status</th>
					<th>No. Nodes</th>
					<th>No. Cores</th>
					<th>Submission Date</th>
					<th>Start Date</th>
					<th>Date Received</th>
					<th>Execution Time(s)</th>
					<th>Error</th>
						
					
				</tr>
			</thead>
			


			<c:forEach var="job" items="${jobs}">
				<tr>
					
					<td>${job.id}</td>
					<td>${job.type}</td>
					<td>${job.status}</td>
					<td>${job.n_nodes}</td>
					<td>${job.n_cores}</td>
					<td>${job.date_submitted}</td>
					<td>${job.date_started}</td>
					<td>${job.date_server_received}</td>
					<td>${job.sc_execution_time}</td>
					<td>${job.error}</td>

					
				</tr>
			</c:forEach>
				
			
		</table>

	</div>

	
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="${contextPath}/resources/js/bootstrap.min.js"></script>

<jsp:include page="footer.jsp" />