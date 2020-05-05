 - no session check

 global variable = error-msg

 input 
	command (' ','add')		(cmd)
	portal-id 			(pid)
	url				(url)
	existing category/categories 	(ecat)
	new categories			(ncat)

 main
	if cmd = 'add'
		do edit/process
		if return-code == 0
			html = same page with error message
		else
			html = thankyou page
		end-if
	else
		html = init blank page with the all the categories (titles) listed in a multiple select box
	end-if
	print html

 edit/process
	validate portal-id - get his emailid
		 url
		 the existance of categories
	if error
		error-msg = invalid data
		return 1
	end-if

	check for the catid+url in the caturl-dbfile
	if present 
		error-msg = url has already present
		return 1
	end-if

	check for the catid+url in the suburl-dbfile
	if present 
		error-msg = url has already been submitted
		return 1
	end-if

	for each category selected
		add url+title+description+catid+o in suburl-dbfile
	end-for
	for each new category recommended
		add url+title+description+cattitle+n in suburl-dbfile
	end-for
	if error
		error-msg = database error
		return 99
	end-if

	return-code = 0


 DBM-database
	users/pid/
		suburl
		  url,title,description,catid/cattitle,catstatus (o - old, n - new)
