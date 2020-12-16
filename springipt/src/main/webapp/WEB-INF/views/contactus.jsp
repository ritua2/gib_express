<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>
  <%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
  <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
  <%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>
<c:set var="contextPath" value="${pageContext.request.contextPath}"/>
<jsp:include page="base.jsp" />

  <div class="container" style="padding-left: 80px;padding-right: 130px">	
<div style="width: 100%;"><table align="centre">
    <tbody><tr>
      <td>
       <iframe src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3469.720483589693!2d-98.62109398505345!3d29.582735082052643!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x865c667dd6657fdd%3A0x24e55c903c3a270c!2sThe%20University%20of%20Texas%20at%20San%20Antonio!5e0!3m2!1sen!2sus!4v1605316898863!5m2!1sen!2sus" width="600" height="450" frameborder="0" style="border:0;" allowfullscreen="" aria-hidden="false" tabindex="0"></iframe>
      </td>
      <td width="100%">
        <div style="margin-left: 50px; ">
          <h2>Team</h2>
          <p style="font-size: 20px">Ritu Arora:<br><a href="mailto:ritu.arora@utsa.edu">ritu.arora@utsa.edu</a></p>
          <p style="font-size: 20px">Saumya Shah:<br><a href="mailto:saumya.shah@utsa.edu">saumya.shah@utsa.edu</a></p>
        </div>
        <!-- <div style="margin-left: 50px">
          <h2>Phone / Fax</h2>
          <p>512-475-9411<br>512-475-9445<br><br><strong>Email ID:</strong><a href="info@tacc.utexas.edu">info@tacc.utexas.edu</a></p>
        </div> -->
        
      </td>
      </tr>    
    </tbody></table>

</div>
  </div>

<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="${contextPath}/resources/js/bootstrap.min.js"></script>

<jsp:include page="footer.jsp" />
