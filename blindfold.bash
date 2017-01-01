#!/usr/bin/env bash

source ../bashevents/emitter.bash

getFileStat() {

    local currentFileSize="$(stat --format="%s" "$files" )"
    declare -A FILESTAT

    FILESTAT["group_id"]="$(stat --format="%g" "$files" )"
    FILESTAT["group_name_owner"]="$(stat --format="%G" "$files" )"

    FILESTAT["access_right"]="$(stat --format="%a" "$files" )"
    
    FILESTAT["user_id"]="$(stat --format="%u" "$files" )"
    FILESTAT["user_name_owner"]="$(stat --format="%U" "$files" )"
    
    

    if (( ${FILESIZE[$files]} != $currentFileSize ));then

	FILESIZE["$files"]="$currentFileSize" ;# reinitialize the new size of the file and emit modifyFile event
	
	# pass in the file name as first argument
	# group_id as second argument
	# group_name_owner has third argument
	# hexadecimal access_right as fourth argument
	# user_id as fifth argument
	# user_name_owner as sixth argument
	# size of file as last argument
	
	event emit modifyFile "${files} ${FILESTAT[*]} ${FILESIZE["$files"]}"
	
    fi
    
}


fileFunc() {

    if [[ "${#FILES[@]}" -ge 1 ]];then

	for filesInArray in "${FILES[@]}";do

	    # if the was added and for some reason it has been deleted
	    #    the file no longer exist in the file system
	    #    but the filename is inside the array

	    if [[ -e "$filesInArray" ]];then

		# files is a local variable in blindfold, but since
		#     fileFunc is called in blindfold,
		#    fileFunc now have access to all blindfold local variables
		#                ***** think closure ****
		
		if [[ "$filesInArray" == "$files" ]];then
		    getFileStat
		    # since $filesInArray is equal to $files
		    #   check if file has been changed
		    #     if it has been changed
		    #         emit the event
		    return 0
		fi

	    else
		# file have been deleted or renamed or moved
		unset FILES["$filesInArray"]
		
		# unsets the size of the file
		unset FILESIZE["$filesInArray"]

		# emit deleteFile event
		# only argument is $filesInArray
		event emit deleteFile "'$filesInArray'"
		return 5; # Return status of 5
	    fi


	done
    fi
    return 1

}

directoryFunc() {

    # The only interesting thing here is the return code
    for folderInArray in "${PATHS[@]}";do

	if [[ -e "${folderInArray}" ]];then
	    # folder is a local variable in blindfold, but since
	    #    directoryFunc is called in blindfold,
	    #    directoryFunc now have access to all blindfold local variables
	    #                ***** think closure ****
	    if [[ "${folderInArray}" == "$folder" ]];then

		# Do nothing, but return 0
		#   the reason is because since all the folders is initalized in PATHS
		#   there is no need to check if anything fancy is going on in the pwd, blindfold will be called
		#   forever, and fileFunc will handle any change in files
	       return 0;
	    fi
	fi

    done
    return 1
}

blindfold() {


    if (( "${#@}" == 0 ));then
	printf "%s\n" "No Folders were specified"
	printf "%s\n" "You have to specify the folders to watch as arguments"
	return 1
    fi

    
    local files folder status
    
    which stat 1>/dev/null
    
    status=$?
    
    (( status == 1 )) && {
	printf "%s\n" "blindfold depends on stat"
	printf "%s\n" "install stat then rerun this program"
	exit 1;
    }

    # initialize the size
    declare -A FILESIZE
    # create an array to handle files
    
    declare -A FILES

    #local execCommand
    
    # Set paths in an Array
    declare -A PATHS
    for paths ;do

	[[ -e "${paths}" ]] && {
	    which readlink 1>/dev/null
	    
	    status=$?

	    (( status == 0 )) && {
		paths=$(readlink -f "${paths}") ; # eleminate nonsence relative paths
		#execCommand="readlink -f"
	    } || {
		which realpath 1>/dev/null
		status=$?
		(( status == 0 )) && {
		    paths=$(realpath "${paths}"); # eleminate nonsence relative paths
		    #execCommand=realpath
		} || {
		    if [[ "$paths" =~ (../|./|.) ]];then
			printf "%s\n" "Cannot parse a relative path"
			printf "%s\n" "relative paths crashes blindfold"
			printf "%s\n" "install readlink or realpath"
			#unset execCommand
			exit 1;
		    fi
		}
	    }

	    ###################################################################################################
	    #if [[ -f "${paths}" ]];then
	    #
	    #FILES["${paths}"]="${paths}"
	    #
	    #PATHS["$(dirname "${FILES["$paths"]}" )"]=$($execCommand $(dirname ${FILES["${paths}"]}))
	    #
	    #
	    # this elif can be eliminated with a continue statement,
	    #     but to avoid the user specifing a path that is not a file or directory an elif is used
	    #     if an invalid path is found maybe a socket file or a block or character file ,
	    #     blindfold ignores it silently
	    #     if only a socket file or a block or character file was specified,
	    #     blindfold gets stuck in an event loop
	    #     Hit ctrl + c to close
	    #####################################################################################################
		
	    if [[ -d "${paths}" ]];then
		PATHS["$paths"]="${paths}"
	    fi
	} || {
	    printf "%s\n" "${paths} cannot be initialized because it cannot be located"
	    printf "%s\n" "Exiting..."
	    return 100
	}
    done

    while true;do

	for watchingPath in "${!PATHS[@]}";do
	    
	    
	    if [[ ! -e "${PATHS[$watchingPath]}" ]];then

		# unset any deleted directory
		unset PATHS["$watchingPath"]

		# emit deleteFolder event

		# pass in only one argument which is the deleted file name
		event emit deleteFolder "'${PATHS[$watchingPath]}'"
		continue ;
	    fi
	    
	    
	    cd "${PATHS[$watchingPath]}"
	    
	    for list in *;do

		if [[ -f "${list}" ]];then

		    files="${PATHS[$watchingPath]}/${list}"
		    
		    fileFunc #"$files"

		    status=$?

		    (( status == 1 )) && {
			    # pass in the path were the file was changed as first argument and the file name as second
			    #   argument, also pass in the file permission
			event emit newFile "'${PATHS[$watchingPath]}' '${files}'"
			FILES["$files"]="$files"
			FILESIZE["$files"]="$(stat --format="%s" "$files" )"
		    }

		elif [[ -d "${list}" ]];then

		    folder="${PWD}/${list}"

		    directoryFunc #"$folder"

		    status=$?

		    (( status == 1 )) && {
			
			# emit the newDir event
			# pass in the parent directory and the current directory name
			event emit newDir "'${PATHS[$watchingPath]}' '${folder}'"
			
			PATHS["$folder"]="$folder"
		    }
		fi

	    done

	done

    done
}

ne() {
    echo $1

}
nf() {
    echo "new file detected $2"
    #if [[ "${2##*.}" == 'js' ]];then
    #	traceur "$2" --out "../we.js"
    #fi

}
nd() {
    echo "new disrectory $2"
}
mf() {
    
    for i in "${@}" ;do
	echo $i
    done
}

blindfold "${@}"

