<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>
<%@ taglib uri = "http://java.sun.com/jsp/jstl/core" prefix = "c" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.lang.*"%>
<%@page import="java.sql.DriverManager"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.Statement"%>
<%@page import="java.sql.Connection"%>

<c:set var="contextPath" value="${pageContext.request.contextPath}"/>

<jsp:include page="base.jsp" />
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
    <meta name="description" content="">
    <meta name="author" content="">

    <title>Putty Terminal</title>

    <!-- <link href="${contextPath}/resources/css/bootstrap.min.css" rel="stylesheet">
    <link href="${contextPath}/resources/css/common.css" rel="stylesheet">-->

</head>

<body>
<div class="container">

   <table cellpadding="0" cellspacing="0" width="100%" height="350px">
    <tr>
      <td width="75%">
      <div class="terminal">
        
        <c:set var="username" value="${pageContext.request.userPrincipal.name}" />
        <c:set var="path" value="${contextPath}" />

	  
	 <%
            String test =  (String) session.getAttribute("newip");
            pageContext.setAttribute("test", test);
         %>
	 

	 <iframe id="webterm" src="<% out.println(test);%>" style="overflow:hidden; width:850px; height:500px; background: white; float:center; " allowtransparency="true"> Terminal Session Frame</iframe>
      </div>
      </td>
      <td valign="top">
      <a data-toggle="tooltip"  style="border-bottom:1px dotted #000;text-decoration: none;" title="Upload Additional Files and they will show up in /home/ipt within your IPT terminal."><h3>Upload File/Folder</h3></a>
      <form id="uploadForm" action="${contextPath}/terminal/upload" method="POST" enctype="multipart/form-data">
        <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/>
        <div id="myRadioGroup">
        File upload <input type="radio" name="filefolder" checked="checked" value="file" />
        Folder upload <input type="radio" name="filefolder" value="folder" />
        <div id="file" class="desc">
    	    <div class="form-group">
    	        <input type="file" class="form-control" id="file"
    	                       placeholder="Add additional files or folders" name="fileToUpload" >
    	    </div>
        </div>
        <div id="folder" class="desc">
    	    <div class="form-group">
    	        <input type="file" class="form-control" id="folder"
    	                       placeholder="Add additional files or folders" name="folderToUpload" webkitdirectory mozdirectory directory multiple>
    	        <input type="hidden" id="uploadId" name="hiddenInput">
    	    </div>
        </div>
    	</div>
        <div class="text-right">
          <button type="submit" class="btn btn-default">Upload</button>
        </div>
      </form>
      <br/><br/>
      
        <a data-toggle="tooltip"  style="border-bottom:1px dotted #000;text-decoration: none;" title="Select file or folder to download. Folder path ends with a slash '/' "><h3>Download File/Folder </h3></a>
      <form id="downloadForm" method="GET" action="${contextPath}/terminal/download" enctype="multipart/form-data">
          <div class="form-group">
    	  <select id=fileToDownload class="form-control">
      	    <option value="">--Select--</option>
    	  </select>
              <input type="hidden" name="action" value="download">
          </div>
          <table>
    	<td width="80%">
          <div class="text-left">
              <button id=refreshList type="button" class="btn btn-default">Refresh List</button>
          </div>
    	</td>
    	<td align="right">
          <div class="text-right">
              <button type="submit" id = "test" class="btn btn-default">Download</button>
          </div>
    	</td>
          </table>
      </form>

      </td>
    </tr>
    </table>
  </div>
    <!-- {% endblock %}
  
{% block scripts %} -->
<script src="http://code.jquery.com/jquery-1.9.1.min.js"></script>

  <script>
	window.onload = function(){		
				var frame = document.getElementById('webterm'); 
				var key = "<%=session.getAttribute("key")%>";
				var key1 = "<%=session.getAttribute("key1")%>";
									
				if(key!==key1){	
					console.log("Sending:"+key1);
					var stop = setInterval(function(){frame.contentWindow.postMessage(key1, "*");},100);
					setTimeout(function( ) { clearInterval( stop ); }, 1000);
				}
										
			};
		
	  
	
      $(document).ready(function(){
          src = document.getElementById('webterm').src;
          if (src === window.location.href){
              getTerminalUrl(0) //start count at 0
          }
          $("#folder").hide();
          $("input[name$='filefolder']").click(function() {
          var test = $(this).val();

           $("div.desc").hide();
          $("#" + test).show();
    	  });
          $.ajax({
              url: '${contextPath}/terminal/getdropdownvalues',
              type: 'GET',
  	    dataType: "json",
              success: function(data){
  	    drpDwnValue=data;
  	    $.each( drpDwnValue, function( key, f ) {
		var abc = f.toString().substr(getPosition(f.toString(), '/', 8)); 
		function getPosition(string, subString, index) {
			return string.split(subString, index).join(subString).length;
                }
                $("#fileToDownload").append($('<option>', {
      		value: f +'/',
      		//text: f.substring(f.lastIndexOf("/"));
			text: abc
  		}));
  	    });	

             },
              error: function(){
                  console.log("error in ajax call");
              }
          });
      });
      

      async function sleep(ms = 0) {
        return new Promise(r => setTimeout(r, ms));
      }
      
      var printFiles = function (event) {
          var files = event.target.files;
          jsonObj = [];
          
          for (var indx in files) {
              var curFile = files[indx];
              var fileName = curFile.name
              var path = curFile.webkitRelativePath
              item = {};
              if((fileName != null) && (path != null)){
            	  item [fileName] = '/'+path;
            	  jsonObj.push(item);
              }
              
          }
          
          jsonString = JSON.stringify(jsonObj);
		  $("#uploadId").val(jsonString);
          console.log($("#uploadId").val());
      };
      
      $('#folder').change(printFiles);

      var getTerminalUrl = function(count) {
        $.get("webterm",
        function(data) {
            count += 1;
            console.log(count, data)
            if (data.url !== ""){
                sleep(75)
                webterm.src = data.url;
                return;
            } else if (count < 20){
              getTerminalUrl(count)
            }
        });
      }

      $('#downloadForm').on('submit', function(event){
          event.preventDefault();
          $('#errorMsg').text('');
		  //url=window.location.origin + '${contextPath}/terminal/download/' + $('#fileToDownload').val();
		  //var newWindow = window.open();
		  //newWindow.location = url;
		  var frame = document.getElementById('webterm'); 
		  //var doc = ''+document.getElementById('test'); 
		  //frame.contentWindow.postMessage(doc, "*"); 
		  
		  $.ajax({
            url: window.location.origin + '${contextPath}/terminal/download/' + $('#fileToDownload').val(),
            type: 'GET'
          }).fail(function(xhr) {
            $('#errorMsg').text($('#fileToDownload').val() + ' -- ' +xhr.responseText);
          }).done(function(xhr) {
            window.location = window.location.origin + '${contextPath}/terminal/download/' + $('#fileToDownload').val()
          });
      });
      $('#refreshList').click(function () {
          $.ajax({
              url: '${contextPath}/terminal/getdropdownvalues',
              type: 'GET',
  	    dataType: "json",
              success: function(data){
  	    drpDwnValue=data;
  	    $('#fileToDownload').html('');
  	    $('#fileToDownload').append('<option value="">--Select--</option>');
  	    $.each( drpDwnValue, function( key, f ) {
	    var abc = f.toString().substr(getPosition(f.toString(), '/', 8)); 
	    function getPosition(string, subString, index) {
                     return string.split(subString, index).join(subString).length;
	    }
                $("#fileToDownload").append($('<option>', {
      		value: f + '/',
      		text: abc
  		}));
  	    });	

             },
              error: function(){
                  console.log("error in ajax call");
              }
          });

        });

      $('#uploadForm').on('submit', function(event){
		  event.preventDefault();
          $('#errorMsg').text('');
          var form = $('#uploadForm')[0]
          var formData = new FormData(form);

          $.ajax({
            url: window.location.origin + '${contextPath}/terminal/upload',
            data: formData,
            type: 'POST',
            dataType: "json",
            processData: false,
            contentType: false,
            success: function(xhr) {
              $('<div class="alert alert-success alert-dismissable"><button type="button" class="close" data-dismiss="alert" aria-hidden="true">x</button>'
                   + xhr.msg +'</div>').insertBefore('.terminal')
            }
          }).fail(function(xhr) {
            $('<div class="alert alert-danger alert-dismissable"><button type="button" class="close" data-dismiss="alert" aria-hidden="true">x</button>'
            + xhr.responseJSON.msg +'</div>').insertBefore('.terminal')
          });
      });
  </script>
<!-- {% endblock %} -->

<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="${contextPath}/resources/js/bootstrap.min.js"></script>
</body>
</html>
<jsp:include page="footer.jsp" />
