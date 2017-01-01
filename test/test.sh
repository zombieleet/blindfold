source ../blindfold.bash


_nfile() {
	local newfile=$2
	if [[ "${newfile##*.}" != 'js' ]];then
		printf "%s\n%s" "only javascript file are strictly allowed here" "this file has been moved to /tmp"
		mv "$newfile" /tmp
		return ;
	fi
	printf "%s\n" "javascript file detected , now watching $newfile"
}

_nmodfile() {
	local filename=${1}
        local access=${4}
	local status
		which traceur 1>/dev/null
		status=$?
		(( status == 0 )) && {
			traceur "${filename}" --out /tmp/bb.js 2>/dev/null
			status=$?
			(( status == 0 )) && {
				printf "%s\n" "This file has been transpiled successfully"
			} || {
				printf "%s\n" "Error transpiling file"
			}
		}
}

_ndeletefile() {
	local filedel="${1}"
	printf "%s\n" "${filedel} removed from watch list"
}

_nDir() {
	local newdire="${2}"
	printf "%s\n" "${newdire} added to watch list"
}

_ndeleteDir() {
	local deldir="${1}"
	printf "%s\n" "${deldir} has been deleted including all files and subfolder"
}

event attach newFile _nfile
event attach modifyFile _nmodfile
event attach deleteFile _ndeletefile
event attach newDir _nDir
event attach deleteFolder _ndeleteDir


blindfold "${@}"
