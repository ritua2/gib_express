<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>

        <%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>

        <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

        <%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>

        <c:set var="contextPath" value="${pageContext.request.contextPath}"/>

<jsp:include page="base.jsp" />

<div class="container">

<div class="col-sm-3 info">
 </div>

<form method="POST" action="${contextPath}/forgotPassword" class="form-signin" style="width: 30%; margin-left: 400px">

                <h2 class="form-heading">Enter Email ID:</h2>

                <div class="form-group">
                      

                        <input name="email" type="text" class="form-control" placeholder="email" autofocus="true" required="required style="margin-bottom:20px"/>

			<br>
                        <button class="btn btn-lg btn-primary btn-block" type="submit" onclick="pass_reset()">Reset Password</button>

			<p><span id='displaySuccess'></span></p>
                </div>

    </form>

</div>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>

<script src="${contextPath}/resources/js/bootstrap.min.js"></script>

<script>
function pass_reset(){
        console.log(document.querySelector('input[name="email"]).value)
        var a = document.querySelector('input[name="email"]').value
        if(a!=NULL"){
                console.log("Calling Password Reset")
                location.href='/resetPassword'
		document.getElementById('displaySuccess').innerHTML = "You will receive an email for password reset if your id exists in our database."
	        
        }else{
                console.log("Cannot reset password right now.")
        }
}
</script>

<jsp:include page="footer.jsp" />
