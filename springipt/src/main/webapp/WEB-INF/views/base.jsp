<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<c:set var="contextPath" value="${pageContext.request.contextPath}" />
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Gateway In a Box</title>
<!-- Latest compiled and minified CSS -->
<link rel="stylesheet"
	href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"
	integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u"
	crossorigin="anonymous">
<link rel="stylesheet"
	href="//maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css">
<!-- Latest compiled and minified CSS -->
<link href="${contextPath}/resources/css/main.css" rel="stylesheet">
<meta name="viewport" content="width=device-width, initial-scale=1">
<script src='https://www.google.com/recaptcha/api.js'></script>
</head>


<body style="background: #e9ebf0">


	<div class="main-banner">
			<img src="${contextPath}/resources/images/IPT-Banner.jpg"
				class="img-responsive" alt="IPT Banner" style="width: 100%;">
	</div>

	<!-- Navbar -->
	<div class="navbar" style="width: 100%; border-radius: 0;">
		<div class="container" style="width: 93%">

			<!--Tabs-->
			<c:if test="${pageContext.request.userPrincipal.name != null}">

				<a href="/">Home</a>

				<c:if test="${sessionScope.is_admin == 'true'}">
					<a href="${contextPath}/admin">Admin</a>
					<a href="${contextPath}/terminal">Terminal</a>
					<a href="${contextPath}/compileRun">Compile & Run</a>
					<a href="${contextPath}/jobHistory">Job History</a>
					<a data-toggle="dropdown" href="#" aria-expanded="false">Help
                			<span class="caret"></span></a>
					<ul class="dropdown-menu" style="margin-left: 28.5%; margin-top: 0px">
                				<li><a href="/faq">FAQ</a></li>
                				<li><a href="/help">User Guide</a></li>
						<li><a href="/vdemos">Video Demos</a></li>
						<li><a href="/contactus">Contact Us</a></li>
					</ul>
				</c:if>

				
				
				<c:if test="${sessionScope.is_ldap == 'true'}">
					<a href="${contextPath}/terminal">Terminal</a>
					<a href="${contextPath}/compileRun">Compile & Run</a>
					<a href="${contextPath}/jobHistory">Job History</a>
					<a data-toggle="dropdown" href="#" aria-expanded="false">Help
                			<span class="caret"></span></a>
					<ul class="dropdown-menu" style="margin-left: 32%; margin-top: 0px">
	                			<li><a href="/faq">FAQ</a></li>
	                			<li><a href="/help">User Guide</a></li>
						<li><a href="/vdemos">Video Demos</a></li>
						<li><a href="/contactus">Contact Us</a></li>
					</ul>
				</c:if>

				<c:if test="${(sessionScope.is_admin != 'true') && (sessionScope.is_ldap != 'true')}">
					<a href="${contextPath}/terminal">Terminal</a>
					<a href="${contextPath}/compileRun">Compile & Run</a> <%--- comment this line when enble ldap --%>
					<a href="${contextPath}/jobHistory">Job History</a> <%--- comment this line when enble ldap --%>
					<a data-toggle="dropdown" href="#" aria-expanded="false">Help
                			<span class="caret"></span></a>
					<ul class="dropdown-menu" style="margin-left: 28.5%; margin-top: 0px">
	                			<li><a href="/faq">FAQ</a></li>
	                			<li><a href="/help">User Guide</a></li>
						<li><a href="/vdemos">Video Demos</a></li>
						<li><a href="/contactus">Contact Us</a></li>
					</ul>
				</c:if>

				

				<a href="${contextPath}/comments">Message Board</a>
				<a href="${contextPath}/aboutus">About Us</a>

				<ul class="nav navbar-nav navbar-right">
					<a href="/"">Welcome ${pageContext.request.userPrincipal.name}</a>
					<a href="/perform_logout"> Logout <span class="glyphicon glyphicon-log-out"></span></a>
				</ul>

			</c:if>


			<c:if test="${pageContext.request.userPrincipal.name == null}">
				
				<a href="/">Home</a>

				<a data-toggle="dropdown" href="#" aria-expanded="false">Help
                			<span class="caret"></span></a>
				<ul class="dropdown-menu" style="margin-left: 17.2%; margin-top: 0px">
                			<li><a href="/faq">FAQ</a></li>
                			<li><a href="/help">User Guide</a></li>
					<li><a href="/vdemos">Video Demos</a></li>
					<li><a href="/contactus">Contact Us</a></li>
				</ul>

				<a href="${contextPath}/comments">Message Board</a>
				<a href="${contextPath}/aboutus">About Us</a>

				<ul class="nav navbar-nav navbar-right" style="margin-right: 16.5%">
					<li><a href="/registration"><span class="glyphicon glyphicon-user"></span> Sign Up</a></li>
					<li><a href="/login_normal"><span class="glyphicon glyphicon-log-in"></span> Login</a></li>
				</ul>
			</c:if>

			<!-- End Tabs -->

		</div>
	</div>



	<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js"></script>
	<script
		src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"
		integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa"
		crossorigin="anonymous"></script>
	<!-- Latest compiled and minified JavaScript -->
	<script
		src="https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js"></script>
	

	<div style="padding-bottom: 0rem;"></div>
