# Blindfold is a bash script that watches for changes in a file and directory

Blindfold uses emitter library for fake/custom event listening


# Need to know 


The following list of events are already emitted in blindfold.bash
all you need to do is attach the event and sepcify a function to execute whenever the event is emitted

list of emitted event that you should attach

1. newFile `when a new file is created`
2. modifyFile `when a file is edited`
3. deleteFile `when a file is deleted`
4. newDir `when a new directory is created`
5. deleteFolder `when a folder is deleted`

you should attach the event like this

```bash
    event attach newFile functionToExecute
```

```bash
    event attach modifyFile functionToExecute
```

```bash
    event attach deleteFile functionToExecute
```

```bash
    event attach newDir functionToExecute
```

```bash
    event attach deleteFolder functionToExecute
```



# How to use


> using blindfold with traceur 

you have to source blindfold in your script
```bash
    source ../blindfold.bash
```

```bash
# This function will be executed when a new file is created
_nfile() {
	local newfile=$2
	if [[ "${newfile##*.}" != 'js' ]];then
		printf "%s\n%s" "only javascript file are strictly allowed here" "this file has been moved to /tmp"
		mv "$newfile" /tmp
		return ;
	fi
	printf "%s\n" "javascript file detected , now watching $newfile"
}

```

```bash 
# This function will be executed when a file is modified
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
```

```bash
# This function will be executed when a file is deleted
_ndeletefile() {
	local filedel="${1}"
	printf "%s\n" "${filedel} removed from watch list"
}
```

```bash
# This function will be executed when a new directory is created
_nDir() {
	local newdire="${2}"
	printf "%s\n" "${newdire} added to watch list"
}

```

```bash
# This function will be executed when a folder is deleted
_ndeleteDir() {
	local deldir="${1}"
	printf "%s\n" "${deldir} has been deleted including all files and subfolder"
}
```

next thing to do is to attach the events


```bash
    event attach newFile _nfile
```

```bash
    event attach modifyFile _nmodfile
```

```bash
    event attach deleteFile _ndeletefile
```

```bash
    event attach newDir _nDir
```

```bash
    event attach deleteFolder _ndeleteDir
```

after attaching the listeners call the blindfold function

```bash
    blindfold "${@}"
```

# arguments passed to listeners 

1. when a new file is created , `newFile` listener is emitted 
and two argument is passed to the function that will be executed when the event is emitted
    
    first_arg > the directory the file was created

    second_arg > new file name

2. when a file is modified , `modifyFile` listener is emitted
and seven argument is passed to the function that will be executed

    first_arg > file name

    second_arg > group id

    third_arg > group owner id

    fourt_arg > hexadecimal value for access right

    fifth_arg > user id

    sixth_arg > user owner name

    seventh_arg > size of the file in bytes

3. when a file is deleted , `deleteFile` listener is emitted
and a single argument is passed to the function to execute

    first_arg > name of deleted file

4. when a directory is created, `newDir` listener is emitted
and two argument are passed to the function to execute

    first_arg > name of parent folder

    second_arg > name of new folder

5. when a directory is deleted, `deleteFolder` listener is emitted
and a single argument is passed to the function to execute

    firsrt_arg > name of deleted file


# Note
1. blindfold only accepts directory names . It can take more than one directory
2. blindfold ignores arguments that are regular or charcter or socket or block files and gets stuck in its event loop

# Dependencies
1. readlink or realpath
2. stat

# emitter library

[emitter library](https://github.com/zombieleet/emitter.git)

# License
UAHYW ( USE ANY HOW YOU WANT ) lol