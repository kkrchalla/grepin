Templates - Unlimited

New dbm files
	top_bar_html
	bot_bar_html
	left_bar_html

New fields
	template number
	Title of the template

Screens
	1) List of Templates Screen
		Template#	Title		Action
		nn		xxxxxxxxx	Preview / Basic Edit / Advance Edit / Delete

	2) Basic Edit -> Preview -> Confirm

	3) Advance Edit -> Preview -> Confirm

	4) Preview

	5) Delete Confirm


Code Logic

	if cmd = lst
		display list screen
	if cmd = prv
		preview
	if cmd = badd
		display basic add screen
		if fn = prv
			badd to preview screen
		if fn = cfm
			confirm add
	if cmd = aadd
		display advance add screen
		if fn = prv
			aadd to preview screen
		if fn = cfm
			confirm add
	if cmd = bedit
		basic edit screen
		if fn = prv
			bedit to preview screen
		if fn = cfm
			confirm update
	if cmd = aedit
		advance edit screen
		if fn = prv
			aedit to preview screen
		if fn = cfm
			confirm update
	if cmd = del
		delete confirm screen
		if fn = del
			delete and then list screen

	