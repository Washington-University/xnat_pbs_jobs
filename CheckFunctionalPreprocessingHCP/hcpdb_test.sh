#!/bin/bash
cd /HCP/hcpdb/archive/PipelineTest/arc001/
for subject in 188347 100307 201414; do
    subj="${subject}_3T"
    logfile="/home/HCP/gburgess/${subject}.txt"
    echo -n >| $logfile
    for task in REST1 REST2 WM GAMBLING MOTOR LANGUAGE RELATIONAL SOCIAL EMOTION; do
	for dir in LR RL; do
	    numframes=`fslnvols ${subj}/RESOURCES/?fMRI_${task}_${dir}_preproc/MNINonLinear/Results/?fMRI_${task}_${dir}/?fMRI_${task}_${dir}.nii.gz`;
	    if [ -e ${subj}/RESOURCES/?fMRI_${task}_${dir}_preproc/MNINonLinear/Results/?fMRI_${task}_${dir}/*.fsf ]; then
		fsf=${subj}/RESOURCES/?fMRI_${task}_${dir}_preproc/MNINonLinear/Results/?fMRI_${task}_${dir}/*.fsf
		ls -ld $fsf
                #should be equal to numframes
		npts=`grep npts $fsf | cut -d ' ' -f3`
		if [ $npts -ne $numframes ]; then
		    echo "Subject: ${subject} ${task}_${dir} failed with FSF NPTS less than acquired volumes, NPTS $npts Volumes $numframes " >> $logfile
		else
		    echo "Subject: ${subject} ${task}_${dir} passed with FSF NPTS equal to acquired volumes." >> $logfile
		fi

		# check that EVs are not empty
		results_directory=`dirname $fsf`
		for EV in `grep txt $fsf | sed -e 's|\"||g' | cut -d'/' -f2-3`; do 
		    EV="$results_directory/$EV";
		    if [ -e $EV ]; then
			ev_lines=`cat $EV | wc -l`
			ev_columns=`awk '{print NF}' $EV | sort -nu`
		    else
			ev_lines=0;
			ev_columns=0;
		    fi
		    if [ $ev_lines -eq 0 ]; then
			echo "Subject: ${subject} ${task}_${dir} failed with EV lines equal 0" >> $logfile
		    else
			echo "Subject: ${subject} ${task}_${dir} passed with EV lines equal $ev_lines ." >> $logfile
		    fi
		
		    if [ $ev_columns -ne 3 ]; then
			echo "Subject: ${subject} ${task}_${dir} failed with EV columns not equal to 3, Cols" $ev_columns >> $logfile
		    else
			echo "Subject: ${subject} ${task}_${dir} passed with EV columns equal to 3." >> $logfile
		    fi
		done

	    elif [[ $task != *REST* ]]; then
		echo "Subject: ${subject} tfMRI_${task}_${dir} failed with no FSF found." >> $logfile
	    fi


	    #check movement regressors
	    if [ -e ${subj}/RESOURCES/?fMRI_${task}_${dir}_preproc/MNINonLinear/Results/?fMRI_${task}_${dir}/Movement_Regressors.txt ]; then
		mvmt_reg=${subj}/RESOURCES/?fMRI_${task}_${dir}_preproc/MNINonLinear/Results/?fMRI_${task}_${dir}/Movement_Regressors.txt
		mvmt_lines=`cat $mvmt_reg | wc -l`
		mvmt_columns=`awk '{print NF}' $mvmt_reg | sort -nu`
		if [ $mvmt_lines -ne $numframes ]; then
		    echo "Subject: ${subject} ${task}_${dir} failed with MVMT lines less than acquired volumes, Lines" $mvmt_lines " Volumes " $numframes >> $logfile
		else
		    echo "Subject: ${subject} ${task}_${dir} passed with MVMT covering acquired volumes." >> $logfile
		fi
		
		if [ $mvmt_columns -ne 12 ]; then
		    echo "Subject: ${subject} ${task}_${dir} failed with MVMT columns less than 12, Cols" $mvmt_columns >> $logfile
		else
		    echo "Subject: ${subject} ${task}_${dir} passed with MVMT columns equal to 12." >> $logfile
		fi
	    else
		echo "Subject: ${subject} ${task}_${dir} failed MVMT with no Movement_Regressors.txt found." >> $logfile
	    fi

	done
    done
done