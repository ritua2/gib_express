#! /bin/bash

# getting necessary information from configure file
# read README for more information
folder_to_check=$(grep FolderToCheck configure| cut -d"=" -f2)
show_all_job_ids_command=$(grep ShowAllJobIdsCommand configure | cut -d"=" -f2)
control_files_folder=$(grep ControlFilesFolder configure | cut -d"=" -f2)
unzip_files_folder=$(grep UnzipFilesFolder configure | cut -d"=" -f2) 
scheduling_system=$(grep ScheduleingSystem configure | cut -d"=" -f2)
serverip=$(grep MainServerIP configure | cut -d'=' -f2)
greyfiship=$(grep GreyFishIP configure | cut -d'=' -f2)
greyfishkey=greyfish


currentdir=$(pwd)
# Getting the files from greyfish
cd $folder_to_check
jobs_left=$(wget --content-disposition http://$greyfiship:2000/grey/download_checksum_dir/$greyfishkey/commonuser/jobs_left 2>&1 | grep "Saving to" | cut -d':' -f2| cut -d' ' -f2 | tr -cd "[:print:]")
echo "Download $jobs_left"
checksum=$(cat $jobs_left | shasum -a 256 |cut -c1-8)
echo $checksum
while [ $(basename $jobs_left) != ${checksum}.tar.gz ]; do 
	echo $checksum.tar.gz is not equal $jobs_left.tar.gz
	rm $jobs_left
	jobs_left=$(wget --content-disposition http://$greyfiship:2000/grey/grey/$greyfishkey/commonuser/$jobs_left/checksum_files 2>&1 | grep "Saving to" | cut -d':' -f2| cut -d' ' -f2 | tr -cd "[:print:]")
	checksum=$(cat $jobs_left | shasum -a 256 |cut -c1-8)
done 

curl http://$greyfiship:2000/grey/delete_checksum_file/${greyfishkey}/commonuser/$jobs_left
tar -xzf $jobs_left
rm $jobs_left

cd $currentdir

# Preparing control files for new execution
if (ls $control_files_folder/current_compile_file_list > /dev/null 2> /dev/null ); then
	cp $control_files_folder/current_compile_file_list $control_files_folder/previous_compile_file_list  
else
	touch $control_files_folder/previous_compile_file_list 
fi
if (ls $control_files_folder/current_run_file_list > /dev/null 2> /dev/null ); then
	cp $control_files_folder/current_run_file_list $control_files_folder/previous_run_file_list  
else
	touch $control_files_folder/previous_run_file_list 
fi

if (ls $control_files_folder/wait_to_run_file_list > /dev/null 2> /dev/null); then
	for f in $(cat wait_to_run_file_list); do
		sed -i "/$f/ d" $control_files_folder/previous_run_file_list
	done
fi
rm $control_files_folder/wait_to_run_file_list 2> /dev/null


if (ls $control_files_folder/current_file_list > /dev/null 2> /dev/null ); then
	cp $control_files_folder/current_file_list $control_files_folder/previous_file_list  
else
	touch $control_files_folder/previous_file_list 
fi 
ls -1r $folder_to_check/*.zip > $control_files_folder/current_file_list

# check to see if there are update in folder_to_check 
new_jobs=$(diff $control_files_folder/current_file_list $control_files_folder/previous_file_list  \
				| grep "^<" | cut -d" " -f2 )

#classify new jobs to Run Job or Compile job
for j in $new_jobs; do
	name=$(echo $j | rev | cut -d'/' -f1 | rev | cut -d'.' -f1  )
	unzip $j -d $unzip_files_folder #/$name
	job=$(python json_parser.py unzip_files_folder/$name/meta.json Jobs)
	if [[ $jobs == 'Compile' ]]; then
		echo $name >> $control_files_folder/current_compile_file_list
	elif [[ $jobs == 'Run' ]]; then
		echo $name >> $control_files_folder/current_run_file_list
	else
		echo $name >> $control_files_folder/current_compile_file_list
		echo $name >> $control_files_folder/current_run_file_list
	fi
done


new_compile_jobs=$(diff $control_files_folder/current_compile_file_list $control_files_folder/previous_compile_file_list  \
				| grep "^<" | cut -d" " -f2 )
# run all the new compile jobs 
for j in $new_compile_jobs; do
	# unzip the compile zip file
	name=$j
	# executing the compile file
	echo $currentdir
	cd $unzip_files_folder/$name
	numbersOfCommands=$(python ${currentdir}/json_parser.py meta.json CC)
	numbersOfCommands=$((numbersOfCommands - 1))
	username=$(python ${currentdir}/json_parser.py meta.json User)
	
	touch compile.sh
	chmod 755 compile.sh
	for i in $(seq 0 $numbersOfCommands); do
		python ${currentdir}/json_parser.py meta.json C${i} >> compile.sh
	done
	./compile.sh 2> ErrorMessages.out 
	# sending back results
	cd $currentdir
	tar -czf $unzip_files_folder/${name}_output.tar.gz $unzip_files_folder/$name/*
	curl -F file=@$unzip_files_folder/${name}_output.tar.gz http://${greyfiship}:2000/grey/upload/${greyfishkey}/${username}/${name}

	# zip -r ${name}_output.zip  $unzip_files_folder/$name
	# curl -F file=@$unzip_files_folder/$name/${name}_output.zip http://${greyfiship}:2000/grey/upload/dev/commonuser/output

	# tar -czf $unzip_files_folder/${name}_output.tar.gz $unzip_files_folder/$name/*
	# curl -F file=@$unzip_files_folder/${name}_output.tar.gz http://${greyfiship}:2000/grey/upload/dev/akn752/${name}
done

MAXIMUM_RUNNING_JOBS=50

if (ls $control_files_folder/current_running_jobs > /dev/null 2> /dev/null ); then
	cp $control_files_folder/current_running_jobs $control_files_folder/previous_running_jobs
else 
	touch $control_files_folder/previous_running_jobs
fi
$show_all_job_ids_command > $control_files_folder/current_running_jobs 

#return results to clients for finished jobs
finished_jobs=$(diff $control_files_folder/current_running_jobs $control_files_folder/previous_running_jobs\
				| grep "^>" | cut -d" " -f2)
echo $finished_jobs
for j in $finished_jobs; do
	name=$(grep $j $control_files_folder/job_id_and_name_list | cut -d' '  -f2)
	cd $unzip_files_folder/$name
	username=$(python ${currentdir}/json_parser.py meta.json User)
	cd $currentdir
	tar -czf $unzip_files_folder/${name}_output.tar.gz $unzip_files_folder/$name/*
	curl -F file=@$unzip_files_folder/${name}_output.tar.gz http://${greyfiship}:2000/grey/upload/${greyfishkey}/${username}/${name}
	# curl --header "Content-Type: application/json" --request POST --data "{\"Job_ID\":\"$name\", \"password\":\"abc123\",\"User\":\"akn752\", \"OUTPUT_DIRS\":[], \"OUTPUT_FILES\":[]}" http://${serverip}:5000/listener/api/users/output_data
	# zip -r $unzip_files_folder/$name/${name}_output.zip $unzip_files_folder/$name
	# curl -F file=@$unzip_files_folder/$name/${name}_output.zip http://${greyfiship}:2000/grey/upload/dev/commonuser/output
	# tar -czf $unzip_files_folder/${name}_output.tar.gz $unzip_files_folder/$name/*
	# curl -F file=@$unzip_files_folder/${name}_output.tar.gz http://${greyfiship}:2000/grey/upload/dev/akn752/${name}
	# curl --header "Content-Type: application/json" --request POST --data "{\"Job_ID\":\"$name\", \"password\":\"abc123\",\"User\":\"akn752\", \"OUTPUT_DIRS\":[], \"OUTPUT_FILES\":[]}" http://${serverip}:5000/listener/api/users/output_data
done


current_running_jobs_num=$(cat $control_files_folder/current_running_jobs  | wc -l)
num_jobs_to_run=0

if [[ $current_running_jobs_num < $MAXIMUM_RUNNING_JOBS ]]; then
	#calucalte maximum number of new jobs to run
	num_jobs_to_run=$(( $MAXIMUM_RUNNING_JOBS - $current_running_jobs_num ))
fi


new_run_jobs=$(diff $control_files_folder/current_run_file_list $control_files_folder/previous_run_file_list  \
				| grep "^<" | cut -d" " -f2 )
# run all the new run jobs
for j in $new_run_jobs; do
	# check to see if the threshold of run jobs is reached
	# if so, does not perform any check or run for new run jobs
	if [[ $num_jobs_to_run == 0 ]]; then
		# saving the jobs that cannnot be run this time in the current run file list
		echo $j >> $control_files_folder/wait_to_run_file_list
		continue
	fi

	# unzip the run zip file
	name=$j
	# run all the new run jobs (FIFO)
	if [[ $scheduling_system == "SLURM" ]]; then
		cp $currentdir/slurm_skeleton.sh $unzip_files_folder/$name/${name}_slurm_skeleton.sh
		cd $unzip_files_folder/$name
		numbersOfCommands=$(python ${currentdir}/json_parser.py meta.json RC)
		numbersOfCommands=$((numbersOfCommands - 1))
		touch run.sh
		chmod 755 run.sh
		for i in $(seq 0 $numbersOfCommands); do
			python ${currentdir}/json_parser.py meta.json R${i} >> run.sh
		done
		cat run.sh >> ${name}_slurm_skeleton.sh
		sed -i "s/JOB_NAME/$name/g" ${name}_slurm_skeleton.sh
		jobid=$(sbatch ${name}_slurm_skeleton.sh | cut -d' ' -f4)
		cd $currentdir
		# adding new job to the list of current_running_jobs
		echo $jobid >> $control_files_folder/current_running_jobs
		echo "$jobid $name" >> $control_files_folder/job_id_and_name_list
	fi
	num_jobs_to_run=$((num_jobs_to_run - 1))
done












