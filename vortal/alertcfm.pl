 - no session check

 global variable = error-msg

 input 
	portal-id		(pid)
	category/categories	(cat)
	subscriber email id	(email)
	verification-code	(verify)

 main
	do edit/process
	if return-code == 0
		html = alert confirmed page
	else
		html = confirm page with error message
	end-if
	print html

 edit/process
	validate pid+cat+email existing in 
		alertprof-dbfile, alert-dbfile, and catalert-dbfile
	if error
		error-msg = nothing to confirm, probably alerts expired
		return 1
	else
		if adddatetime == verification-code
			if status == 'P'
				change status to 'C' (confirmed)
			end-if
		else
			error-msg = invalid verification code
			return 1
		end-if
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
		