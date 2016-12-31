#!/usr/bin/env bash

source ../bashevents/emitter.bash


fileFunc() {
    
    if [[ "${#FILES[@]}" -ge 1 ]];then
	
	for filesInArray in "${FILES[@]}";do
	    
	    # if the was added and for some reason it has been deleted
	    #    the file no longer exist in the file system
	    #    but the filename is inside the array
	    if [[ -e "$filesInArray" ]];then
		
		
		if [[ "$filesInArray" == "$files" ]];then
		    echo "$files"
		    sleep 5
		    # since $filesInArray is equal to $files
		    #   check if file has been changed
		    #     if it has been changed
		    #         emit the event
		    return 0
		fi
		
	    else
		# file have been deleted or renamed or moved
		unset FILES["$filesInArray"]
		event emit deleteFile "'$filesInArray'"
		return 5 ; # Return status of 5
	    fi
	    
	    
	done
    fi
    return 1
    
}

directoryFunc() {
    :
}

watcher() {

    
    if (( "${#@}" == 0 ));then
	printf "%s\n" "No Folders were specified"
	printf "%s\n" "You have to specify the folders to watch as arguments"
	return 1
    fi



    local files status
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
		    
		    files="${list}"
		    
		    fileFunc "$files"
		    
		    status=$?
		    
		    case $status in
			1)
			    # pass in the path were the file was changed as first argument and the file name as second
			    #   argument, also pass in the file permission
			    event emit newFile "'${PATHS[$watchingPath]}' $files"
			    FILES["$files"]="$files"
			    
			    ;;
		    esac

		    continue
		    
		elif [[ -d "${list}" ]];then
		    files="${list}"
		    continue
		fi
		
		# All the continue statement inside the above conditional statemnt was just to avoid using the
		#    else conditional statement
		event emit unwatchedFile "'${files}'"
		
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

uf() {
    echo "This file is not been watched $1"
}
event attach noExist ne
event attach newFile nf
event attach newDir nd
event attach modifyFile mf
event attach deleteFile df
event attach unwatchedFile uf

watcher "${@}"

