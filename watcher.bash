#!/usr/bin/env bash

source ../bashevents/emitter.bash



watcher() {

    
    if (( "${#@}" == 0 ));then
	printf "%s\n" "No Folders were specified"
	printf "%s\n" "You have to specify the folders to watch as arguments"
	return 1
    fi


    # create an array to handle files

    declare -A FILES

    # Set paths in an Array
    declare -A PATHS
    for paths ;do
	PATHS["$paths"]="${paths}"
    done

    while true;do
	
	for watchingPath in "${!PATHS[@]}";do


	    if [[ ! -d "${PATHS[$watchingPath]}" ]];then
		event emit noExist "'${PATHS[$watchingPath]}'"
		unset PATHS[$watchingPath]
	    fi

	    
	    cd "${PATHS[$watchingPath]}"
	    
	    for list in *;do
		
		if [[ -f "${list}" ]];then
		    
		    local files="${list}"
		    
		    (
			if [[ "${#FILES[@]}" -ge 1 ]];then
			    
			    for filesInArray in "${FILES[@]}";do

				# if the was added and for some reason it has been deleted
				#    the file no longer exist in the file system
				#    but the filename is inside the array
				if [[ -e "$filesInArray" ]];then
				    
				
				    if [[ "$filesInArray" == "$files" ]];then

					# since $filesInArray is equal to $files
					#   check if file has been changed
					#     if it has been changed
					#         emit the event
					exit 0
				    fi
				    
				else
				    # file have been deleted or renamed or moved
				    event emit deleteFile "'$filesInArray'"
				    exit 5 ; # Exit status of 5
				fi
				
				
			    done
			fi
			exit 1
		    )
		    
		    local status=$?

		    case $status in
			1)
			    # pass in the path were the file was changed as first argument and the file name as second
			    #   argument, also pass in the file permission
			    event emit newFile "'${PATHS[$watchingPath]}' $files"
			    FILES["$files"]="$files"
			    
			    ;;
			5)
			    # Exit status of 5 means the file has been deleted
			    # unset the file
			    echo $status
			    unset FILES["$files"]
			    ;;
		    esac
		    
		    
		fi
		
	    done
	    
	done
	
    done		  
}

ne() {
    local path="${1}"

    
}
nf() {
    echo "new file detected"
}
nd() { : ;}
mf() { : ;}
df() {
    
    echo "file has been deleted $1"
}
       
event attach noExist ne
event attach newFile nf
event attach newDir nd
event attach modifyFile mf
event attach deleteFile df


watcher "${@}"

