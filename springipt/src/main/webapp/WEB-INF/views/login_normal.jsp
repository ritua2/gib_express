<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>

<c:set var="contextPath" value="${pageContext.request.contextPath}"/>
<jsp:include page="base.jsp" />

<div class="container">

<div class="col-sm-3 info">
                    
 </div>

    <form method="POST" action="${contextPath}/login" class="form-signin" style="width: 30%; margin-left: 400px">
		<div class="form-group" id="utype">
			<label >User Type:</label> &nbsp;&nbsp;&nbsp;
				<input type="radio" id="utype" name="utype" value="db"> IPT User
				<span style="padding-left: 1em">
					<input type="radio" id="utype" name="utype" value="tacc"> TACC User <br>
				</span>
				<c:if test="utype_error">
					<div class="error">
						<p>There was an error: ${ utype_error }</p>
					</div>
				</c:if>

		</div>
        	<h2 class="form-heading">Log in</h2>
		<div class="form-group ${error != null ? 'has-error' : ''}">
            		<span>${message}</span>
			<span>${name}</span>
            		<input name="username" type="text" class="form-control" placeholder="Username" autofocus="true" style="margin-bottom:20px"/>
            		<input name="password" type="password" class="form-control" placeholder="Password" style="margin-bottom:20px"/>
            		<span>${error}</span>
            		<input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/>
			<button class="btn btn-lg btn-primary btn-block" type="submit" onclick="login_test()">Log In</button>
			<br> <br>

			<a href="${contextPath}/forgotPassword" text="resetPassword">Reset Password</a>
            
       		</div>

    </form>

</div>
<jsp:include page="footer.jsp" />
<!-- /container -->
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="${contextPath}/resources/js/bootstrap.min.js"></script>
<script>
function login_test(){
	console.log(document.querySelector('input[name="utype"]:checked').value)
	var a = document.querySelector('input[name="utype"]:checked').value
	if(a==="tacc"){
		console.log("Calling Tacc")
		location.href='/test1'
	}else if(a==="db"){
		console.log("Calling DB")
		location.href='/test2'
	}
}
</script>
<!--</body>
</html>-->
