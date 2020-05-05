 - batch program
 - no session check

 global variables
	currenttime = time()

 input 
	none

 main
	for each pid
		for each record in alert-dbfile
			if (status == 'C')
				do sendalert
			end-if
		end-for
		for each record in catalert-dbfile
			if (status == 'C')
				do sendalert
			end-if
	    	end-for
		delete all the changelog records whose eventtime < currenttime
	end-for

	exit

 sendalert
	for each record in changelog-dbfile
		if eventtime < currenttime
			email text .= content with add or delete tag
		end-if
	end-for

	build email with subject, and unsubscribe link

	send email
	if error
		add this record to retryalert-dbfile
	end-if
	return 0


 DBM-database
	users/pid/
		alert
		  emailid,adddate,status		(for entire portal subs)
		catalert
		  category,emailid,adddate,status	(for category subs)
		changelog
		  category,url,event(add or delete),title,description,eventtime
		retryalert
		  email,subject,message

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
		changelog
		  pid,category,url,event(add or delete),title,description,eventtime
		retryalert
		  email,subject,message
