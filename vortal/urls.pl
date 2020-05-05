 - online program
 - session check

 global variable = 	error-msg
			html
			working-storage-fields
				w_catid,w_title,w_desc,w_path,@w_url_array,@w_title_array,@w_desc_array,@w_kwd_array

 input 
	command 		(cmd)
	portal-id		(pid)
	session-id		(sid)
	url0			(url0)
	url1			(url1)
	url2			(url2)
	url3			(url3)
	url4			(url4)
	url5			(url5)
	url6			(url6)
	url7			(url7)
	url8			(url8)
	url9			(url9)
	title0 			(title0)
	title1 			(title1)
	title2 			(title2)
	title3 			(title3)
	title4 			(title4)
	title5 			(title5)
	title6 			(title6)
	title7 			(title7)
	title8 			(title8)
	title9 			(title9)	
	description0 		(desc0)
	description1 		(desc1)
	description2 		(desc2)
	description3 		(desc3)
	description4 		(desc4)
	description5 		(desc5)
	description6 		(desc6)
	description7 		(desc7)
	description8 		(desc8)
	description9 		(desc9)
	keywords0		(kwd0)
	keywords1		(kwd1)
	keywords2		(kwd2)
	keywords3		(kwd3)
	keywords4		(kwd4)
	keywords5		(kwd5)
	keywords6		(kwd6)
	keywords7		(kwd7)
	keywords8		(kwd8)
	keywords9		(kwd9)
	catlist0		(catlst0)
	catlist1		(catlst1)
	catlist2		(catlst2)
	catlist3		(catlst3)
	catlist4		(catlst4)
	catlist5		(catlst5)
	catlist6		(catlst6)
	catlist7		(catlst7)
	catlist8		(catlst8)
	catlist9		(catlst9)
	newcategory		(newcat)	only for submitted list


		listsub = list submitted urls
		updatesub = accept or reject or remove submitted urls (by checkboxes)
		initadd = blank page for add
		add = add urls for different categories (10 empty buckets for urls to add)
		listbad = list urls reported as bad
		updatebad = keep or delete bad urls (by checkboxes)

		cannot modify the path for a category - to do this the category has to be deleted from this path 
			and a new one should be created in another path
		cannot update url in a category - to do this, the url has to deleted and a new one has to be created

 main
	error-msg = undef

	if session is invalid
		redirect to logon page with error
			webscr.pl?cmd=logon&fn=error
		exit
	end-if

	if cmd = 'listsub'
		do listsub
		do listsubpage with listsub-return-code
	elsif cmd = 'updatesub'
		do updatesub
		do updatesubpage with updatesub-return-code
	elsif cmd = 'initadd'
*		do initaddpage
*	elsif cmd = 'add'
		do add
		do addpage with add-return-code
	elsif cmd = 'listbad'
		do listbad
		do listbadpage with listbad-return-code
	elsif cmd = 'updatebad'
		do updatebad
		do updatebadpage with updatebad-return-code
	else
		do urlhomepage
	end-if
	print html


 initaddpage
	html = init blank url-add page

 add
	workingstoragefields = undef;
	change to lower case
	remove extra spaces
	populate workingstoragefields with the input data
		if (url1 || title1 || desc1 || catlist1)
			populate url data into w-url-array
			populate tite data into w-title-array
			populate desc data into w-desc-array
			populate keyword data into w-kwd-array
			populate catlist data into w-catlist-array
		end-if
		repeat for all 10
	validate input fields
		url, title, description (url should have corresponding title and description), keyword is not required
			for each @url-array
				if !(w_url_array[$_] && w_title_array[$_] && w_desc_array[$_] && w_catlist_array[$_])
					if (error-msg)
						error-msg .= ' - incomplete data regarding URLs. should have all 3'
					else
						error-msg = 'incomplete data regarding URLs. should have all 3'
					end-if
					return 1
				end-if
			end-for

	add records to caturl-dbfile
	add records to toindex-dbfile
	add records to changelog-dbfile

	if error
		if (error-msg)
			error-msg .= database error
		else
			error-msg = database error
		end-if
		return 99
	end-if

	return 0	


 addpage
	if add-return-code == 0
		if (error-msg)
			error-msg .= " - urls added"
		else
			error-msg = "urls added"
		end-if
		html = blank url-add page with just error message
	else
		html = url-add page with workingstoragefields and error message
	end-if

 addurl
	working-storage-fields = undef
		($catid, $title, ...) = undef;
	change to lower case
	remove extra spaces
	populate workingstoragefields with the input data
		if (url1 || title1 || desc1)
			populate url data into w-url-array
			populate tite data into w-title-array
			populate desc data into w-desc-array
		end-if
		repeat for all 10
	validate input fields
		url, title, description (url should have corresponding title and description)
			for each @url-array
				if !(w_url_array[$_] && w_title_array[$_] && w_desc_array[$_])
					if (error-msg)
						error-msg .= ' - incomplete data regarding URLs. should have all 3'
					else
						error-msg = 'incomplete data regarding URLs. should have all 3'
					end-if
					return 1
				end-if
			end-for
		read caturl-dbfile for all the records with this catid
			foe each @w_url_array
				read caturl-dbfile for all the records with this catid
				if this url is present 
					if (error-msg)
						error-msg .= ' - url $w_url_array[$_] is already present for this category'
					else
						error-msg = 'url $w_url_array[$_] is already present for this category'
					end-if
					return 1
				end-if
			end-for

	add records to caturl-dbfile
	end-for
	add records to toindex-dbfile
	add records to changelog-dbfile

	if error
		if (error-msg)
			error-msg .= database error
		else
			error-msg = database error
		end-if
		return 99
	end-if

	return 0	


 addurlpage
	if addurl-return-code == 0
		if (error-msg)
			error-msg .= " - url added"
		else
			error-msg = "url added"
		end-if
		do view
		do viewpage using view-return-code
	else
		html = cat-edit page with workingstoragefields and error message
	end-if


 update
	* updates on the category title and description
	* does not update the urls - should use the edit url link
	* does not update the path
	working-storage-fields = undef
		($catid, $title, ...) = undef;
	change to lower case
	remove extra spaces
	populate workingstoragefields with the input data
		if (url1 || title1 || desc1)
			populate url data into w-url-array
			populate tite data into w-title-array
			populate desc data into w-desc-array
		end-if
		repeat for all 10
	validate input fields
		category name	required
			if (error-msg)
				error-msg .= ' - category name is required'
			else
				error-msg = 'category name is required'
			end-if
			return 1
		category desc	required
			if (error-msg)
				error-msg .= ' - category description is required'
			else
				error-msg = 'category description is required'
			end-if
			return 1

	if title is different
		update record to catpath-dbfile
	end-if
	update record to catprof-dbfile

	if error
		if (error-msg)
			error-msg .= database error
		else
			error-msg = database error
		end-if
		return 99
	end-if

	return 0	


 updatepage
	if update-return-code == 0
		if (error-msg)
			error-msg .= " - category updated"
		else
			error-msg = "category updated"
		end-if
		do view
		do viewpage using view-return-code
	else
		html = cat-edit page with workingstoragefields and error message
	end-if

 editurl
	working-storage-fields = undef
		($catid, $title, ...) = undef;
	validate catid+url
	if error
		if (error-msg)
			error-msg .= ' - invalid category and url'
		else
			error-msg = invalid category and url
		end-if
		return 1
	end-if

	read the catprof-dbfile, caturl-dbfile
	if error
		if (error-msg)
			error-msg .= ' - database error'
		else
			error-msg = database error
		end-if
		return 99
	end-if

	populate the workingstoragefields with category data, url, url title, url description

	return 0

 editurlpage
	html = cat-edit-url page with workingstoragefields and error-msg



 updateurl
	* cannot change the url
	working-storage-fields = undef
		($catid, $title, ...) = undef;
	change to lower case
	remove extra spaces
	populate workingstoragefields with the input data
	validate input fields
		url title	required
			if (error-msg)
				error-msg .= ' - url name is required'
			else
				error-msg = 'url name is required'
			end-if
			return 1
		url desc	required
			if (error-msg)
				error-msg .= ' - url description is required'
			else
				error-msg = 'url description is required'
			end-if
			return 1

	update record to caturl-dbfile
	add records to changelog-dbfile

	if error
		if (error-msg)
			error-msg .= database error
		else
			error-msg = database error
		end-if
		return 99
	end-if

	return 0	


 updateurlpage
	if updateurl-return-code == 0
		if (error-msg)
			error-msg .= " - url updated"
		else
			error-msg = "url updated"
		end-if
		do view
		do viewpage using view-return-code
	else
		html = cat-edit-url page with workingstoragefields and error message
	end-if

 delpage
	html = cat-del-cfm page with data

 delcfm
	working-storage-fields = undef
		($catid, $title, ...) = undef;
	populate workingstoragefields with the input data

	read catprof-dbfile for catid and get the path of its super-category
	thispath = super-path . '-' . $catid
	read catpath-dbfile with thispath
		if there are any records found
			if (error-msg)
				error-msg .= ' - cannot delete this category due to its subcategories'
			else
				error-msg = 'cannot delete this category due to its subcategories'
			end-if
			return 1
		end-if

	delete catpath-dbfile for which the catid is this catid
	delete catprof-dbfile for this catid
	delete caturl-dbfile for this catid
	delete path-dbfile for 'thispath'
	add records to todeindex-dbfile
	add records to changelog-dbfile

	if error
		if (error-msg)
			error-msg .= database error
		else
			error-msg = database error
		end-if
		return 99
	end-if

	return 0	


 delcfmpage
	if delcfm-return-code == 0
		if (error-msg)
			error-msg .= " - category deleted"
		else
			error-msg = "category deleted"
		end-if
		do list
		do listpage using list-return-code
	else
		html = cat-del-error page with workingstoragefields and error message
	end-if

 delurlpage
	html = cat-delurl-cfm page with data


 delurlcfm
	working-storage-fields = undef
		($catid, $title, ...) = undef;
	populate workingstoragefields with the input data

	delete caturl-dbfile for this catid+url
	add records to todeindex-dbfile
	add records to changelog-dbfile

	if error
		if (error-msg)
			error-msg .= database error
		else
			error-msg = database error
		end-if
		return 99
	end-if

	return 0	


 delurlcfmpage
	if delurlcfm-return-code == 0
		if (error-msg)
			error-msg .= " - url deleted"
		else
			error-msg = "url deleted"
		end-if
		do view
		do viewpage using view-return-code
	else
		html = cat-del-url-error page with workingstoragefields and error message
	end-if


 list
	working-storage-fields = undef

	read catprof-dbfile
	if error
		if (error-msg)
			error-msg .= ' - database error'
		else
			error-msg = database error
		end-if
		return 99
	end-if
	populate the workingstoragefields with data

	return 0



 listpage
	html = cat-list page with workingstoragefields and error-msg


 DBM-database
	users/pid/
		catprof
		  catid,title,description,adddate,path
		caturl
		  catid,url,url-title,url-desc,keywords
		toindex
		  url,keywords,time
		todeindex
		  url,keywords,time
		changelog (for alerts)
		  category,url,event,title,description,eventtime
		badurl
		  catid,url
		suburl
		  url,title,description,catid/cattitle,catstatus (o - old, n - new)


 Page

urls submitted with existing categories will display as a list with 2 check boxes
	check box - 1: to accept url
	check box - 2: to reject url

urls submitted with new categories will display as a list with 1 checkbox
	check box - 1: remove url

