<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>

<c:set var="contextPath" value="${pageContext.request.contextPath}"/>
<!-- Footer -->
  <footer id="myFooter">
        <div class="container">
            <div class="row">
                <div class="col-sm-3">
                    <h5>Get started</h5>
                    <ul>
                        <li><a href="${contextPath}/welcome">Home</a></li>
                        <li><a href="${contextPath}/login">Sign up</a></li>
                    </ul>
                </div>
                <div class="col-sm-3">
                    <h5>About us</h5>
                    <ul>
                        <li><a href="#">Project Overview</a></li>
                        <li><a href="#">Project Team</a></li>
                    </ul>
                </div>
                <div class="col-sm-3">
                    <h5>Support</h5>
                    <ul>
                        <li><a href="#">FAQ</a></li>
                        <li><a href="${contextPath}/comments">Forums</a></li>
                    </ul>
                </div>
                <div class="col-sm-3 info">
                    <h5>What is IPT?</h5>
                    <p> IPT is a semi-automatic tool that converts a C/C++ serial program into an efficient parallel program by parsing the specification by the users. </p>
                </div>
            </div>
        </div>
        <div class="second-bar">
           <div class="container">
                <h2 class="logo"><a href="#"> TACC | IPT </a></h2>
                <div class="social-icons">
                    <br />
                    <p>&copy; TACC | IPT 2018</p>
                    <!--<a href="#" class="twitter"><i class="fa fa-twitter"></i></a>
                    <a href="#" class="facebook"><i class="fa fa-facebook"></i></a>
                    <a href="#" class="google"><i class="fa fa-google-plus"></i></a>-->
                </div>
            </div>
        </div>
  </footer>
<!-- End of footer -->

  <script
    src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
  <script
    src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"
    integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa"
    crossorigin="anonymous"></script>
  <!-- Latest compiled and minified JavaScript -->
  <script src="https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js"></script>

    <!-- For login.jsp -->
    <script>
        $( document ).ready(function() {
          $("#forgot_password_form").hide();
        });

        $(".forgot_password_section").click(function(){
          $("#forgot_password_form").show();
          $("#login_form").hide();
        });

        $(".login_section").click(function(){
          $("#forgot_password_form").hide();
          $("#login_form").show();
        });
    </script>
</body>
</html>