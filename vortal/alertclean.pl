 - batch program
 - no session check

 input 
	none

 main
	for each record in alertprof-dbfile
		if (status == 'P') && (time() - adddate > 72 hours)
			delete record in alert-dbfile
			delete record in catalert-dbfile
			delete record in alertprof-dbfile
		end-if
	end-for

	exit

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
