 - no session check

 global variable = error-msg

 input 
	command (' ','add')	(cmd)
	portal-id		(pid)
	category/categories	(cat)
	subscriber email id	(email)

 main
	if cmd = 'add'
		do edit
		if return-code == 0
			html = thankyou page
		else
			html = same page with error message
		end-if
	else
		html = init blank page
	end-if
	print html

 edit/process
	validate portal-id
		 the existance of categories
		 email id
	if error
		error-msg = invalid data
		return 1
	end-if

	add a record in alertprof-dbfile with cat = '' and status = 'P'
	add a record in alert-dbfile with status = 'P' (pending)
	for each input category
		add a record in alertprof-dbfile with status = 'P'
		add a record in catalert-dbfile with status = 'P'
	if error
		error-msg = database error
		return 1
	end-if

	build email to subscriber
		You have subcribed for the alert
		please confirm the subscription
		by clicking the following url
		/cgi-bin/alertcfm.pl?email=&cat=
	send the email
	if error
		error-msg = database error or email error
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
		