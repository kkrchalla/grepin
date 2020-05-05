#!/usr/bin/perl
#	version 1.030612,	coded by MrRat - http://www.mrrat.com,  GPL licensed - http://www.opensource.org/licenses/gpl-license.html

# required options
my $associate_id = "freewarfrommrrat";

# basic options
# if you want this script to link to the APF script set the next option to "yes" and put the URL of the APF script in the following option
my $link_to_apf = "no";
my $location_of_apf = "/cgi-bin/amazon_products_feed.cgi";

#  set the locale: "us" or "uk" and if "uk" then you must include your Amazon.co.uk associate id
my $locale = "us";
my $uk_associate_id = "mrratcom-21";

# skip to the bottom "sub set_html" to edit the HTML that displays the result

# for best effect you should add a Unicode charset META tag to the <HEAD> of your page
# like this: <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=utf-8">

#  that's all you need to change. the code is below.


my $developer_token = "D1KQJBNTALRLQH";
my (%browse_ids, $search, $mode, $browse_id, $item_id, $output_type, $xml_result, @Details, $random_details, $result_link, $this_xml_url, $error_msg);

# setup initial variables
get_url_input();
if ($locale eq "uk") {
	$amazon_site = "Amazon.co.uk";
	$amazon_server = "xml-eu";
	$associate_id = $uk_associate_id;
	%browse_ids = ( "books_uk" => 1025612, "music" => 694208, "classical" => 229817, "dvd_uk" => 655852, "vhs_uk" => 573400, "electronics_uk" => 560800, "kitchen_uk" => 3147411, "software_uk" => 1025614, "video_games_uk" => 1025616, "toys_uk" => 595314 );
} else {
	$amazon_site = "Amazon.com";
	$amazon_server = "xml";
	%browse_ids = ( baby => 540988, books => 1000, classical => 85, dvd => 404276, electronics => 493964, garden => 468250, kitchen => 491864, magazines => 599872, music => 301668, pc_hardware => 565118, photo => 508048, software => 491286, toys => 491290, universal => 468240, vhs => 404274, videogames => 471280 );
}
if (!$mode) { $mode = ((keys %browse_ids)[int rand keys %browse_ids]); } 
if (!$browse_id) { $browse_id = $browse_ids{$mode}; };
$mode =~ s/_/-/g;
if ($search) {
	$search =~ s/\s/\%20/g;
	$this_xml_url = "http://$amazon_server.amazon.com/onca/xml3?t=$associate_id&dev-t=$developer_token&KeywordSearch=$search&mode=$mode&type=lite&page=1&sort=+salesrank&f=xml&locale=$locale"; 
} elsif ($item_id) {
	$this_xml_url = "http://$amazon_server.amazon.com/onca/xml3?t=$associate_id&dev-t=$developer_token&AsinSearch=$item_id&type=lite&f=xml&locale=$locale";
} else {
	$this_xml_url = "http://$amazon_server.amazon.com/onca/xml3?t=$associate_id&dev-t=$developer_token&BrowseNodeSearch=$browse_id&mode=$mode&type=lite&page=1&sort=+salesrank&f=xml&locale=$locale";
}

# request the XML
eval 'use LWP::Simple qw($ua get)'; if ($@) { print "Content-type: text/html\n\n"; print "Unable to use LWP::Simple and this script cannot function without it.\n"; exit; }
$ua->timeout(15);
$xml_result = get($this_xml_url);
if (!$xml_result) { $error_msg = "Sorry, we are currently unable to process your request in a timely manner.<BR>Please try again later.\n"; exit; }

# get all the products and shuffle them
$xml_result =~ s/<Details(?:\s[^>]+)?>(.*?)<\/Details>/push @Details, $1;/gsie;
if (@Details) {
	$random_details = $Details[rand @Details];
} else {
	$error_msg = "Sorry no results are currently being returned for this query.";
	$xml_result =~ s/<ErrorMsg>([^<]+)<\/ErrorMsg>/$error_msg = $1;/esi;
}

# assign variables
$random_details =~ s/<([^>]+)>([^<]+)<\/\1>/${$1} = $2;/gsie;
if ($link_to_apf eq "yes") {
	$result_link = $location_of_apf . "?input_search_type=AsinSearch&input_item=$Asin&input_locale=$locale";
} else {
	$result_link = "http://www.$amazon_site/exec/obidos/ASIN/$Asin/ref=nosim/$associate_id?dev-t=D1KQJBNTALRLQH";
}

# display result
my $html = set_html();
if ($error_msg) { $html = $error_msg; }
if ($output_type eq "javascript") {
	$html =~ s/"/'/g;
	$html =~ s/\n/"\);\ndocument.write\("/g;
	$html = qq[document.write("] . $html . qq[");\n];
	$html =~ s/(document.write\(")?<\/?SCRIPT[^>]*>("\);)?//gi;
}
print "Content-type: text/html; charset=utf-8\n\n";
print "$html\n";
exit;

#	the end - subs below


# yep, it's my standard input parser
sub get_url_input {
	my (%FORM,$form_pair,$form_name,$form_value,$item);
	for $form_pair (split(/&/, $ENV{QUERY_STRING})) {
		$form_pair =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$form_pair =~ s/[^\w|\d|\=|\,|\(|\)|\-|\:]/ /g;
		($form_name, $form_value) = split(/=/, $form_pair);
		if ($form_name eq $form_value) { $form_value = ""; }
		$FORM{$form_name} = $form_value;
	}
	foreach $item (@ARGV) {
		($form_name, $form_value) = split(/=/, $item);
		$FORM{$form_name} = $form_value;
	}
	if (%FORM) {
		$search = $FORM{input_string};
		if ($FORM{input_mode} or $FORM{input_id}) { $mode = $FORM{input_mode}; }
		if ($FORM{input_id}) { $browse_id = $FORM{input_id}; }
		if ($FORM{input_item}) { $item_id = $FORM{input_item}; }
		if ($FORM{input_output}) { $output_type = $FORM{input_output}; }
		if ($FORM{input_locale}) { $locale = $FORM{input_locale}; }
	}
}



# between the qq[ and ]; is the HTML that formats the result. feel free to change it to whatever you want
# possible variables are: $result_link, $Asin, $ProductName, $Catalog, $ReleaseDate, $Manufacturer, $ImageUrlSmall, $ImageUrlMedium, $ImageUrlLarge, $ListPrice, $OurPrice, $UsedPrice
sub set_html {
	my $banner_html = qq[

<SCRIPT>function noImageCheck(objImg) { if (objImg.width == 1) { objImg.src = "http://g-images.amazon.com/images/G/01/books/icons/books-no-image.gif"; } } </SCRIPT>
<TABLE Bgcolor="#F1F1F1" Border="1" Width="468"><TR><TD>
<TABLE Border="0" Cellpadding="0" Cellspacing="0" Width="100%"><TR>
<TD Align="left"><A Href="$result_link"><IMG Border="0" Src="$ImageUrlSmall" onLoad="noImageCheck(this);"></A></TD>
<TD Align="center"><FONT Size="4"><B><A Href="$result_link">$ProductName</A></B></FONT><BR><FONT Size="1">In association with $amazon_site</FONT></TD>
<TD Align="right"><FONT Color="red" Size="4"><B>$OurPrice</B></FONT></TD>
</TR></TABLE>
</TD></TR></TABLE>
<FONT Size="1"><A Href="http://www.mrrat.com/scripts.html" Target="_new">script by MrRat</A></FONT>

	];
}
