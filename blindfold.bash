#!/usr/bin/env bash

source ../bashevents/emitter.bash


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
		return 0; # Return status of 5
	    fi


	done
    fi
    return 1

}

directoryFunc() {

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
    # create an array to handle files

    declare -A FILES

    # Set paths in an Array
    declare -A PATHS
    for paths ;do

	[[ -e "${paths}" ]] && {
	    which readlink 1>/dev/null
	    status=$?

	    (( status == 0 )) && {
		paths=$(readlink -f "${paths}") ; # eleminate nonsence relative paths
	    } || {
		which realpath 1>/dev/null
		status=$?
		(( status == 0 )) && {
		    paths=$(realpath "${paths}"); # eleminate nonsence relative paths
		} || {
		    if [[ "$paths" =~ (../|./|.) ]];then
			printf "%s\n" "Cannot parse a relative path"
			printf "%s\n" "install readlink or realpath"
			exit 1;
		    fi
		}
	    }


	    if [[ -f "${paths}" ]];then
		FILES["${paths}"]="${paths}"
		# this elif can be eliminated with a continue statement,
		#     but to avoid the user specifing a path that is not a file or directory an elif is used
		#     if an invalid path is found maybe a socket file or a block or character file ,
		#     blindfold ignores it silently
	    elif [[ -d "${paths}" ]];then
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


	    if [[ ! -d "${PATHS[$watchingPath]}" ]];then
		unset PATHS["$watchingPath"]
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
		    }

		elif [[ -d "${list}" ]];then

		    folder="${PWD}/${list}"

		    directoryFunc #"$folder"

		    status=$?

		    (( status == 1 )) && {
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
    echo "new directory $2"
}
mf() { : ;}
df() {

    echo "file has been deleted $1"
}

dff() {
    echo "folder deleted"
}

event attach noExist ne
event attach newFile nf
event attach newDir nd
event attach modifyFile mf
event attach deleteFile df
event attach deleteFolder dff
blindfold "${@}"

