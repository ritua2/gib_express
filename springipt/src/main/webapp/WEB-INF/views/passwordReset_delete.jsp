<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<c:set var="contextPath" value="${pageContext.request.contextPath}"/>
<jsp:include page="base.jsp" />

<script src="${contextPath}/resources/js/bootstrap.min.js"></script>

<br />
<br />
<div class="container">
    <center>
        <h1>You have been verified successfully. Please reset your password here.</h1>

    </center>
</div>
<br/>
<br/>

<!-- /container -->
<jsp:include page="footer.jsp" />