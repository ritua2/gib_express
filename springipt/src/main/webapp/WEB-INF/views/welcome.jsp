<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>

<c:set var="contextPath" value="${pageContext.request.contextPath}"/>
<jsp:include page="base.jsp" />


<style>

  .col-container {
    display: table;
    width: 100%;
  }
  .col {
    display: table-cell;
    padding: 0.5%;
  }

  #rcorners_solid {
    border-radius: 0px;
    padding: 2%;
    width: 100%;
  }

</style>



<div class="col-container" style="width: 95%; padding-left: 5%;">
  <div class="col" style="background: transparent; width: 67%;">
    <h3>Gateway-In-a-Box (GIB) - An out-of-the-box solution for provisioning web-portals that can support interactive and batch computing modes through the convenience of a web-browser</h3>
  </div>

  <div class="col" style="background:  transparent; width: 3%;">
  </div>

  <div class="col" style="background: transparent; width: 30%;">
    <h3>Project News</h3>
  </div>
</div>






<div class="col-container" style="width: 95%; padding-left: 5%;">
  <div class="col" style="background:  #f2f3c3; width: 67%; border-color: #b9aa16; border-style: solid; border-width: 1px;">
    <p>
      Gateway-In-a-Box (GIB) is a customizable software framework for provisioning web-portals that are capable of running scientific computing jobs both interactively in the VMs and in batch computing mode on the supercomputing platforms of interest. The interactive computing tools can be built into the Docker image for the terminal emulator that is a part of GIB, thereby, not only lowering the adoption barriers to these interactive tools by providing a ready-to-use environment, but also making it easy for developers to demo their products to the interested audience. The batch computing mode available through GIB can be customized for compiling and running applications on the supercomputers of interest. GIB can be easily deployed on the resources in the cloud or on-premises.
    </p>
    <p>
      GIB provides the features for registration, login, message-boards, file and folder upload/download, a portable filesystem named Greyfish, a terminal emulator to work in the command-line mode as shown in image below and compiling and running applications on remote computing platforms. The "Help", "Contact", and "About Us" pages along with the header and footer can be easily customized by developers to suit their needs. The web-portal for the Interactive Parallelization Tool (IPT) (iptweb.tacc.utexas.edu) has been developed using GIB and the video of introduction to IPT is shown below. 
    </p>


    <div class="col-container" style="width: 98%; padding-left: 2%;">
      <div class="col" style="background: transparent; width: 47.5%;">
        <img src="${contextPath}/resources/images/terminal_IPT.png" width="400" height="295" style="display: block; margin-left: auto; margin-right: auto;">
      </div>

      <div class="col" style="background:  transparent; width: 5%;">
      </div>

      <div class="col" style="background: transparent; ; width: 47.5%;">
        <iframe width="400" height="295" src="https://www.youtube.com/embed/qKo05dIZoYI"></iframe>
      </div>
    </div>

  </div>

  <div class="col" style="background:  transparent; width: 3%;">
  </div>


  <div class="col" style="background: #f2f3c3; border-color: #b9aa16; border-style: solid; width: 30%; border-width: 1px;">

    <p id="rcorners_solid" style="background-color: #fcfcfc; ">
      Vanilla version of gib has been released on December 18, 2020.
    </p>

    <p id="rcorners_solid" style="background-color: #fcfcfc; ">
      Iptweb at Texas Advanced Computing Center(TACC) which is a precursor of Gib, debuted in September, 2019.
    </p>

    <p id="rcorners_solid" style="background-color: #fcfcfc; ">
      In upcoming version of GIB, the docker swarm will be released to provide wetty terminals on demand.
    </p>

  </div>

</div>


<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="${contextPath}/resources/js/bootstrap.min.js"></script>


<jsp:include page="footer.jsp" />
