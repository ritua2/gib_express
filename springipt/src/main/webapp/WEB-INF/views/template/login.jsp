
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>

<jsp:include page="../base.jsp" />


<div class="row">
	<div class="col-sm-6 col-sm-offset-3">
		<div class="panel panel-default">
			<div class="panel-heading">
				<h3>
					<center>Welcome to IPT</center>
				</h3>
			</div>
			<div class="panel-body">
				<form:form class="form-horizontal" method="POST" action="/IPTJava/login">
					<fieldset>
						<legend>Sign In to IPT</legend>
						<div class="form-group">
							<label for="username" class="col-lg-2 control-label"></label>

							<div class="col-lg-8">
								<input type="username" class="form-control" id="username"
									placeholder="Enter Username" name="username">
							</div>
						</div>
						<!-- Original -->
						<div class="form-group">
							<label for="password" class="col-lg-2 control-label"></label>

							<div class="col-lg-8">
								<input type="password" class="form-control" id="password"
									placeholder="Enter Password" name="password">
							</div>
						</div>
						<!-- Sign In Button -->
						<div class="form-group">
							<div class="col-lg-8 col-lg-offset-2">
								<div class="card--buttons">
									<button type="submit" id="signin-btn"
										data-behavior="submitForm" name="AccountSignIn"
										class="btn btn-primary btn-lg btn-block">Sign In</button>
								</div>
							</div>
						</div>
						<!-- Error Handling -->

						<div class="error"></div>

						<div></div>

						<!-- Password Reset -->
						<div>
							<div id="gam-forgot-password"
								class="card--message col-lg-8 col-lg-offset-3">
								Forgot your password? <a
									href="{% url 'accounts:password_reset' %}" id="recoverPassword"
									class="link link-grayDarkest link-underline"
									alt="Reset password">Click here</a>
							</div>
						</div>
					</fieldset>
				</form:form>
				<a href="{% url 'accounts:register' %}">
					<button class="btn btn-primary btn-lg btn-block">Create
						Account</button>
				</a>
			</div>
		</div>
	</div>
</div>

