<%@ page session="false"%>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<c:set var="contextPath" value="${pageContext.request.contextPath}"/>
<jsp:include page="base.jsp" />
<!--<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    
    <meta name="description" content="">
    <meta name="author" content="">

    <title>Need Help?</title>


</head>

<body>-->
<!-- Help Tab -->
        <!--Section header-->
    <div class="container" style="padding-left: 80px;padding-right: 130px"> 
        <h2>Just Getting Started with IPT?</h2>
        <!--Links-->
        

        <p style="text-align: justify; text-justify: inter-word;">Interactive Parallelization Tool (IPT) is a high-level tool for transforming serial C/C++ applications
          into their parallel variants. The parallel programming models that are currently supported by IPT are:
          MPI, OpenMP, CUDA, and Hybrid Programming models. The end-users of IPT must have an understanding
          of the basic concepts involved in parallel programming (e.g., data distribution and data gathering).
          After developing an understanding of the basic parallel programming concepts,
          IPT can be used by its target audience (domain experts and students) to semi-automatically generate
          parallel programs based on multiple parallel programming paradigms (MPI, OpenMP, and CUDA), and
          learn about these paradigms through observation and comparison. The IPT-based personalized learning
          approach complements the traditional methods of learning and training that usually emphasize the syntax
          and semantics of one or more programming standards. IPT provides a jumpstart to the domain experts
          in using modern High Performance Computing (HPC) platforms for their research and development needs,
          and hence lowers the adoption barriers to HPC.</p>
        <h4>
          For further high-level details related to IPT (motivation, design, benefits), please review our
            <a href="http://dl.acm.org/citation.cfm?id=2616558" target="_blank" alt="A Tool for Interactive Parallelization">paper</a>.
        </h4>

        <!--Section header-->
        <h2>Want to Learn More?</h2>
        <!--Links-->
        <h4><a href="https://drive.google.com/drive/u/0/folders/1TuGOd-h-qz_6pQWQ0lgBXzeIpawHwYz1" target="_blank" alt="Tutorial Files for IPT">Tutorial
            Files for IPT</a></h4>

        <p>Some test cases and the step-by-step process of parallelizing those test cases using IPT can be downloaded
        <a href="https://drive.google.com/open?id=1J5AIAub9lnfZmZRktCjMPPHnL_3AcJnE" target="_blank" alt="IPT user guide">here</a>.</p>

        <h4><a href="https://github.com/ritua2/IPT/tree/master/Userguide" target="_blank" alt="IPT user guide">IPT User
      Guide</a></h4><p>Covers a series of IPT examples for transforming serial programs into their parallelized versions</p>
    </div>  
       

   <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="${contextPath}/resources/js/bootstrap.min.js"></script>  

<!--</body>
</html>-->
 <jsp:include page="footer.jsp" />
