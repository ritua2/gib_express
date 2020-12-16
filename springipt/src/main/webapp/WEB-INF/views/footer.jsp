<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<c:set var="contextPath" value="${pageContext.request.contextPath}"/>

<style type="text/css">

  

  .navbar a {
    float: left;
    font-size: 16px;
    color: white;
    text-align: center;
    padding: 14px 16px;
    text-decoration: none;
  }

  

  .navbar a:hover, .navbar li a:hover, {
    background-color: grey;
  }

  

  html {
    height: 100%;
    box-sizing: border-box;
  }

  *,
  *:before,
  *:after {
    box-sizing: inherit;
  }

  body {
    position: relative;
    margin: 0;
    padding-bottom: 15rem;
    min-height: 100%;
    width:100%;
  }


  

  .footer {
    position: absolute;
    right: 0;
    bottom: 0;
    left: 0;
  }


  /* Based on https://stackoverflow.com/questions/14821087/horizontal-line-and-right-way-to-code-it-in-html-css */
  .dash{
        border: 1px solid #b9aa16;
        width: 100%;
        height: 0px;
  }


  /* Based on https://www.w3schools.com/howto/howto_css_center-vertical.asp */
  .vertical-center {
  margin: 0;
  position: absolute;
  top: 50%;
  -ms-transform: translateY(-50%);
  transform: translateY(-50%);
  }

</style>



<!-- Footer -->
<div class="footer">
  <footer id="myFooter" style="left: 0px; right: 0px; bottom: 0; bottom:0; background-color: #fff; text-align:center; color:#fff; height: 12%; width: 100%">
    

    <div class="dash"></div>

    <div class="container">

      <div class="container-fluid" style="position: relative; z-index: 5;  
      padding:2px 16px 0px 16px; 
      text-align: left; 
      font-size: 1.2em;
      filter: alpha(opacity=1);
      border-radius: 0px;">

         <table style="width:100%;">


          <tr>
            <th>
                <a href="https://www.nsf.gov/"><img class="nsfLogo" src="/resources/images/nsf.jpg" width="65" height="65" alt="NSF Logo" style="float:left; margin-right:4px;"></a>
            </th>

            <th>
                <p style="margin:13px 5px 5px 5px; font-size:18px; font-weight:bold; text-align:left; color:   #555555  ;">This project has been generously funded by <a href="https://www.nsf.gov/awardsearch/showAward?AWD_ID=1642396&HistoricalAwards=false" style="color:   #555555  ;" target="_blank">NSF award #1642396</a>.</p>

            </th>
            <th>
                
              <div>
                      
                <h3 class="logo"><a href="https://www.utsa.edu//"> UTSA </a>|<a href="/"> IPT </a></h3>
                  <div class="social-icons">
                    <p>
                      &nbsp; &nbsp;
                      <a href="https://twitter.com/UTSA" class="twitter"><i class="fa fa-twitter"></i></a> &nbsp;
                      <a href="https://www.facebook.com/utsa" class="facebook"><i class="fa fa-facebook"></i></a>  
                    </p>       
                    </div>
              </div>


            </th>

          </tr>

        </table> </div>


      </div>
    </div>
            
  </footer>
</div>
<!-- End of footer -->


  <script
    src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
  <script
    src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"
    integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa"
    crossorigin="anonymous"></script>
  <!-- Latest compiled and minified JavaScript -->
  <script src="https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js"></script>

</body>
</html>
