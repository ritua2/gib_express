<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>
	<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
	<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
	<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>
<c:set var="contextPath" value="${pageContext.request.contextPath}"/>
<jsp:include page="base.jsp" />


	<style>
.reveal-if-active {
	opacity: 1;
	max-height: 0;
	overflow: hidden;
	font-size: 16px;
	transform: scale(0.8);
	transition: 0.5s;
	margin-left: -100px;
}

.reveal-if-active label {
	display: block;
	margin: 0 0 3px 15px;
}

.reveal-if-active input[type=text] {
	width: 100%;
}

input[type="radio"]:checked ~ .reveal-if-active {
	opacity: 1;
	max-height: 100px;
	padding: 10px 20px;
	transform: scale(1);
	overflow: visible;
}
</style>
	<div class="container" >
		<div class="container-fluid" style=" z-index: 5;  
margin:-35px 0px 0px 0px; 
padding:45px 415px 35px 65px; 
text-align: left; 
font-size: 1.2em; 
border-radius: 0px;">

		<c:if test="${not empty alert}">
			<div class="alert alert-${css} alert-dismissible" role="alert">
				<button type="button" class="close" data-dismiss="alert"
					aria-label="Close">
					<span aria-hidden="true">&times;</span>
				</button>
				<strong>${alert}</strong>
			</div>
		</c:if>
		
		<p style="text-align: justify; text-justify: inter-word;  width: 105%;">This form will guide you towards composing the command for
			compiling your serial or parallel programs on TACC/XSEDE resources.
			Please upload all the files that are external to your program but are
			required for compiling it successfully, such as, header files and
			other C/C++ program files. composing the command for running your
			serial or parallel programs on TACC/XSEDE resources. Please upload
			all the input or data files required by your executable/binary.</p>


		
		<div id="compile" class="tab-pane fade in active">
			<div class="container" style="width: 90%;margin-left: -10px">
				<form method="POST" action="${contextPath}/compileRunJob"
					enctype="multipart/form-data" id="myForm" name="myForm" onsubmit="event.preventDefault(); radio();">
					<input type="hidden" name="${_csrf.parameterName}"
						value="${_csrf.token}" />
					<div class="form-group">
						<table><tbody><tr><td><label for="system">*System: &nbsp; &nbsp;</label> </td><td style="width: 70%"><select class="form-control" id="system" name="system" onchange="updateQueues()">
							<option value="comet">Comet</option>
							<option value="stampede2">Stampede2</option>
							<option value="Lonestar5">LoneStar5</option>
							 
						</select></td></tr></tbody></table>

						<c:if test="system_error">
							<div class="error">
								<p>There was an error: ${ system_error }</p>
							</div>
						</c:if>
					</div>
					
					<div class="form-group" id="ptype" style="width: 150%;">
						<label for="ptype">Program Type:</label> &nbsp;&nbsp;&nbsp;<input type="radio" id="ptype" name="ptype" value="gcc" checked="" > <a    title="Some sample commands to compile are as follows:

Serial Programs (C/C++)
gcc -o executable_name program_name.c
gcc -o executable_name program_name.c helper_file.c
gcc -o executable_name program_name.c -lm ; #use '-lm' if you have any math functions

g++ -o executable_name program_name.cc
g++ -o executable_name program_name.cc helper_file.cc
g++ -o executable_name program_name.cc -lm ; #use '-lm' if you have any math functions

make; # use this if you provided a Makefile

chmod +x compile.sh; compile.sh; # use this if your commands are in a script that has been uploaded too." style="color:black;">Serial(C/C++) </a>
						<span style="padding-left: 1em"><input type="radio" name="ptype" value="mpi"> <a    title="Some sample commands to compile are as follows:

MPI Programs (C/C++)
mpicc -o executable_name program_name.c
mpicc -o executable_name program_name.c helper_file.c
mpicc -o executable_name program_name.c -lm ; #use '-lm' if you have any math functions

mpicxx -o executable_name program_name.cc
mpicxx -o executable_name program_name.cc helper_file.cc
mpicxx -o executable_name program_name.cc -lm ; #use '-lm' if you have any math functions

make; # use this if you provided a Makefile

chmod +x compile.sh; compile.sh; # use this if your commands are in a script that has been uploaded too." style="color:black;"> MPI(C/C++) </a> <span style="padding-left: 1em"><input type="radio" name="ptype" value="openmp">  <a    title="Some sample commands to compile are as follows:

OpenMP Programs (C/C++)
gcc -fopenmp -o executable_name program_name.c
gcc -fopenmp -o executable_name program_name.c helper_file.c
gcc -fopenmp -o executable_name program_name.c -lm ; #use '-lm' if you have any math functions

g++ -fopenmp -o executable_name program_name.cc
g++ -fopenmp -o executable_name program_name.cc helper_file.cc
g++ -fopenmp -o executable_name program_name.cc -lm ; #use '-lm' if you have any math functions

make; # use this if you provided a Makefile

chmod +x compile.sh; compile.sh; # use this if your commands are in a script that has been uploaded too." style="color:black;">OpenMP(C/C++)</a></span>  <span style="padding-left: 1em"><input type="radio" name="ptype" value="cuda">  <a title="Some sample commands to compile are as follows:

CUDA Programs (C/C++)
nvcc -o executable_name program_name.c

make; # use this if you provided a Makefile

chmod +x compile.sh; compile.sh; # use this if your commands are in a script that has been uploaded too." style="color:black;">CUDA(C/C++)</a></span> <br> 
					</span><c:if
								test="ptype_error">
								<div class="error">
									<p>There was an error: ${ ptype_error }</p>
								</div>
							</c:if>
					</div>
						
						<div>
						<table style="width: 130%; table-layout: fixed;">
							<tbody><tr>
    <td ><div class="form-group" id="ops0" ><label for="ops">Select Operation:</label></div></td>
								<td>
									<div class="form-group" id="ops" name="ops">
						
							<input type="radio" name="radios" value="radio1" id="radio1">  <label for="radio1">Compile</label>
							<div class="reveal-if-active">
							<div style="background-color: #eeeeee" >
							<label for="ccommand">Enter command to Compile</label> <input type="text" id="ccommand" name="ccommand" class="form-control" data-require-pair="#radio1" placeholder="Enter $command" onblur="check(this.value)" title="Enter compile command">
						</div>
						<div style="background-color: #eeeeee">
						<label for="modules1">Modules:</label> <input type="text" class="form-control" id="modules1" placeholder="Add modules to load separated by commas" name="modules1" data-require-pair="#radio1" title="Add modules to load separated by commas">

						
					</div>
						</div>
						</div>
								</td>
								<td>
									<div class="form-group" id="ops2" name="ops"><input type="radio" name="radios" value="radio2" id="radio2"><label for="radio2">Run</label>
							<div class="reveal-if-active"> 
							<div style="background-color: #eeeeee">
								<label for="jobq">Job Queue:</label> <select id="jobq" name="jobq" class="form-control" data-require-pair="#radio2"><option value="gpu-shared" {%="" if="" jobq="=" "gpu-shared"="" %}selected{%="" endif="" %}="">gpu-shared</option><option value="gpu" {%="" if="" jobq="=" "gpu"="" %}selected{%="" endif="" %}="">gpu</option><option value="debug" {%="" if="" jobq="=" "debug"="" %}selected{%="" endif="" %}="">debug</option><option value="compute" {%="" if="" jobq="=" "compute"="" %}selected{%="" endif="" %}="">compute</option></select>
								</div>
								<div style="background-color: #eeeeee">
								<label for="numcores">Number of cores:</label>
								<select class="form-control" type="number" id="numcores" name="numcores" data-require-pair="#radio2">
				<option value="disabled" disabled="">Select One</option>
				<option value="1" {%="" if="" numcores="=&quot;1&quot;" %}selected{%="" endif="" %}="">1</option>
				<option value="2" {%="" if="" numcores="=&quot;2&quot;" %}selected{%="" endif="" %}="">2</option>
				<option value="3" {%="" if="" numcores="=&quot;3&quot;" %}selected{%="" endif="" %}="">3</option>
				<option value="4" {%="" if="" numcores="=&quot;4&quot;" %}selected{%="" endif="" %}="">4</option>
				<option value="5" {%="" if="" numcores="=&quot;5&quot;" %}selected{%="" endif="" %}="">5</option>
				<option value="6" {%="" if="" numcores="=&quot;6&quot;" %}selected{%="" endif="" %}="">6</option>
				<option value="7" {%="" if="" numcores="=&quot;7&quot;" %}selected{%="" endif="" %}="">7</option>
				<option value="8" {%="" if="" numcores="=&quot;8&quot;" %}selected{%="" endif="" %}="">8</option>
				<option value="9" {%="" if="" numcores="=&quot;9&quot;" %}selected{%="" endif="" %}="">9</option>
				<option value="10" {%="" if="" numcores="=&quot;10&quot;" %}selected{%="" endif="" %}="">10</option>
				<option value="11" {%="" if="" numcores="=&quot;11&quot;" %}selected{%="" endif="" %}="">11</option>
				<option value="12" {%="" if="" numcores="=&quot;12&quot;" %}selected{%="" endif="" %}="">12</option>
				<option value="13" {%="" if="" numcores="=&quot;13&quot;" %}selected{%="" endif="" %}="">13</option>
				<option value="14" {%="" if="" numcores="=&quot;14&quot;" %}selected{%="" endif="" %}="">14</option>
				<option value="15" {%="" if="" numcores="=&quot;15&quot;" %}selected{%="" endif="" %}="">15</option>
				<option value="16" {%="" if="" numcores="=&quot;16&quot;" %}selected{%="" endif="" %}="">16</option>
			</select>
			
			</div>
			<div style="background-color: #eeeeee">
			<label for="numnodes">Number of Nodes:</label> <input value="" type="text" class="form-control" id="numnodes" placeholder="Enter number of nodes. if OpenMP or CUDA: Enter 1, if MPI or Hybrid: You may enter 1+" name="numnodes" data-require-pair="#radio2" title="Enter number of nodes. if OpenMP or CUDA: Enter 1, if MPI or Hybrid: You may enter 1+">
			
			</div>
			<div style="background-color: #eeeeee">
				<label for="rcommandargs">Runtime:</label> <input value="" type="text" class="form-control" id="rtime" placeholder="Please enter the time in format: HH:MM:ss" name="rtime" data-require-pair="#radio2" title="Please enter the time in format: HH:MM:ss">
				
			</div>
			<!--<div style="background-color: #eeeeee ; height: 32%">-->
			<div style="background-color: #eeeeee">
			<label for="rcommand">Enter command to Run</label> <input type="text" id="rcommand" name="rcommand" class="form-control" data-require-pair="#radio2" placeholder="Enter $command" title="Sample commands for running serial or parallel programs:

./executable_name ; # serial, OpenMP, CUDA
./executable_name arg1 arg2; # serial, OpenMP, CUDA
ibrun executable_name ;# MPI programs on Stampede2, LS5, or Comet
ibrun executable_name arg1 arg2; # MPI programs on Stampede2, LS5, or Comet
chmod +x runScript.sh; runScript.sh; # use this if your commands are in a script that has been uploaded too.">
								</div>
								
								<div style="background-color: #eeeeee">
						<label for="modules2">Modules:</label> <input type="text" class="form-control" id="modules2" placeholder="Add modules to load separated by commas" name="modules2" data-require-pair="#radio2" title="Add modules to load separated by commas">

						
					</div>
			
							</div>
						</div>
								</td>
								<td>
									<div class="form-group" id="ops3" name="ops"><input type="radio" name="radios" value="radio3" id="radio3"><label for="radio3">Both</label>
							<div class="reveal-if-active"> 
							<div style="background-color: #eeeeee">
								<label for="jobq2">Job Queue:</label> <select id="jobq2" name="jobq2" class="form-control" data-require-pair="#radio3"><option value="gpu-shared" {%="" if="" jobq2="=" "gpu-shared"="" %}selected{%="" endif="" %}="">gpu-shared</option><option value="gpu" {%="" if="" jobq2="=" "gpu"="" %}selected{%="" endif="" %}="">gpu</option><option value="debug" {%="" if="" jobq2="=" "debug"="" %}selected{%="" endif="" %}="">debug</option><option value="compute" {%="" if="" jobq2="=" "compute"="" %}selected{%="" endif="" %}="">compute</option></select>
								</div>
								<div style="background-color: #eeeeee">
								<label for="numcores2">Number of cores:</label>
								<select class="form-control" type="number" id="numcores2" name="numcores2" data-require-pair="#radio3">
				<option value="disabled" disabled="">Select One</option>
				<option value="1" {%="" if="" numcores2="=&quot;1&quot;" %}selected{%="" endif="" %}="">1</option>
				<option value="2" {%="" if="" numcores2="=&quot;2&quot;" %}selected{%="" endif="" %}="">2</option>
				<option value="3" {%="" if="" numcores2="=&quot;3&quot;" %}selected{%="" endif="" %}="">3</option>
				<option value="4" {%="" if="" numcores2="=&quot;4&quot;" %}selected{%="" endif="" %}="">4</option>
				<option value="5" {%="" if="" numcores2="=&quot;5&quot;" %}selected{%="" endif="" %}="">5</option>
				<option value="6" {%="" if="" numcores2="=&quot;6&quot;" %}selected{%="" endif="" %}="">6</option>
				<option value="7" {%="" if="" numcores2="=&quot;7&quot;" %}selected{%="" endif="" %}="">7</option>
				<option value="8" {%="" if="" numcores2="=&quot;8&quot;" %}selected{%="" endif="" %}="">8</option>
				<option value="9" {%="" if="" numcores2="=&quot;9&quot;" %}selected{%="" endif="" %}="">9</option>
				<option value="10" {%="" if="" numcores2="=&quot;10&quot;" %}selected{%="" endif="" %}="">10</option>
				<option value="11" {%="" if="" numcores2="=&quot;11&quot;" %}selected{%="" endif="" %}="">11</option>
				<option value="12" {%="" if="" numcores2="=&quot;12&quot;" %}selected{%="" endif="" %}="">12</option>
				<option value="13" {%="" if="" numcores2="=&quot;13&quot;" %}selected{%="" endif="" %}="">13</option>
				<option value="14" {%="" if="" numcores2="=&quot;14&quot;" %}selected{%="" endif="" %}="">14</option>
				<option value="15" {%="" if="" numcores2="=&quot;15&quot;" %}selected{%="" endif="" %}="">15</option>
				<option value="16" {%="" if="" numcores2="=&quot;16&quot;" %}selected{%="" endif="" %}="">16</option>
			</select>
			
			</div>
			<div style="background-color: #eeeeee">
			<label for="numnodes2">Number of Nodes:</label> <input value="" type="text" class="form-control" id="numnodes2" placeholder="Enter number of nodes. if OpenMP or CUDA: Enter 1, if MPI or Hybrid: You may enter 1+" name="numnodes2" data-require-pair="#radio3" title="Enter number of nodes. if OpenMP or CUDA: Enter 1, if MPI or Hybrid: You may enter 1+">
			
			</div>
			<div style="background-color: #eeeeee">
				<label for="rcommandargs">Runtime:</label> <input value="" type="text" class="form-control" id="rtime2" placeholder="Please enter the time in format: HH:MM:ss" name="rtime2" data-require-pair="#radio3" title="Please enter the time in format: HH:MM:ss">
				
			</div>
			<div style="background-color: #eeeeee">
			<label for="crcommand1">Enter command to Compile</label> <input type="text" id="crcommand1" name="crcommand1" class="form-control" data-require-pair="#radio3" placeholder="Enter $command" onblur="check(this.value)" title="Enter compile command.">
								</div>
			<!--<div style="background-color: #eeeeee; height: 30%" >-->
			<div style="background-color: #eeeeee">
			<label for="crcommand2">Enter command to Run</label> <input type="text" id="crcommand2" name="crcommand2" class="form-control" data-require-pair="#radio3" placeholder="Enter $command" title="Sample commands for running serial or parallel programs:

./executable_name ; # serial, OpenMP, CUDA
./executable_name arg1 arg2; # serial, OpenMP, CUDA
ibrun executable_name ;# MPI programs on Stampede2, LS5, or Comet
ibrun executable_name arg1 arg2; # MPI programs on Stampede2, LS5, or Comet
chmod +x runScript.sh; runScript.sh; # use this if your commands are in a script that has been uploaded too.">
								</div>
			<div style="background-color: #eeeeee">
						<label for="modules3">Modules:</label> <input type="text" class="form-control" id="modules3" placeholder="Add modules to load separated by commas" data-require-pair="#radio3" name="modules3" title="Add modules to load separated by commas">

						
					</div>
			
							</div>
						</div>
								</td>
							</tr>
						</tbody></table></div>					
							
							
						<c:if test="ops_error">
							<div class="error">
								<p>There was an error: ${ ops_error }</p>
							</div>
						</c:if>
					
					
					
					<div class="form-group" id="fileselect">

						<label for="binary">Provide a zip file containing all the
							related files: </label>
						<br>
						<table>
        <tbody><tr>
            <td>
                <input type="radio" name="files" value="wetty" checked=""> From Wetty
            </td>
            <td style="width: 70%">
                <select id="fileToUpload" name="fileToUpload" class="form-control" style="width: 80%">
                    <option value="">--Select--</option>
				</select>
            </td>
        </tr>
        <tr>
            <td>
                <input type="radio" name="files" value="local"> From Local System &nbsp;&nbsp;
            </td>
            <td>
                <input type="file" id="localFiles" name="localFiles" class="form-control" style="width: 80%">
            </td>
        </tr>
    </tbody></table>
						<c:if test="driver_error">
							<div class="error">
								<p>There was an error: ${ driver_error }</p>
							</div>
						</c:if>
						<BR>


					</div>
					<c:if test="ops_error">
						<div class="error">
							<p>There was an error: ${ ops_error }</p>
						</div>
					</c:if>
			<div class="text-left">
				<button type="submit" class="btn btn-default">Submit</button>
			</div>

			</form>
		</div>
	</div>

	<br />
	<br />
	</div>
	</div>
	<script src="http://code.jquery.com/jquery-2.1.3.min.js"></script>
	<script>
	var set='abc';
	var click1;
	var click2;
	var click3;
	$("#radio1").click(function(e){
		 
		if(set==='2'){
		$('#fileselect').animate({
		'marginTop' : "-=300px" //moves up
			});
		
		$('#ops0').animate({
		'marginTop' : "+=70px" //moves up
			});
        $('#ops').animate({
		'marginTop' : "+=70px" //moves up
			});
        $('#ops3').animate({
		'marginTop' : "+=70px" //moves up
			});
		
		}
		if(set==='3'){
		$('#fileselect').animate({
		'marginTop' : "-=350px" //moves up
		});	
		
		$('#ops0').animate({
		'marginTop' : "+=70px" //moves up
			});
        $('#ops2').animate({
		'marginTop' : "+=70px" //moves up
			});
        $('#ops').animate({
		'marginTop' : "+=70px" //moves up
			});
		
		}
			set='1';
		if(!click1){	
click1=true;
click2=false;
click3=false;
	$('#ops0').animate({
		'marginTop' : "-=70px" //moves up
			});
        $('#ops2').animate({
		'marginTop' : "-=70px" //moves up
			});
        $('#ops3').animate({
		'marginTop' : "-=70px" //moves up
			});
	
	$('#fileselect').animate({
		'marginTop' : "+=70px" //moves down
	});}
	});
	
	$("#radio2").click(function(e){
		if(set==='1'){
		$('#fileselect').animate({
		'marginTop' : "-=70px" //moves up
				});
		
		$('#ops0').animate({
		'marginTop' : "+=70px" //moves up
			});
        $('#ops2').animate({
		'marginTop' : "+=70px" //moves up
			});
        $('#ops3').animate({
		'marginTop' : "+=70px" //moves up
			});
		
		}
				if(set==='3'){
		$('#fileselect').animate({
		'marginTop' : "-=350px" //moves up
		});
		
		$('#ops0').animate({
		'marginTop' : "+=70px" //moves up
			});
        $('#ops2').animate({
		'marginTop' : "+=70px" //moves up
			});
        $('#ops').animate({
		'marginTop' : "+=70px" //moves up
			});
		
		}
				set='2';
	if(!click2){	
click2=true;
click1=false;
click3=false;
		$('#ops0').animate({
		'marginTop' : "-=70px" //moves up
			});
        $('#ops').animate({
		'marginTop' : "-=70px" //moves up
			});
        $('#ops3').animate({
		'marginTop' : "-=70px" //moves up
			});
		
	$('#fileselect').animate({
		'marginTop' : "+=300px" //moves down
		});}
	});
	
	
	$("#radio3").click(function(e){
		if(set==='1'){
		$('#fileselect').animate({
		'marginTop' : "-=70px" //moves up
				});
		
		$('#ops0').animate({
		'marginTop' : "+=70px" //moves up
			});
        $('#ops2').animate({
		'marginTop' : "+=70px" //moves up
			});
        $('#ops3').animate({
		'marginTop' : "+=70px" //moves up
			});
		
		}
				if(set==='2'){
		$('#fileselect').animate({
		'marginTop' : "-=300px" //moves up
		});
		
		$('#ops0').animate({
		'marginTop' : "+=70px" //moves up
			});
        $('#ops').animate({
		'marginTop' : "+=70px" //moves up
			});
        $('#ops3').animate({
		'marginTop' : "+=70px" //moves up
			});
		
		}
				set='3';
	if(!click3){	
click3=true;
click1=false;
click2=false;
		$('#ops0').animate({
		'marginTop' : "-=70px" //moves up
			});
        $('#ops2').animate({
		'marginTop' : "-=70px" //moves up
			});
        $('#ops').animate({
		'marginTop' : "-=70px" //moves up
			});
		
	$('#fileselect').animate({
		'marginTop' : "+=350px" //moves down
	});}
	});
	</script>
	
	<script>
	
	$(document).ready(function(){
          
          
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
                $("#fileToUpload").append($('<option>', {
      		value: f +'/',
      		text: abc
  		}));
  	    });	

             },
              error: function(){
                  console.log("error in ajax call");
              }
          });
		  
	
	});

	  updateQueues();
	 function updateQueues(){
      var system = $('#system').val();
	  console.log(system);
      var queues = $('#jobq')
	  var queues2 = $('#jobq2')
      

      if (system == 'stampede2') {
		  queues.empty()
		  queues.append('<option value="normal" {% if jobq == "normal" %}selected{% endif %}>normal</option>')
          queues.append('<option value="development" {% if jobq == "development" %}selected{% endif %}>development</option>')
          queues.append('<option value="flat-quadrant" {% if jobq == "flat-quadrant" %}selected{% endif %}>flat-quadrant</option>')
          queues.append('<option value="skx-dev" {% if jobq == "skx-dev" %}selected{% endif %}>skx-dev</option>')  
          queues.append('<option value="skx-normal" {% if jobq == "skx-normal" %}selected{% endif %}>skx-normal</option>')
		  
		  queues2.empty()
		  queues2.append('<option value="normal" {% if jobq2 == "normal" %}selected{% endif %}>normal</option>')
          queues2.append('<option value="development" {% if jobq2 == "development" %}selected{% endif %}>development</option>')
          queues2.append('<option value="flat-quadrant" {% if jobq2 == "flat-quadrant" %}selected{% endif %}>flat-quadrant</option>')
          queues2.append('<option value="skx-dev" {% if jobq2 == "skx-dev" %}selected{% endif %}>skx-dev</option>')  
          queues2.append('<option value="skx-normal" {% if jobq2 == "skx-normal" %}selected{% endif %}>skx-normal</option>')
      
      } else if (system == 'Lonestar5') {
		  queues.empty()
          queues.append('<option value="normal" {% if jobq == "normal" %}selected{% endif %}>normal</option>')
          queues.append('<option value="development" {% if jobq == "development" %}selected{% endif %}>development</option>')
          queues.append('<option value="gpu" {% if jobq == "gpu" %}selected{% endif %}>gpu</option>')
          queues.append('<option value="vis" {% if jobq == "vis" %}selected{% endif %}>vis</option>')
		  
		  queues2.empty()
		  queues2.append('<option value="normal" {% if jobq2 == "normal" %}selected{% endif %}>normal</option>')
          queues2.append('<option value="development" {% if jobq2 == "development" %}selected{% endif %}>development</option>')
          queues2.append('<option value="gpu" {% if jobq2 == "gpu" %}selected{% endif %}>gpu</option>')
          queues2.append('<option value="vis" {% if jobq2 == "vis" %}selected{% endif %}>vis</option>')
          
      } else if (system == 'comet') {
		  queues.empty()
          queues.append('<option value="gpu-shared" {% if jobq == "gpu-shared" %}selected{% endif %}>gpu-shared</option>')
          queues.append('<option value="gpu" {% if jobq == "gpu" %}selected{% endif %}>gpu</option>')
          queues.append('<option value="debug" {% if jobq == "debug" %}selected{% endif %}>debug</option>')
          queues.append('<option value="compute" {% if jobq == "compute" %}selected{% endif %}>compute</option>')
		  
		  queues2.empty()
		  queues2.append('<option value="gpu-shared" {% if jobq2 == "gpu-shared" %}selected{% endif %}>gpu-shared</option>')
          queues2.append('<option value="gpu" {% if jobq2 == "gpu" %}selected{% endif %}>gpu</option>')
          queues2.append('<option value="debug" {% if jobq2 == "debug" %}selected{% endif %}>debug</option>')
          queues2.append('<option value="compute" {% if jobq2 == "compute" %}selected{% endif %}>compute</option>')
      }
    }
    
</script>
<script>
function check(value){	
	if(document.querySelector('input[name="ptype"]:checked').value==="gcc"){
		if(!(value.includes("gcc")||(value.includes("g++"))))
     {
        alert("Invalid command");  
     }  
	}else if(document.querySelector('input[name="ptype"]:checked').value==="openmp"){
		if(!value.includes("-fopenmp"))
     {
        alert("Invalid command");  
     }  
	}else if(document.querySelector('input[name="ptype"]:checked').value==="mpi"){
		if(!(value.includes("mpicc")||(value.includes("mpicxx"))))
     {
        alert("Invalid command");  
     }  
	}else if(document.querySelector('input[name="ptype"]:checked').value==="cuda"){
		if(!value.includes("nvcc"))
     {
        alert("Invalid command");  
     }  
	}
       
}

function radio(){
	if(document.querySelector('input[name="radios"]:checked')===null){
		alert("Please select an operation.");
		window.location.href = '${contextPath}/compileRun';
	}else{
		console.log("Here");
		document.myForm.action = "${contextPath}/compileRunJob";
		document.myForm.submit();
}
		
}

var FormStuff = {
  
  init: function() {
    this.applyConditionalRequired();
    this.bindUIActions();
  },
  
  bindUIActions: function() {
    $("input[type='radio']").on("change", this.applyConditionalRequired);
  },
  
  applyConditionalRequired: function() {
  	
    $(".form-control").each(function() {
      var el = $(this);
      if ($(el.data("require-pair")).is(":checked")) {
        el.prop("required", true);
      } else {
        el.prop("required", false);
      }
    });
    
  }
  
};

FormStuff.init();

</script>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="${contextPath}/resources/js/bootstrap.min.js"></script>

<jsp:include page="footer.jsp" />



