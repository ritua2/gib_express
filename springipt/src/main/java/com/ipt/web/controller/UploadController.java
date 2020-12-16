package com.ipt.web.controller;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.io.IOException;
import java.io.OutputStream;
import java.net.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.StringJoiner;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.util.AntPathMatcher;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.HandlerMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.fasterxml.jackson.core.JsonGenerationException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.ObjectMapper;

@Controller
public class UploadController {
	
	private static String keyReader(){
		String okey=null, baseIP=null;
		File file = new File("/usr/local/tomcat/webapps/envar.txt");
		BufferedReader reader;
		try {
			reader = new BufferedReader(new FileReader(file));
			String line = reader.readLine();
			while (line != null) {
				if(line.contains("orchestra_key"))
					okey=line.substring(line.indexOf("=")+1);
				else if(line.contains("URL_BASE"))
					baseIP=line.substring(line.indexOf("=")+1);
				
				line = reader.readLine();
			}
			reader.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return okey;
	}
	
	private static String IPReader(){
		String baseIP=null;
		File file = new File("/usr/local/tomcat/webapps/envar.txt");
		BufferedReader reader;
		try {
			reader = new BufferedReader(new FileReader(file));
			String line = reader.readLine();
			while (line != null) {
				if(line.contains("URL_BASE"))
					baseIP=line.substring(line.indexOf("=")+1);
				
				line = reader.readLine();
			}
			reader.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return baseIP;
	}

	//private static String UPLOADED_FOLDER = "/home/term/";
	private static String UPLOADED_FOLDER = "/home/greyfish/users/sandbox/DIR_";
	private final Logger logger = LoggerFactory.getLogger(UploadController.class);
	private String loggedin_user=null;
	
	
	private File file = new File("Output.txt");

	@GetMapping("/terminal/upload")
	public String index() {
		return "upload";
	}

	@RequestMapping(value = "/terminal/upload", method = RequestMethod.POST, produces = "application/json")
	public String fileUpload(@RequestParam("filefolder") String filefolderselection,
			@RequestParam("fileToUpload") MultipartFile file, @RequestParam("folderToUpload") MultipartFile[] files,
			@RequestParam("hiddenInput") String jsonfilepath, RedirectAttributes redirectAttributes, HttpServletRequest request) {
				
				String jsonInputString=null, okey=null, baseIP=null, dirPath=null, tarGzPath=null;
				BufferedReader reader=null;
				URL url = null;
				StringBuilder result = new StringBuilder();
				loggedin_user=request.getUserPrincipal().getName();
				
				if(loggedin_user.contains(" "))
					loggedin_user=loggedin_user.replace(" ","_");
				
				
				try {
					File envar = new File("/usr/local/tomcat/webapps/envar.txt");
					reader = new BufferedReader(new FileReader(envar));
					String line = reader.readLine();
					while (line != null) {
						if(line.contains("orchestra_key"))
							okey=line.substring(line.indexOf("=")+1);
						else if(line.contains("URL_BASE"))
							baseIP=line.substring(line.indexOf("=")+1);
						line = reader.readLine();
					}
					reader.close();
				} catch (IOException e) {
					e.printStackTrace();
				}

		System.out.println("Inside the /terminal/upload");
		String objectToReturn = "";
		if (filefolderselection.equals("file")) {

			if (file.isEmpty()) {
				redirectAttributes.addFlashAttribute("msg", "Please select a file to upload");
				// return "redirect:/terminal";
			}

			try {

				byte[] bytes = file.getBytes();
				
				Path path = Paths.get(UPLOADED_FOLDER +loggedin_user+"/home/gib/home/gib/"+ file.getOriginalFilename());
				Files.write(path, bytes);
				
				//set the JSON 
				jsonInputString = "{\"key\":\""+okey+"\",\"filepath\":\""+"home/gib/home/gib/"+ file.getOriginalFilename().toString()+"\", \"IP\":\""+request.getSession().getAttribute("mySessionAttribute").toString().substring(0,request.getSession().getAttribute("mySessionAttribute").toString().indexOf(":"))+"\",\"Port\":\""+request.getSession().getAttribute("mySessionAttribute").toString().substring(request.getSession().getAttribute("mySessionAttribute").toString().indexOf(":")+1)+"\"}";
				
				url = new URL("http://"+baseIP+":5000/api/greyfish/users/"+loggedin_user+"/upload_file");
				
				Process p1 = Runtime.getRuntime().exec("chown -R 1001:1001 /home/term");

				redirectAttributes.addFlashAttribute("msg",
						"You successfully uploaded '" + file.getOriginalFilename() + "'");

			} catch(MalformedURLException e){
				e.printStackTrace();
			}catch (IOException e) {
				e.printStackTrace();
			}
		} else if (filefolderselection.equals("folder")) {
			Map<String, Object> map = new HashMap<String, Object>();

			try {
				System.out.println("jsonfilepath " + jsonfilepath);
				ObjectMapper mapper = new ObjectMapper();
				jsonfilepath = jsonfilepath.replace("{", "").replace("}", "").replace("[", "{").replace("]", "}");
				System.out.println("jsonfilepath " + jsonfilepath);

				// convert JSON string to Map
				map = mapper.readValue(jsonfilepath, new TypeReference<Map<String, String>>() {
				});

				// System.out.println(map);
			} catch (JsonGenerationException e) {
				e.printStackTrace();
			} catch (JsonMappingException e) {
				e.printStackTrace();
			} catch (IOException e) {
				e.printStackTrace();
			}
			StringJoiner sj = new StringJoiner(" , ");
			
			Path path1 = Paths.get(UPLOADED_FOLDER + loggedin_user+"/home/gib/home/gib/"+map.get(files[0].getOriginalFilename()));
						
			try{			
				dirPath = path1.toString().substring(ordinalIndexOf(path1.toString(), "/", 9)+1, ordinalIndexOf(path1.toString(), "/", 10));
				
				
				//set the JSON
				jsonInputString = "{\"key\":\""+okey+"\",\"basepath\":\""+"home/gib/home/gib\", \"IP\":\""+request.getSession().getAttribute("mySessionAttribute").toString().substring(0,request.getSession().getAttribute("mySessionAttribute").toString().indexOf(":"))+"\",\"Port\":\""+request.getSession().getAttribute("mySessionAttribute").toString().substring(request.getSession().getAttribute("mySessionAttribute").toString().indexOf(":")+1)+"\", \"dirname\":\""+dirPath+"\" }";
			
				url = new URL("http://"+baseIP+":5000/api/greyfish/users/"+loggedin_user+"/upload_dir");
				
			} /*catch (FileNotFoundException e) {
				e.printStackTrace();
			} */catch(MalformedURLException e){
				e.printStackTrace();
			}catch (IOException e) {
				e.printStackTrace();
			} 
			
			

			for (MultipartFile f : files) {

				if (f.isEmpty()) {
					continue; // next pls
				}
				
				

				try {
					byte[] bytes = f.getBytes();
					System.out.println("File PATH GETNAME =" + f.getName() + " Original path Name" + f.getOriginalFilename());
					Path path = Paths.get(UPLOADED_FOLDER + loggedin_user+"/home/gib/home/gib/"+map.get(f.getOriginalFilename()));
					Path parentDir = path.getParent();
					if (!Files.exists(parentDir))
						Files.createDirectories(parentDir);
					
					Files.write(path, bytes);

					sj.add(f.getOriginalFilename());

				} catch (IOException e) {
					e.printStackTrace();
				} 

			}

			String uploadedFileName = sj.toString();

			if (StringUtils.isEmpty(uploadedFileName)) {
				// redirectAttributes.addFlashAttribute("msg", "Please select a folder to
				// upload");
				objectToReturn = "{ msg: 'value1' }";
			} else {
				// redirectAttributes.addFlashAttribute("msg", "You successfully uploaded '" +
				// uploadedFileName + "'");
				objectToReturn = "{ msg: 'value2' }";
			}

		}
		
		try{
			
			HttpURLConnection conn = (HttpURLConnection) url.openConnection();
			conn.setRequestMethod("POST");
			conn.setRequestProperty("Content-Type", "application/json; utf-8");
			conn.setDoOutput(true);
			
			try{
			File file4 = new File("Sent.txt");
			FileWriter fileWriter = new FileWriter(file4);
			fileWriter.write("\n");
			fileWriter.write("Base IP: "+ baseIP);
			fileWriter.write("\n");
			fileWriter.write("URL: "+ url.toString());
			fileWriter.write("\n");
			fileWriter.write("User: "+loggedin_user);
			fileWriter.write("\n");
			fileWriter.write(jsonInputString);
			fileWriter.write("\n");
			fileWriter.flush();
			fileWriter.close();
		}catch(IOException e){
			e.printStackTrace();
		}
			
			try(OutputStream os = conn.getOutputStream()) {
				byte[] input = jsonInputString.getBytes("utf-8");
				os.write(input, 0, input.length);           
			}
			BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
			String line;
			//curl_output=abc;
			while ((line = rd.readLine()) != null) {
				result.append(line);
			}
			rd.close();
			
			try{
			File file3 = new File("WettyUploadResult.txt");
			FileWriter fileWriter = new FileWriter(file3);
			fileWriter.write(result.toString());
			fileWriter.write("\n");
			fileWriter.flush();
			fileWriter.close();
		}catch(IOException e){
			e.printStackTrace();
		}
			
			
			
			
		}catch(ProtocolException e){
			e.printStackTrace();
		}catch(IOException e){
			e.printStackTrace();
		}
		
		try {
			Process p1 = Runtime.getRuntime().exec("chown -R 1001:1001 /home/term");
		} catch (IOException e) {
			e.printStackTrace();
		}
		return objectToReturn;
		// return "redirect:/terminal";
	}

	@RequestMapping(value = "/terminal/getdropdownvalues", method = RequestMethod.GET, produces = "application/json")
	public @ResponseBody Map<String, String> refreshDropdownValues(Model model, RedirectAttributes redirectAttributes, HttpServletRequest request, HttpSession session) {
		
		URL url = null;
		String jsonInputString=null, key=null;
		StringBuilder result = new StringBuilder();
		loggedin_user=request.getUserPrincipal().getName();
				
		if(loggedin_user.contains(" "))
			loggedin_user=loggedin_user.replace(" ","_");
		
		
		
		if(session.getAttribute("mySessionAttribute")!=null){
		try{
			url = new URL("http://"+IPReader()+":5000/api/instance/get_latest");
			HttpURLConnection conn = (HttpURLConnection) url.openConnection();
			conn.setRequestMethod("POST");
			conn.setRequestProperty("Content-Type", "application/json; utf-8");
			conn.setDoOutput(true);
			
			jsonInputString = "{\"key\":\""+keyReader()+"\", \"IP\":\""+request.getSession().getAttribute("mySessionAttribute").toString().substring(0,request.getSession().getAttribute("mySessionAttribute").toString().indexOf(":"))+"\",\"Port\":\""+request.getSession().getAttribute("mySessionAttribute").toString().substring(request.getSession().getAttribute("mySessionAttribute").toString().indexOf(":")+1)+"\"}";
			try(OutputStream os = conn.getOutputStream()) {
				byte[] input = jsonInputString.getBytes("utf-8");
				os.write(input, 0, input.length);           
			}
			BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
			String line;
			//curl_output=abc;
			while ((line = rd.readLine()) != null) {
				result.append(line);
			}
			rd.close();
			if(result!=null){
			try{
			File file1 = new File("GetLatestFiles.txt");
			FileWriter fileWriter = new FileWriter(file1);
			fileWriter.write("Result: "+result.toString());
			fileWriter.write("\n");
			fileWriter.write("User: "+request.getUserPrincipal().getName());
			fileWriter.write("\n");
			fileWriter.write("JSON: "+jsonInputString);
			fileWriter.write("\n");
			fileWriter.write("IP: "+request.getSession().getAttribute("mySessionAttribute").toString().substring(0,request.getSession().getAttribute("mySessionAttribute").toString().indexOf(":")));
			fileWriter.write("\n");
			fileWriter.write("Port: "+request.getSession().getAttribute("mySessionAttribute").toString().substring(request.getSession().getAttribute("mySessionAttribute").toString().indexOf(":")+1));
			fileWriter.write("\n");
			fileWriter.flush();
			fileWriter.close();
		}catch(IOException e){
			e.printStackTrace();
			}}
			
		}catch(MalformedURLException e){
			e.printStackTrace();
		}catch(ProtocolException e){
			e.printStackTrace();
		}catch(IOException e){
			e.printStackTrace();
		}
		}
		Map<String, String> listofpath = new HashMap<String, String>();
		walk(UPLOADED_FOLDER + loggedin_user+"/home/gib/home/gib/", listofpath);
		
		try{
			FileWriter fileWriter = new FileWriter(file);
			fileWriter.write("Keys: "+listofpath.keySet());
			fileWriter.write("Values: "+listofpath.values());
			fileWriter.write("\n");
			fileWriter.flush();
			fileWriter.close();
		}catch(IOException e){
			e.printStackTrace();
		}
		
		System.out.println(listofpath.keySet());
		System.out.println(listofpath.values());
		return listofpath;
	}

	@RequestMapping(value = "/terminal/download/{file_name}/**", produces = "application/zip")
	@ResponseBody
	public HttpServletResponse downloadFolder(@PathVariable("file_name") String moduleBaseName,
			HttpServletRequest request, HttpServletResponse response) {
		final String path = request.getAttribute(HandlerMapping.PATH_WITHIN_HANDLER_MAPPING_ATTRIBUTE).toString();
	    final String bestMatchingPattern = request.getAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE).toString();

	    moduleBaseName = "/" + moduleBaseName;
		String arguments = new AntPathMatcher().extractPathWithinPattern(bestMatchingPattern, path);

		System.out.println(moduleBaseName + " module base name and args:" + arguments);
		
		try{
			FileOutputStream outputStream = new FileOutputStream(file, true);
			byte[] strToBytes = (moduleBaseName + " module base name and args:" + arguments).getBytes();
			outputStream.write(strToBytes);
			outputStream.close();
		}catch(IOException e){
			e.printStackTrace();
		}

		String moduleName;
		if (null != arguments && !arguments.isEmpty()) {
			moduleName = moduleBaseName + '/' + arguments;
		} else {
			moduleName = moduleBaseName;
		}
		
		try{
			FileOutputStream outputStream = new FileOutputStream(file, true);
			byte[] strToBytes = ("ModuleName is " + moduleName).getBytes();
			outputStream.write(strToBytes);
			outputStream.close();
		}catch(IOException e){
			e.printStackTrace();
		}
		
		System.out.println("ModuleName is " + moduleName);



		try {
			String temparray[] = moduleName.split("/");
			String filename = temparray[temparray.length - 1];
			// get your file as InputStream
			File fileToDownload = new File(moduleName.replace("\\", "/"));

			Map<String, String> filestozip = new HashMap<String, String>();
			walk(moduleName, filestozip);

			response.setStatus(HttpServletResponse.SC_OK);
			response.setCharacterEncoding("UTF-8");
			response.setContentType("application/zip; charset=UTF-8");
			response.setHeader("Content-Disposition", "attachment;filename=" + filename + ".zip");

			ZipOutputStream zipOutputStream = new ZipOutputStream(response.getOutputStream());

			zipDir(moduleName, zipOutputStream);
			zipOutputStream.close();

		} catch (IOException ex) {
			logger.info("Error writing file to output stream. Filename was '{}'", moduleName, ex);
			throw new RuntimeException("IOError writing file to output stream");
		}

		return response;

	}

	
	
	@GetMapping("/compileRun")
	public String compileRunStatus(Authentication authentication) {
		
		/*try{
			File file1 = new File("UserDetails.txt");
			FileWriter fileWriter = new FileWriter(file1);
			fileWriter.write("\n");
			fileWriter.write(authentication.getPrincipal().toString());
			fileWriter.write("\n");
			fileWriter.write(authentication.getPrincipal().toString().substring(0,65));
			fileWriter.write("\n");
			fileWriter.flush();
			fileWriter.close();
		}catch(IOException e){
			e.printStackTrace();
			}*/
		
		if(authentication.getPrincipal().toString().contains("ROLE_ADMIN"))
		return "compileRun_v5";
	else{
		if(authentication.getPrincipal().toString().contains("Not granted any authorities")){
			if(authentication.getPrincipal().toString().substring(0,65).equals("org.springframework.security.ldap.userdetails.LdapUserDetailsImpl"))
				return "compileRun_v5";
			else
				return "accessDenied";
		}else
			return "accessDenied";
	}
		
	}
	
	@RequestMapping(value = "/compileRunJob", method = RequestMethod.POST, produces = "application/json")
	public String compileRunJob(@RequestParam("system") String system,
	@RequestParam("ptype") String ptype,
	@RequestParam("radios") String radios,
	@RequestParam("ccommand") String ccommand,
	@RequestParam("modules1") String modules1,
	@RequestParam("jobq") String jobq,
	@RequestParam("numcores") String numcores,
	@RequestParam("numnodes") String numnodes,
	@RequestParam("rtime") String rtime,
	@RequestParam("rcommand") String rcommand,
	@RequestParam("modules2") String modules2,
	@RequestParam("jobq2") String jobq2,
	@RequestParam("numcores2") String numcores2,
	@RequestParam("numnodes2") String numnodes2,
	@RequestParam("rtime2") String rtime2,
	@RequestParam("crcommand1") String crcommand1,
	@RequestParam("crcommand2") String crcommand2,
	@RequestParam("modules3") String modules3,
	@RequestParam("files") String files,
	@RequestParam("fileToUpload") String fileToUpload,
	@RequestParam("localFiles") MultipartFile localFiles,
			RedirectAttributes redirectAttributes, HttpServletRequest request)
	{
		try{
			File file = new File("Form.txt");
			FileWriter fileWriter = new FileWriter(file);
			fileWriter.write("\n");
			fileWriter.write("System: "+ system);
			fileWriter.write("\n");
			fileWriter.write("Program Type: "+ ptype);
			fileWriter.write("\n");
			fileWriter.write("Op: "+ radios);
			fileWriter.write("\n");
			fileWriter.write("CCom: "+ ccommand);
			fileWriter.write("\n");
			fileWriter.write("CMod: "+ modules1);
			fileWriter.write("\n");
			fileWriter.write("Jobq: "+ jobq);
			fileWriter.write("\n");
			fileWriter.write("Ncores: "+ numcores);
			fileWriter.write("\n");
			fileWriter.write("NNodes: "+ numnodes);
			fileWriter.write("\n");
			fileWriter.write("Rtime: "+ rtime);
			fileWriter.write("\n");
			fileWriter.write("RCom: "+ rcommand);
			fileWriter.write("\n");
			fileWriter.write("RMod: "+ modules2);
			fileWriter.write("\n");
			fileWriter.write("BJobq: "+ jobq2);
			fileWriter.write("\n");
			fileWriter.write("BNcores: "+ numcores2);
			fileWriter.write("\n");
			fileWriter.write("BNNodes: "+ numnodes2);
			fileWriter.write("\n");
			fileWriter.write("BRtime: "+ rtime2);
			fileWriter.write("\n");
			fileWriter.write("BCCom: "+ crcommand1);
			fileWriter.write("\n");
			fileWriter.write("BRCom: "+ crcommand2);
			fileWriter.write("\n");
			fileWriter.write("BRMod: "+ modules3);
			fileWriter.write("\n");
			fileWriter.write("FilesSelect: "+ files);
			fileWriter.write("\n");
			fileWriter.write("Wetty: "+ fileToUpload);
			fileWriter.write("\n");
			fileWriter.write("Local: "+ localFiles.getOriginalFilename());
			fileWriter.write("\n");
			fileWriter.flush();
			fileWriter.close();
		}catch(IOException e){
			e.printStackTrace();
		}
		
		if(files.equals("wetty")){
			if(fileToUpload.isEmpty()){
				
				redirectAttributes.addFlashAttribute("css", "danger");
				redirectAttributes.addFlashAttribute("alert", "Error!!! Please select a file from Wetty.");
				return "redirect:/compileRun";
			}
		}else{
			
			if(localFiles.isEmpty()){
				redirectAttributes.addFlashAttribute("css", "danger");
				redirectAttributes.addFlashAttribute("alert", "Error!!!  Please upload a file from system.");
				return "redirect:/compileRun";
			}
		}
		
		String jsonInputString=null, okey=null, baseIP=null, queue = null;
		BufferedReader reader=null;
		URL url = null;
		StringBuilder result = new StringBuilder();
		String SALTCHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
        StringBuilder salt = new StringBuilder();
		StringBuilder randomFileName = new StringBuilder();
        Random rnd = new Random();
		
		try{
		File file4 = new File("CompileRun_submit.txt");
		FileWriter fileWriter = new FileWriter(file4);
		
		
		fileWriter.write("Selected File: "+ fileToUpload);
		fileWriter.write("\n");
		
		while (salt.length() < 32) { // length of the random string.
            int index = (int) (rnd.nextFloat() * SALTCHARS.length());
            salt.append(SALTCHARS.charAt(index));
        }
		
		while (randomFileName.length() < 16) { // length of the random string.
            int index = (int) (rnd.nextFloat() * SALTCHARS.length());
            randomFileName.append(SALTCHARS.charAt(index));
        }
        String saltStr = salt.toString();
		
		File file = new File(fileToUpload);
		
		if(!file.exists()){
		
		if (localFiles.isEmpty()) {
				redirectAttributes.addFlashAttribute("msg", "Please select a file to upload");
				// return "redirect:/terminal";
		}
		}
		
		try {
				if(!file.exists()){
					byte[] bytes = localFiles.getBytes();
				Path path = Paths.get(UPLOADED_FOLDER +"commonuser/jobs_left/"+ localFiles.getOriginalFilename());
				Files.write(path, bytes);
				}
				else{
					byte[] bytes = Files.readAllBytes(file.toPath());
					Path path = Paths.get(UPLOADED_FOLDER +"commonuser/jobs_left/"+ file.getName());
				Files.write(path, bytes);
				}
				
				
		}catch (IOException e) {
				e.printStackTrace();
		}	
			File f1 = null;
		if(!file.exists())
				f1 = new File(UPLOADED_FOLDER +"commonuser/jobs_left/"+ localFiles.getOriginalFilename());
			else
				f1 = new File(UPLOADED_FOLDER +"commonuser/jobs_left/"+ file.getName());
				File f2 = new File(UPLOADED_FOLDER +"commonuser/jobs_left/"+ randomFileName.toString()+".zip");
				boolean b = f1.renameTo(f2);
		
		try {
					File envar = new File("/usr/local/tomcat/webapps/envar.txt");
					reader = new BufferedReader(new FileReader(envar));
					String line = reader.readLine();
					while (line != null) {
						if(line.contains("orchestra_key"))
							okey=line.substring(line.indexOf("=")+1);
						else if(line.contains("URL_BASE"))
							baseIP=line.substring(line.indexOf("=")+1);
						line = reader.readLine();
					}
					reader.close();
				} catch (IOException e) {
					e.printStackTrace();
				}
				
		if(system.equals("Stampede2")||system.equals("Lonestar2"))
			queue="normal";
		else
			queue="compute";
		
		String[] fragments = crcommand1.split(" ");
		StringBuilder crcommand1_new = new StringBuilder("");
		StringBuilder crcommand2_new = new StringBuilder("");
		crcommand1_new.append(fragments[0]);
		crcommand2_new.append(crcommand2.replace(".",".."));
		for(int i=1; i<fragments.length;i++){
			if(!fragments[i].contains("-"))
				crcommand1_new.append(" ../"+fragments[i]);
			else
				crcommand1_new.append(" "+fragments[i]);
		}
			
		
		try{
			//set the JSON based on operation chosen
			if(radios.equals("radio1")){
				jsonInputString = "{\"key\":\""+okey+"\",\"User\":\""+request.getUserPrincipal().getName()+"\", \"origin\":\"web\", \"Job\":\"Compile\", \"CC\": \"1\", \"C0\": \""+ccommand+"\", \"modules\":\""+modules1+"\", \"sc_system\":\""+system+"\",\"ID\":\""+saltStr+"\",\"output_files\":\""+"Fixed_Dummy"+"\", \"dirname\":\""+f2.getName().toString().substring(0,f2.getName().toString().indexOf("."))+"\",\"sc_queue\":\""+queue+"\",\"n_nodes\":\"1\",\"n_cores\":\"1\", \"runtime\": \"00:10:00\"}";
			}else if(radios.equals("radio2")){
				jsonInputString = "{\"key\":\""+okey+"\",\"User\":\""+request.getUserPrincipal().getName()+"\", \"origin\":\"web\", \"Job\":\"Run\", \"RC\": \"1\", \"R0\": \""+rcommand+"\", \"modules\":\""+modules2+"\", \"sc_system\":\""+system+"\",\"ID\":\""+saltStr+"\",\"output_files\":\""+"Fixed_Dummy"+"\", \"dirname\":\""+f2.getName().toString().substring(0,f2.getName().toString().indexOf("."))+"\",\"sc_queue\":\""+jobq+"\",\"n_nodes\":\""+numnodes+"\",\"n_cores\":\""+numcores+"\", \"runtime\": \""+rtime+"\"}";
			}else{
				jsonInputString = "{\"key\":\""+okey+"\",\"User\":\""+request.getUserPrincipal().getName()+"\", \"origin\":\"web\", \"Job\":\"Both\", \"CC\": \"1\", \"RC\": \"1\",\"C0\": \""+crcommand1+"\", \"R0\": \""+crcommand2+"\", \"modules\":\""+modules3+"\", \"sc_system\":\""+system+"\",\"ID\":\""+saltStr+"\",\"output_files\":\""+"Fixed_Dummy"+"\", \"dirname\":\""+f2.getName().toString().substring(0,f2.getName().toString().indexOf("."))+"\",\"sc_queue\":\""+jobq2+"\",\"n_nodes\":\""+numnodes2+"\",\"n_cores\":\""+numcores2+"\", \"runtime\": \""+rtime2+"\"}";
				
				//jsonInputString = "{\"key\":\""+okey+"\",\"User\":\""+request.getUserPrincipal().getName()+"\", \"origin\":\"web\", \"Job\":\"Both\", \"CC\": \"1\", \"RC\": \"1\",\"C0\": \""+crcommand1_new.toString()+"\", \"R0\": \""+crcommand2_new.toString()+"\", \"modules\":\""+modules3+"\", \"sc_system\":\""+system+"\",\"ID\":\""+saltStr+"\",\"output_files\":\""+"Fixed_Dummy"+"\", \"dirname\":\""+f2.getName().toString().substring(0,f2.getName().toString().indexOf("."))+"\",\"sc_queue\":\""+jobq+"\",\"n_nodes\":\""+numnodes2+"\",\"n_cores\":\""+numcores2+"\", \"runtime\": \""+rtime2+"\"}";
			}
				url = new URL("http://"+baseIP+":5000/api/jobs/new");
				
			} catch(MalformedURLException e){
				e.printStackTrace();
			}catch (IOException e) {
				e.printStackTrace();
			} 	
				
			try{
			
			HttpURLConnection conn = (HttpURLConnection) url.openConnection();
			conn.setRequestMethod("POST");
			conn.setRequestProperty("Content-Type", "application/json; utf-8");
			conn.setDoOutput(true);
			
			
			fileWriter.write("\n");
			fileWriter.write("Base IP: "+ baseIP);
			fileWriter.write("\n");
			fileWriter.write("URL: "+ url.toString());
			fileWriter.write("\n");
			fileWriter.write(request.getUserPrincipal().getName());
			fileWriter.write("\n");
			fileWriter.write(jsonInputString);
			fileWriter.write("\n");
			fileWriter.flush();
			fileWriter.close();
		
		
		
		
		try(OutputStream os = conn.getOutputStream()) {
				byte[] input = jsonInputString.getBytes("utf-8");
				os.write(input, 0, input.length);           
			}
			BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
			String line;
			//curl_output=abc;
			while ((line = rd.readLine()) != null) {
				result.append(line);
			}
			rd.close();
			
			try{
			File file3 = new File("CompileRunResult.txt");
			FileWriter fileWriter2 = new FileWriter(file3);
			fileWriter2.write(result.toString());
			fileWriter2.write("\n");
			fileWriter2.flush();
			fileWriter2.close();
		}catch(IOException e){
			e.printStackTrace();
		}
				
		}catch(ProtocolException e){
			e.printStackTrace();
		}catch(IOException e){
			e.printStackTrace();
		}
				
		}catch(IOException e){
			e.printStackTrace();
		}
		
		if(result.toString().equals("New job added to database")){
			redirectAttributes.addFlashAttribute("css", "success");
			redirectAttributes.addFlashAttribute("alert", "Job submitted successfully.");
		}else{
			redirectAttributes.addFlashAttribute("css", "danger");
			redirectAttributes.addFlashAttribute("alert", "Error!!! "+result.toString());
		}
		
		
		return "redirect:/compileRun";
		
	}

	@GetMapping("/uploadMultiPage")
	public String uploadMultiPage() {
		return "uploadMulti";
	}

	public void walk(String path, Map<String, String> listofpath) {

		File root = new File(path);
		File[] list = root.listFiles();

		if (list == null)
			return;

		for (File f : list) {
			if (f.isDirectory() && (!f.getName().startsWith("."))) {
				listofpath.put(f.getName(), f.getPath() + File.separator);
				walk(f.getAbsolutePath(), listofpath);
			} else {
				if (!f.getName().startsWith("."))
					listofpath.put(f.getName(), f.getPath());
			}
		}
	}
	
	

	public void zipDir(String dir2zip, ZipOutputStream zos) {
		try {
			// create a new File object based on the directory we have to zip
			
			try{
			FileOutputStream outputStream = new FileOutputStream(file, true);
			byte[] strToBytes = ("\nDir to ZIP " + dir2zip).getBytes();
			outputStream.write(strToBytes);
			outputStream.close();
		}catch(IOException e){
			e.printStackTrace();
		}
			System.out.println("Dir to ZIP " + dir2zip);
			File zipDir = new File(dir2zip);

			int bytesIn = 0;
			byte[] readBuffer = new byte[2156];
			if (zipDir.isDirectory()) {
				// get a listing of the directory content
				String[] dirList = zipDir.list();

				// loop through dirList, and zip the files
				for (int i = 0; i < dirList.length; i++) {
					File f = new File(zipDir, dirList[i]);

					// If its a directory loop again.
					if (f.isDirectory()) {
						String filePath = f.getPath();
						zipDir(filePath, zos);
						continue;
					}

					FileInputStream fis = new FileInputStream(f);
					ZipEntry anEntry = new ZipEntry(f.getPath().substring(f.getPath().indexOf("/home/gib/home/gib/")+19));
					//ZipEntry anEntry = new ZipEntry(f.getName());
					System.out.println("THIS IS ENTRY**********" + anEntry);
					zos.putNextEntry(anEntry);
					while ((bytesIn = fis.read(readBuffer)) != -1) {
						zos.write(readBuffer, 0, bytesIn);
					}
					fis.close();
				}
			} else {
				FileInputStream fis = new FileInputStream(zipDir);
				ZipEntry anEntry = new ZipEntry(zipDir.getName());
				try{
			FileOutputStream outputStream = new FileOutputStream(file, true);
			byte[] strToBytes = ("\nTHIS IS ENTRY Point**********" + anEntry).getBytes();
			outputStream.write(strToBytes);
			outputStream.close();
		}catch(IOException e){
			e.printStackTrace();
		}
				System.out.println("THIS IS ENTRY Point**********" + anEntry);
				zos.putNextEntry(anEntry);
				while ((bytesIn = fis.read(readBuffer)) != -1) {
					zos.write(readBuffer, 0, bytesIn);
				}
				fis.close();

			}
		} catch (Exception e) {
			logger.error("Error During zipping file");
			e.printStackTrace();
		}
	}
	
	
	private int ordinalIndexOf(String str, String substr, int n) {
		int pos = -1;
		do {
			pos = str.indexOf(substr, pos + 1);
		} while (n-- > 0 && pos != -1);
		return pos;
}
}
