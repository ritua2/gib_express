<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<c:set var="contextPath" value="${pageContext.request.contextPath}"/>
<jsp:include page="base.jsp" />

<script src="${contextPath}/resources/js/bootstrap.min.js"></script>

<br />
<br />
<div class="container">
	<div class="col-sm-3 info">
	</div>


    	<center>
    		<h1>You have been verified successfully. Please reset your password here.</h1>
	</center>
	<br/>
	<br/>


	<form method="POST" action="${contextPath}/passwordReset2" class="form-signin" style="width: 30%; margin-left: 400px">

                <h2 class="form-heading">Enter Password:</h2>

                <div class="form-group">

			<input name="username" type="hidden" id="username" value="<%= request.getParameter("user") %>" />
                        <input name="password" type="password" class="form-control" placeholder="password" autofocus="true" required="required style="margin-bottom:20px"/>

                        <br>
			 <button class="btn btn-lg btn-primary btn-block" type="submit">Set New Password</button> 

                        <p><span id='displaySuccess'></span></p>
                </div>

    </form>

</div>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>

<script src="${contextPath}/resources/js/bootstrap.min.js"></script>

<script>
function pass_reset(){
        console.log(document.querySelector('input[name="password"]).value)
        var a = document.querySelector('input[name="password"]').value
        if(a!=NULL"){
                console.log("Setting New Password")
                location.href='/passwordReset2'
                document.getElementById('displaySuccess').innerHTML = "Your password has been reset. Please login using your new password."
                
        }else{
                console.log("Cannot reset password right now.")
        }
}
</script>


<!-- /container -->
<jsp:include page="footer.jsp" />
