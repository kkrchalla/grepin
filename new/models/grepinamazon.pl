#!/usr/bin/perl

  use Fcntl;
  use CGI;
  package main;

  my $query = new CGI;
  my $user_id    = $query->param('uid');	# user id
  my $search     = $query->param('query');	# search keyword
  my $mode       = $query->param('category');	# books, music, ....
  my $browse_id  = $query->param('browseid');	
  my $item_id    = $query->param('itemid');	# specific item id
  my $output_type = $query->param('out');	# output type, html or javascript, default=html
  my $locale     = $query->param('locale');	# us or uk, default = us
  my $input_page = $query->param('page');	# page number in results, default = 1
  my $user_aid   = $query->param('aid');	# user amazon associate id
  my $top_bar    = $query->param('top');	# 'yes'= top bar with the same specs is present, default='no'
  my $right_bar  = $query->param('right');    	# 'yes'= this is the right bar, default='no'

# http://www.grepin.com/cgi-bin/amznbar.pl?query=&category=&browseid=&itemid=&out=&locale=&page=&aid=&uid=&top=&right=

# for best effect you should add a Unicode charset META tag to the <HEAD> of your page
# like this: <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=utf-8">

# required options
my $associate_id    = "grepinsearcha-20";
my $uk_associate_id = "grepinsearcha-21";
my $developer_token = "0GNH1BCCTATJ7KASPB82";

my $xml_page = 1;
my (%browse_ids, $xml_result, @Details, $this_xml_url, $error_msg, $total_results, $total_pages);
my ($random_details_1, $random_details_2, $random_details_3, $random_details_4);
my ($result_link_1, $result_link_2, $result_link_3, $result_link_4);
my ($xml_asin_1, $xml_asin_2, $xml_asin_3, $xml_asin_4);
my ($xml_prod_name_1, $xml_prod_name_2, $xml_prod_name_3, $xml_prod_name_4);
my ($xml_catalog_1, $xml_catalog_2, $xml_catalog_3, $xml_catalog_4);
my ($xml_image_s_1, $xml_image_s_2, $xml_image_s_3, $xml_image_s_4);
my ($xml_image_m_1, $xml_image_m_2, $xml_image_m_3, $xml_image_m_4);
my ($xml_image_l_1, $xml_image_l_2, $xml_image_l_3, $xml_image_l_4);
my ($xml_list_price_1, $xml_list_price_2, $xml_list_price_3, $xml_list_price_4);
my ($xml_our_price_1, $xml_our_price_2, $xml_our_price_3, $xml_our_price_4);
my ($xml_used_price_1, $xml_used_price_2, $xml_used_price_3, $xml_used_price_4);

# setup initial variables
# kishore should add one for 'all products'
if (($locale ne "us") && ($locale ne "uk")) { $locale = "us"; }
if ($locale eq "uk") {
	$amazon_site   = "Amazon.co.uk";
	$amazon_server = "xml-eu";
        $associate_id  = $uk_associate_id;
	%browse_ids = ( "books_uk" => 1025612, "music" => 694208, "classical" => 229817, "dvd_uk" => 655852, "vhs_uk" => 573400, "electronics_uk" => 560800, "kitchen_uk" => 3147411, "software_uk" => 1025614, "video_games_uk" => 1025616, "toys_uk" => 595314 );
} else {
	$amazon_site = "Amazon.com";
	$amazon_server = "xml";
	%browse_ids = ( baby => 540988, books => 1000, classical => 85, dvd => 404276, electronics => 493964, garden => 468250, kitchen => 491864, magazines => 599872, music => 301668, pc_hardware => 565118, photo => 508048, software => 491286, toys => 491290, universal => 468240, vhs => 404274, videogames => 471280 );
}
if (!$user_aid) { $user_aid = $associate_id; }
if (!$mode) { $mode = ((keys %browse_ids)[int rand keys %browse_ids]); } 
if (!$browse_id) { $browse_id = $browse_ids{$mode}; };
$mode =~ s/_/-/g;
if ($search) {
	$search =~ s/\s/\%20/g;
	$this_xml_url = "http://$amazon_server.amazon.com/onca/xml3?t=$associate_id&dev-t=$developer_token&KeywordSearch=$search&mode=$mode&type=lite&page=$xml_page&sort=+salesrank&f=xml&locale=$locale"; 
} elsif ($item_id) {
	$this_xml_url = "http://$amazon_server.amazon.com/onca/xml3?t=$associate_id&dev-t=$developer_token&AsinSearch=$item_id&type=lite&f=xml&locale=$locale";
} else {
	$this_xml_url = "http://$amazon_server.amazon.com/onca/xml3?t=$associate_id&dev-t=$developer_token&BrowseNodeSearch=$browse_id&mode=$mode&type=lite&page=$xml_page&sort=+salesrank&f=xml&locale=$locale";
}

# request the XML
eval 'use LWP::Simple qw($ua get)'; if ($@) { print "Content-type: text/html\n\n"; print "Unable to use LWP::Simple and this script cannot function without it.\n"; exit; }
$ua->timeout(15);
$xml_result = get($this_xml_url);

if (!$xml_result) { $error_msg = "Sorry, we are currently unable to process your request in a timely manner.<BR>Please try again later.\n"; exit; }

# get all the products and shuffle them
$xml_result =~ s/<TotalResults(?:\s[^>]+)?>(.*?)<\/TotalResults>/$total_results = $1;/gsie;
$xml_result =~ s/<TotalPages(?:\s[^>]+)?>(.*?)<\/TotalPages>/$total_pages = $1;/gsie;
$xml_result =~ s/<Details(?:\s[^>]+)?>(.*?)<\/Details>/push @Details, $1;/gsie;

# get 4 random_details
if (@Details) {
	if ($total_results <= 4) {
		$random_details_1 = $Details[1];
		$random_details_2 = $Details[2];
		$random_details_3 = $Details[3];
		$random_details_4 = $Details[4];
	} else {
		$random_details_1 = $Details[rand @Details];
		$random_details_2 = $Details[rand @Details];
		while ($random_details_2 eq $random_details_1) {
			$random_details_2 = $Details[rand @Details];
		}
		$random_details_3 = $Details[rand @Details];
		while (($random_details_3 eq $random_details_1) || ($random_details_3 eq $random_details_2)) {
			$random_details_3 = $Details[rand @Details];
		}
		$random_details_4 = $Details[rand @Details];
		while (($random_details_4 eq $random_details_1) || ($random_details_4 eq $random_details_2) || ($random_details_4 eq $random_details_3)) {
			$random_details_4 = $Details[rand @Details];
		}
	}
} else {
	$error_msg = "Sorry no results are currently being returned for this query.";
	$xml_result =~ s/<ErrorMsg>([^<]+)<\/ErrorMsg>/$error_msg = $1;/esi;
}

# assign variables
# kishore - this is the place where all the variables get their values
# kishore - add for 3 more random_details and result_links
# kishore - somehow make all the other variables to be in array
$random_details_1 =~ s/<([^>]+)>([^<]+)<\/\1>/${$1} = $2;/gsie;
$xml_asin_1       = $Asin;
$xml_prod_name_1  = $ProductName;
$xml_catalog_1    = $Catalog;
$xml_image_s_1    = $ImageUrlSmall;
$xml_image_m_1    = $ImageUrlMedium;
$xml_image_l_1    = $ImageUrlLarge;
$xml_list_price_1 = $ListPrice;
$xml_our_price_1  = $OurPrice;
$xml_used_price_1 = $UsedPrice;

if ($random_details_2) {
  $random_details_2 =~ s/<([^>]+)>([^<]+)<\/\1>/${$1} = $2;/gsie;
  $xml_asin_2       = $Asin;
  $xml_prod_name_2  = $ProductName;
  $xml_catalog_2    = $Catalog;
  $xml_image_s_2    = $ImageUrlSmall;
  $xml_image_m_2    = $ImageUrlMedium;
  $xml_image_l_2    = $ImageUrlLarge;
  $xml_list_price_2 = $ListPrice;
  $xml_our_price_2  = $OurPrice;
  $xml_used_price_2 = $UsedPrice;
}
if ($random_details_3) {
  $random_details_3 =~ s/<([^>]+)>([^<]+)<\/\1>/${$1} = $2;/gsie;
  $xml_asin_3       = $Asin;
  $xml_prod_name_3  = $ProductName;
  $xml_catalog_3    = $Catalog;
  $xml_image_s_3    = $ImageUrlSmall;
  $xml_image_m_3    = $ImageUrlMedium;
  $xml_image_l_3    = $ImageUrlLarge;
  $xml_list_price_3 = $ListPrice;
  $xml_our_price_3  = $OurPrice;
  $xml_used_price_3 = $UsedPrice;
}
if ($random_details_4) {
  $random_details_4 =~ s/<([^>]+)>([^<]+)<\/\1>/${$1} = $2;/gsie;
  $xml_asin_4       = $Asin;
  $xml_prod_name_4  = $ProductName;
  $xml_catalog_4    = $Catalog;
  $xml_image_s_4    = $ImageUrlSmall;
  $xml_image_m_4    = $ImageUrlMedium;
  $xml_image_l_4    = $ImageUrlLarge;
  $xml_list_price_4 = $ListPrice;
  $xml_our_price_4  = $OurPrice;
  $xml_used_price_4 = $UsedPrice;
}

$result_link_1 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_1/ref=nosim/$associate_id?dev-t=$developer_token";
$result_link_2 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_2/ref=nosim/$user_aid?dev-t=$developer_token";
$result_link_3 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_3/ref=nosim/$associate_id?dev-t=$developer_token";
$result_link_4 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_4/ref=nosim/$user_aid?dev-t=$developer_token";

# display result
# kishore if error message, change the look and feel - probably create a sub set_error_message
# kishore should be different subs for different looks like bars and skyscrapers

if ($right = 'yes') {
  my $html = set_tower_html();
} else {
  my $html = set_bar_html();
}
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

# between the qq[ and ]; is the HTML that formats the result. feel free to change it to whatever you want
# possible variables are: $result_link, $Asin, $ProductName, $Catalog, $ReleaseDate, $Manufacturer, $ImageUrlSmall, $ImageUrlMedium, $ImageUrlLarge, $ListPrice, $OurPrice, $UsedPrice
# kishore - change the look of the box and boxes
sub set_bar_html {
	my $banner_html = qq[

<SCRIPT>function noImageCheck(objImg) { if (objImg.width == 1) { objImg.src = "http://g-images.amazon.com/images/G/01/books/icons/books-no-image.gif"; } } </SCRIPT>
<font face=verdana>
<TABLE Bgcolor="#ffffff" Border="0" Width="1" height="1" cellpadding="0" cellspacing="0">
<TR>
<TD>
<TABLE Bgcolor="#fff000" Border="0" Width="100%" cellpadding="0" cellspacing="1">
<TR>
<TD>
	<TABLE Bgcolor="#ffffff" Border="0" Cellpadding="5" Cellspacing="0" Width="100%" height="100%">
	<TR>
	<TD Align="center">
		<FONT Size="2"><B><A Href="$result_link_1">$xml_prod_name_1</A></B></FONT>
		<BR>
		<A Href="$result_link_1"><IMG Border="0" Src="$xml_image_s_1" onLoad="noImageCheck(this);"></A>
		<BR>
		<FONT Color="red" Size="2"><B>$xml_our_price_1</B></FONT>
	</TD>
	</TR>
	</TABLE>
</TD>
<TD>
	<TABLE Bgcolor="#ffffff" Border="0" Cellpadding="5" Cellspacing="0" Width="100%" height="100%">
	<TR>
	<TD Align="center">
		<FONT Size="2"><B><A Href="$result_link_2">$xml_prod_name_2</A></B></FONT>
		<BR>
		<A Href="$result_link_2"><IMG Border="0" Src="$xml_image_s_2" onLoad="noImageCheck(this);"></A>
		<BR>
		<FONT Color="red" Size="2"><B>$xml_our_price_2</B></FONT>
	</TD>
	</TR>
	</TABLE>
</TD>
<TD>
	<TABLE Bgcolor="#ffffff" Border="0" Cellpadding="5" Cellspacing="0" Width="100%" height="100%">
	<TR>
	<TD Align="center">
		<FONT Size="2"><B><A Href="$result_link_3">$xml_prod_name_3</A></B></FONT>
		<BR>
		<A Href="$result_link_3"><IMG Border="0" Src="$xml_image_s_3" onLoad="noImageCheck(this);"></A>
		<BR>
		<FONT Color="red" Size="2"><B>$xml_our_price_3</B></FONT>
	</TD>
	</TR>
	</TABLE>
</TD>
<TD>
	<TABLE Bgcolor="#ffffff" Border="0" Cellpadding="5" Cellspacing="0" Width="100%" height="100%">
	<TR>
	<TD Align="center">
		<FONT Size="2"><B><A Href="$result_link_4">$xml_prod_name_4</A></B></FONT>
		<BR>
		<A Href="$result_link_4"><IMG Border="0" Src="$xml_image_s_4" onLoad="noImageCheck(this);"></A>
		<BR>
		<FONT Color="red" Size="2"><B>$xml_our_price_4</B></FONT>
	</TD>
	</TR>
	</TABLE>
</TD>
</TR>
</TABLE>
<TABLE>
<TR>
<TABLE Bgcolor="#fff000" Border="0" Cellpadding="0" Cellspacing="0" Width="100%">
<TR>
<TD align="left">
	<FONT Size="1" color=black>&nbsp;In association with $amazon_site</FONT>
</TD>
<TD align="right">
	<FONT Size="1" color=black>powered by <A Href="http://www.grepin.com/">Grepin.com</A></FONT>&nbsp;
</TD>
</TR>
</TABLE>
</TR>
</TABLE>
	];
}



sub set_tower_html {
	my $banner_html = qq[

<SCRIPT>function noImageCheck(objImg) { if (objImg.width == 1) { objImg.src = "http://g-images.amazon.com/images/G/01/books/icons/books-no-image.gif"; } } </SCRIPT>
<font face=verdana>
<TABLE Bgcolor="#aabbaa" Border="0" Width="1" height="1" cellpadding="0" cellspacing="0">
<TR>
<TD>
<TABLE Border="0" Cellpadding="0" Cellspacing="0" Width="100%">
<TR>
<TD align="right">
	<FONT Size="1">powered by <A Href="http://www.grepin.com/">Grepin.com</A></FONT>&nbsp;
</TD>
</TR>
</TABLE>
<TABLE Bgcolor="#aabbaa" Border="0" Width="100%" height="1" cellpadding="0" cellspacing="1">
<TR>
<TD>
	<TABLE Bgcolor="#ffffff" Border="0" Cellpadding="5" Cellspacing="0" Width="100%" height="100%">
	<TR>
	<TD Align="center">
		<FONT Size="2"><B><A Href="$result_link_1">$xml_prod_name_1</A></B></FONT>
		<BR>
		<A Href="$result_link_1"><IMG Border="0" Src="$xml_image_s_1" onLoad="noImageCheck(this);"></A>
		<BR>
		<FONT Color="red" Size="2"><B>$xml_our_price_1</B></FONT>
	</TD>
	</TR>
	</TABLE>
</TD>
</TR>
<TR>
<TD>
	<TABLE Bgcolor="#ffffff" Border="0" Cellpadding="5" Cellspacing="0" Width="100%" height="100%">
	<TR>
	<TD Align="center">
		<FONT Size="2"><B><A Href="$result_link_2">$xml_prod_name_2</A></B></FONT>
		<BR>
		<A Href="$result_link_2"><IMG Border="0" Src="$xml_image_s_2" onLoad="noImageCheck(this);"></A>
		<BR>
		<FONT Color="red" Size="2"><B>$xml_our_price_2</B></FONT>
	</TD>
	</TR>
	</TABLE>
</TD>
</TR>
<TR>
<TD>
	<TABLE Bgcolor="#ffffff" Border="0" Cellpadding="5" Cellspacing="0" Width="100%" height="100%">
	<TR>
	<TD Align="center">
		<FONT Size="2"><B><A Href="$result_link_3">$xml_prod_name_3</A></B></FONT>
		<BR>
		<A Href="$result_link_3"><IMG Border="0" Src="$xml_image_s_3" onLoad="noImageCheck(this);"></A>
		<BR>
		<FONT Color="red" Size="2"><B>$xml_our_price_3</B></FONT>
	</TD>
	</TR>
	</TABLE>
</TD>
</TR>
<TR>
<TD>
	<TABLE Bgcolor="#ffffff" Border="0" Cellpadding="5" Cellspacing="0" Width="100%" height="100%">
	<TR>
	<TD Align="center">
		<FONT Size="2"><B><A Href="$result_link_4">$xml_prod_name_4</A></B></FONT>
		<BR>
		<A Href="$result_link_4"><IMG Border="0" Src="$xml_image_s_4" onLoad="noImageCheck(this);"></A>
		<BR>
		<FONT Color="red" Size="2"><B>$xml_our_price_4</B></FONT>
	</TD>
	</TR>
	</TABLE>
</TD>
</TR>
</TABLE>
<TABLE>
<TR>
<TABLE Border="0" Cellpadding="0" Cellspacing="0" Width="100%">
<TR>
<TD align="right">
	<FONT Size="0">with $amazon_site&nbsp;</FONT>
</TD>
</TR>
</TABLE>
</TR>
</TABLE>
	];
}

