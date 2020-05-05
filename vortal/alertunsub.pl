 - no session check

 global variable = error-msg

 input 
	portal-id		(pid)
	category/categories	(cat)
	subscriber email id	(email)

 main
	do edit
	if return-code == 0
		html = 'you have been unsubscribed' page
	else
		html = same page with error message
	end-if
	print html

 edit/process
	validate existance of pid+email+cat with status 'C'
	if not present
		error-msg = the alert was not subscribed, so no action was taken
		return 1
	end-if

	delete record in alertprof-dbfile with status = 'C'
	delete record in alert-dbfile with status = 'C'
	if error
		error-msg = database error
		return 1
	end-if

	return 0

 DBM-database
	users/pid/
		catalert
		  category,emailid,adddate,status	(for category subs)
		alert
		  emailid,adddate,status		(for entire portal subs)
		alertprof
		  emailid,category,adddate,status	(for maintenance)

 mysql-database
	users/
		catalert
		  pid,category,emailid,adddate,status	(for category subs)
			index on pid,category
			index on emailid
		alert
		  pid,emailid,adddate,status		(for entire portal subs)
			index on pid
			index on emailid
		