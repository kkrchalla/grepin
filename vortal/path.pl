 - session check
 - login required
 - online program

 global variable = error-msg

 input 
	session-id		(sid)
	portal-id		(pid)

 main
	check for valid session
	if not valid
		html = 'Authorization failed. You have to login in order to access this page'
	else
		read path-dbfile 
		html = list all the paths
	end-if

	print html

	exit;



 DBM-database
	users/pid/
		path
		  path
		