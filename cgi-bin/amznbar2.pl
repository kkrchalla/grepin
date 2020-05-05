#!/usr/bin/perl 

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
#   use CGI::Carp qw(carpout);
#   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/amznbarerr.txt")
#       or die "Unable to append to errorlog: $!\n";
#   carpout(*ERRORLOG);
}

$|=1;    # autoflush

  use Fcntl;
  use CGI;
  package main;

  my $internal_error = "An internal error occurred. Sorry for the inconvenience.<br /> Please inform the webmaster about the error at contact\@grepin.com.";
#  my $db_package = "";
#  package AnyDBM_File;
#  @ISA = qw(DB_File);
#  foreach my $isa (@ISA) {
#    if( eval("require $isa") ) {
#      $db_package = $isa;
#      last;
#    }
#  }
#  if( $db_package  ne 'DB_File' ) {
#    print "DBM - $internal_error \n\n";
#    exit;
#  }

  my $MAIN_DIR          = '/home/grepinco/public_html/cgi-bin/';
  my $USER_DIR          = $MAIN_DIR.'users/';
#  my $AMZN_RSLT_DB_FILE = $USER_DIR.'amznrslt';

  my $query = new CGI;
  my $user_id     = $query->param('uid');	# user id
  my $search      = $query->param('query');	# search keyword
  my $mode        = $query->param('category');	# books, music, ....
  my $item_id     = $query->param('itemid');	# specific item id
  my $output_type = $query->param('out');	# output type, html or javascript, default=html
  my $locale      = $query->param('locale');	# us or uk, default = us
  my $input_page  = $query->param('page');	# page number in results, default = 1
  my $user_aid    = $query->param('aid');	# user amazon associate id
  my $aff_us      = $query->param('aus');	# affiliate amazon associate id - us
  my $aff_uk      = $query->param('auk');	# affiliate amazon associate id - uk
  my $type        = $query->param('type');	# 'bar'= bar, 'tower'= tower, default='bar'
  my $seq         = $query->param('seq');    	# number of the similar bar in the same page
  my $border_color= $query->param('bcolor');    # color of the border of the bar and tower
  my $footer_color= $query->param('fcolor');    # color of the footer text
  my $disp_num    = $query->param('disp');      # how many products to display? min=1, max=5
  my $source      = $query->param('source');    # source where it generated
  my $gsource     = $query->param('gsrc');      # 1 = site search
  my $log         = $query->param('log');
  my $debug       = $query->param('debug');     # if 'yes' will display error messages
  my $key         = $query->param('key');       # numeric value of the query string 
  my $add_time    = undef;
  my $current_time = time();
  my $db_key      = undef; 
  my $result_found = undef; 
#  my %amznrslt_db_file;
  my $tracker = ' ';

  use Fcntl;
#  eval {
#    tie %amznrslt_db_file, "DB_File", $AMZN_RSLT_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $AMZN_RSLT_DB_FILE: $!";   
#  };


# http://www.grepin.com/cgi-bin/amznbar.pl?query=&category=&browseid=&itemid=&out=&locale=&page=&type=&seq=&bcolor=&fcolor=&disp=&aid=&uid=&source=

# for best effect you should add a Unicode charset META tag to the <HEAD> of your page
# like this: <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=utf-8">

# required options
my $associate_id    = "grepinsearcha-20";
my $uk_associate_id = "grepinsearcha-21";
my $developer_token = "0GNH1BCCTATJ7KASPB82";

my $xml_page = 1;
my $html;
my $browse_id;
my (%browse_ids, $xml_result, @Details, $this_xml_url, $error_msg);
my $randnum;
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
my ($xml_best_line_1, $xml_best_line_2, $xml_best_line_3, $xml_best_line_4);
my ($xml_list_line_1, $xml_list_line_2, $xml_list_line_3, $xml_list_line_4);
my ($banner_html, $banner_html_1, $banner_html_2, $banner_html_3, $banner_html_4);
my ($tower_html, $tower_html_1, $tower_html_2, $tower_html_3, $tower_html_4);
my ($trknum_1, $trknum_2, $trknum_3, $trknum_4);
my ($url_1, $url_2, $url_3, $url_4);
my ($result_assoc_1, $result_assoc_2, $result_assoc_3, $result_assoc_4);
my $blended = 'n';

# setup initial variables
if (($disp_num != 1) && ($disp_num != 2) && ($disp_num != 3) && ($disp_num != 4)) {
  if ($type ne 'tower') {
    $disp_num = 3;
  } else {
    $disp_num = 4; 
  }
}
if (!$border_color) { $border_color = "ff8800"; }
if (!$footer_color) { $footer_color = "white"; }
if (($input_page =~ /\d+/) && ($input_page > 1)) { $xml_page = $input_page; }
if (($seq =~ /\d+/) && ($seq > 0) && ($seq < 10)) { $xml_page = $xml_page + $seq - 1; }
if ($locale ne "uk") { $locale = "us"; }
if ($locale eq "uk") {
	$amazon_site   = "amazon.co.uk";
	$amazon_server = "xml-eu";
        $associate_id  = $uk_associate_id;
        $ref_aid       = $aff_uk;
	%browse_ids = ( "books_uk" => 1025612, "music" => 694208, "classical" => 229817, "dvd_uk" => 655852, "vhs_uk" => 573400, "electronics_uk" => 560800, "kitchen_uk" => 3147411, "software_uk" => 1025614, "video_games_uk" => 1025616, "toys_uk" => 595314 );
} else {
	$amazon_site = "amazon.com";
	$amazon_server = "xml";
        $ref_aid       = $aff_us;
	%browse_ids = ( baby => 540988, books => 1000, classical => 85, dvd => 404276, electronics => 493964, garden => 468250, kitchen => 491864, magazines => 599872, music => 301668, pc_hardware => 565118, photo => 508048, software => 491286, toys => 491290, universal => 468240, vhs => 404274, videogames => 471280 );
}

if (!$user_aid) { $user_aid = $associate_id; }
if (!$mode) { 
  $mode = ((keys %browse_ids)[int rand keys %browse_ids]); 
  $blended = 'y';
} 
if (!$browse_id) { $browse_id = $browse_ids{$mode}; }
$mode =~ s/_/-/g;

if (!$key) { $key = $search; }

$xml_result = get_xml_result();

if (!$xml_result) {
  if ($xml_page == 1) { 
    $error_msg = "Sorry, we are currently unable to process your request in a timely manner.<BR>Please try again later.\n"; 
    exit; 
  } else {
    $xml_page = 1;
    $xml_result = get_xml_result();
    if (!$xml_result) { 
      $error_msg = "Sorry, we are currently unable to process your request in a timely manner.<BR>Please try again later.\n"; 
      exit; 
    }
  }
}
  
#if (($result_found eq 'n') && ($db_key)) { 
#   $amznrslt_db_file{$db_key} = $current_time . '-' . $xml_result; 
#} 

# get all the products and shuffle them
$xml_result =~ s/<Details(?:\s[^>]+)?>(.*?)<\/Details>/push @Details, $1;/gsie;

# get 4 random_details
if (@Details) {
	if (@Details <= 7) {
		$random_details_1 = $Details[1];
		if ($disp_num > 1) { $random_details_2 = $Details[2]; }
		if ($disp_num > 2) { $random_details_3 = $Details[3]; }
		if ($disp_num > 3) { $random_details_4 = $Details[4]; }
	} else {
		$randnum = (rand @Details);
		$random_details_1 = $Details[$randnum];
		if ($disp_num > 1) {
			$randnum++;
			if ($randnum > @Details) { $randnum = 1 };
			$random_details_2 = $Details[$randnum];
		}
		if ($disp_num > 2) {
			$randnum++;
			if ($randnum > @Details) { $randnum = 1 };
			$random_details_3 = $Details[$randnum];
		}
		if ($disp_num > 3) {
			$randnum++;
			if ($randnum > @Details) { $randnum = 1 };
			$random_details_4 = $Details[$randnum];
		}
	}
} else {
	$error_msg = "Sorry no results are currently being returned for this query.";
	$xml_result =~ s/<ErrorMsg>([^<]+)<\/ErrorMsg>/$error_msg = $1;/esi;
}

# untie %amznrslt_db_file;

my $var = (rand 9);

# assign variables
if ($random_details_1) {
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
  $trknum_1         = $Asin . time();

  if (!$xml_our_price_1) {$xml_our_price_1 = $xml_list_price_1};
  if ($xml_our_price_1 =~ /'Too'/) { 
     $xml_our_price_1 = "Too Low.."; 
  }
  if ($xml_list_price_1) {
    $xml_list_line_1 = qq[
		<FONT Color="red" Size="1">List $xml_list_price_1</FONT>
    ];
  }

  if ($xml_our_price_1) {
    $xml_best_line_1 = qq[
		<BR>
		<FONT Color="red" Size="1">Best $xml_our_price_1</FONT>
    ];
  }

  if (length ($xml_prod_name_1) > 39) { $xml_prod_name_1 = substr($xml_prod_name_1,0,35).' ...'; }

  if ($gsource == 1) {
    if ($ref_aid) {
      if ($var < 3) {
        $result_link_1 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_1/ref=nosim/$associate_id?dev-t=$developer_token";
        $result_assoc_1 = $associate_id;
      } elsif ($var < 5) {
        $result_link_1 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_1/ref=nosim/$ref_aid?dev-t=$developer_token";
        $result_assoc_1 = $ref_aid;
      } else {
        $result_link_1 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_1/ref=nosim/$user_aid?dev-t=$developer_token";
        $result_assoc_1 = $user_aid;
      }

    } else {
      if ($var < 6) {
        $result_link_1 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_1/ref=nosim/$associate_id?dev-t=$developer_token";
        $result_assoc_1 = $associate_id;
      } else {
        $result_link_1 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_1/ref=nosim/$user_aid?dev-t=$developer_token";
        $result_assoc_1 = $user_aid;
      }
    }
  } else {
    if ($var < 3) {
      $result_link_1 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_1/ref=nosim/$associate_id?dev-t=$developer_token";
      $result_assoc_1 = $associate_id;
    } else {
      $result_link_1 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_1/ref=nosim/$user_aid?dev-t=$developer_token";
      $result_assoc_1 = $user_aid;
    }
  }
  $url_1 = "http://www.grepin.com/cgi-bin/amzntrk.pl?uid=$user_id&trknum=$trknum_1&url=$result_link_1";

  $banner_html_1 = qq[
    <TD>
	<TABLE Bgcolor="#ffffff" Border="0" Cellpadding="5" Cellspacing="0" Width="100%" height="100%">
	<TR>
	<TD Align="center">
		<FONT Size="1"><A Href="$url_1" target=_blank title="$ProductName">$xml_prod_name_1</A></FONT>
	</TD>
	<TD Align="center">
		<A Href="$url_1" target=_blank title="$ProductName"><IMG Border="0" Vspace="3" Src="$xml_image_s_1" onLoad="noImageCheck(this);"></A>
	</TD>
	<TD Align="center">
		$xml_list_line_1
		$xml_best_line_1
	</TD>
	</TR>
	</TABLE>
    </TD>
  ];

  $tower_html_1 = qq[
    <TD>
	<TABLE Bgcolor="#ffffff" Border="0" Cellpadding="5" Cellspacing="0" Width="100%" height="100%">
	<TR>
	<TD Align="center">
		<FONT Size="1"><A Href="$url_1" target=_blank title="$ProductName">$xml_prod_name_1</A></FONT>
		<BR>
		<A Href="$url_1" target=_blank title="$ProductName"><IMG Border="0" Vspace="3" Src="$xml_image_s_1" onLoad="noImageCheck(this);"></A>
		<BR>
		$xml_list_line_1
		$xml_best_line_1
	</TD>
	</TR>
	</TABLE>
    </TD>
  ];

}

$Asin           = undef;
$ProductName    = undef;
$Catalog        = undef;
$ImageUrlSmall  = undef;
$ImageUrlMedium = undef;
$ImageUrlLarge  = undef;
$ListPrice      = undef;
$OurPrice       = undef;
$UsedPrice      = undef;

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
  $trknum_2         = $Asin . time();

  if (!$xml_our_price_2) {$xml_our_price_2 = $xml_list_price_2};
  if ($xml_our_price_2 =~ /'Too'/) { 
     $xml_our_price_2 = "Too Low.."; 
  }
  if ($xml_list_price_2) {
    $xml_list_line_2 = qq[
		<FONT Color="red" Size="1">List $xml_list_price_2</FONT>
    ];
  }

  if ($xml_our_price_2) {
    $xml_best_line_2 = qq[
		<BR>
		<FONT Color="red" Size="1">Best $xml_our_price_2</FONT>
    ];
  }

  if (length ($xml_prod_name_2) > 39) { $xml_prod_name_2 = substr($xml_prod_name_2,0,35).' ...'; }
  if ($gsource == 1) {
    if ($ref_aid) {
      if ($var > 6) {
        $result_link_2 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_2/ref=nosim/$associate_id?dev-t=$developer_token";
        $result_assoc_2 = $associate_id;
      } elsif ($var < 5) {
        $result_link_2 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_2/ref=nosim/$ref_aid?dev-t=$developer_token";
        $result_assoc_2 = $ref_aid;
      } else {
        $result_link_2 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_2/ref=nosim/$user_aid?dev-t=$developer_token";
        $result_assoc_2 = $user_aid;
      }

    } else {
      if ($var > 3) {
        $result_link_2 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_2/ref=nosim/$associate_id?dev-t=$developer_token";
        $result_assoc_2 = $associate_id;
      } else {
        $result_link_2 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_2/ref=nosim/$user_aid?dev-t=$developer_token";
        $result_assoc_2 = $user_aid;
      }
    }
  } else {
    if ($var > 6) {
      $result_link_2 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_2/ref=nosim/$associate_id?dev-t=$developer_token";
      $result_assoc_2 = $associate_id;
    } else {
      $result_link_2 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_2/ref=nosim/$user_aid?dev-t=$developer_token";
      $result_assoc_2 = $user_aid;
    }
  }
  $url_2 = "http://www.grepin.com/cgi-bin/amzntrk.pl?uid=$user_id&trknum=$trknum_2&url=$result_link_2";

  $banner_html_2 = qq[
    <TD>
	<TABLE Bgcolor="#ffffff" Border="0" Cellpadding="5" Cellspacing="0" Width="100%" height="100%">
	<TR>
	<TD Align="center">
		<FONT Size="1"><A Href="$url_2" target=_blank title="$ProductName">$xml_prod_name_2</A></FONT>
	</TD>
	<TD Align="center">
		<A Href="$url_2" target=_blank title="$ProductName"><IMG Border="0" Vspace="3" Src="$xml_image_s_2" onLoad="noImageCheck(this);"></A>
	</TD>
	<TD Align="center">
		$xml_list_line_2
		$xml_best_line_2
	</TD>
	</TR>
	</TABLE>
    </TD>
  ];

  $tower_html_2 = qq[
    <TD>
	<TABLE Bgcolor="#ffffff" Border="0" Cellpadding="5" Cellspacing="0" Width="100%" height="100%">
	<TR>
	<TD Align="center">
		<FONT Size="1"><A Href="$url_2" target=_blank title="$ProductName">$xml_prod_name_2</A></FONT>
		<BR>
		<A Href="$url_2" target=_blank title="$ProductName"><IMG Border="0" Vspace="3" Src="$xml_image_s_2" onLoad="noImageCheck(this);"></A>
		<BR>
		$xml_list_line_2
		$xml_best_line_2
	</TD>
	</TR>
	</TABLE>
    </TD>
  ];

}

$Asin           = undef;
$ProductName    = undef;
$Catalog        = undef;
$ImageUrlSmall  = undef;
$ImageUrlMedium = undef;
$ImageUrlLarge  = undef;
$ListPrice      = undef;
$OurPrice       = undef;
$UsedPrice      = undef;

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
  $trknum_3         = $Asin . time();

  if (!$xml_our_price_3) {$xml_our_price_3 = $xml_list_price_3};
  if ($xml_our_price_3 =~ /'Too'/) { 
     $xml_our_price_3 = "Too Low.."; 
  }
  if ($xml_list_price_3) {
    $xml_list_line_3 = qq[
		<FONT Color="red" Size="1">List $xml_list_price_3</FONT>
    ];
  }

  if ($xml_our_price_3) {
    $xml_best_line_3 = qq[
		<BR>
		<FONT Color="red" Size="1">Best $xml_our_price_3</FONT>
    ];
  }

  if (length ($xml_prod_name_3) > 39) { $xml_prod_name_3 = substr($xml_prod_name_3,0,35).' ...'; }
  if ($gsource == 1) {
    if ($ref_aid) {
      if ($var < 3) {
        $result_link_3 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_3/ref=nosim/$associate_id?dev-t=$developer_token";
        $result_assoc_3 = $associate_id;
      } elsif ($var < 5) {
        $result_link_3 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_3/ref=nosim/$ref_aid?dev-t=$developer_token";
        $result_assoc_3 = $ref_aid;
      } else {
        $result_link_3 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_3/ref=nosim/$user_aid?dev-t=$developer_token";
        $result_assoc_3 = $user_aid;
      }

    } else {
      if ($var < 6) {
        $result_link_3 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_3/ref=nosim/$associate_id?dev-t=$developer_token";
        $result_assoc_3 = $associate_id;
      } else {
        $result_link_3 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_3/ref=nosim/$user_aid?dev-t=$developer_token";
        $result_assoc_3 = $user_aid;
      }
    }
  } else {
    if ($var < 3) {
      $result_link_3 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_3/ref=nosim/$associate_id?dev-t=$developer_token";
      $result_assoc_3 = $associate_id;
    } else {
      $result_link_3 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_3/ref=nosim/$user_aid?dev-t=$developer_token";
      $result_assoc_3 = $user_aid;
    }
  }
  $url_3 = "http://www.grepin.com/cgi-bin/amzntrk.pl?uid=$user_id&trknum=$trknum_3&url=$result_link_3";

  $banner_html_3 = qq[
    <TD>
	<TABLE Bgcolor="#ffffff" Border="0" Cellpadding="5" Cellspacing="0" Width="100" height="100%">
	<TR>
	<TD Align="center">
		<FONT Size="1"><A Href="$url_3" target=_blank title="$ProductName">$xml_prod_name_3</A></FONT>
	</TD>
	<TD Align="center">
		<A Href="$url_3" target=_blank title="$ProductName"><IMG Border="0" Vspace="3" Src="$xml_image_s_3" onLoad="noImageCheck(this);"></A>
	</TD>
	<TD Align="center">
		$xml_list_line_3
		$xml_best_line_3
	</TD>
	</TR>
	</TABLE>
    </TD>
  ];

  $tower_html_3 = qq[
    <TD>
	<TABLE Bgcolor="#ffffff" Border="0" Cellpadding="5" Cellspacing="0" Width="100%" height="100%">
	<TR>
	<TD Align="center">
		<FONT Size="1"><A Href="$url_3" target=_blank title="$ProductName">$xml_prod_name_3</A></FONT>
		<BR>
		<A Href="$url_3" target=_blank title="$ProductName"><IMG Border="0" Vspace="3" Src="$xml_image_s_3" onLoad="noImageCheck(this);"></A>
		<BR>
		$xml_list_line_3
		$xml_best_line_3
	</TD>
	</TR>
	</TABLE>
    </TD>
  ];

}

$Asin           = undef;
$ProductName    = undef;
$Catalog        = undef;
$ImageUrlSmall  = undef;
$ImageUrlMedium = undef;
$ImageUrlLarge  = undef;
$ListPrice      = undef;
$OurPrice       = undef;
$UsedPrice      = undef;

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
  $trknum_4         = $Asin . time();

  if (!$xml_our_price_4) {$xml_our_price_4 = $xml_list_price_4};
  if ($xml_our_price_4 =~ /'Too'/) { 
     $xml_our_price_4 = "Too Low.."; 
  }
  if ($xml_list_price_4) {
    $xml_list_line_4 = qq[
		<FONT Color="red" Size="1">List $xml_list_price_4</FONT>
    ];
  }

  if ($xml_our_price_4) {
    $xml_best_line_4 = qq[
		<BR>
		<FONT Color="red" Size="1">Best $xml_our_price_4</FONT>
    ];
  }

  if (length ($xml_prod_name_4) > 39) { $xml_prod_name_4 = substr($xml_prod_name_4,0,35).' ...'; }
  if ($gsource == 1) {
    if ($ref_aid) {
      if ($var > 6) {
        $result_link_4 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_4/ref=nosim/$associate_id?dev-t=$developer_token";
        $result_assoc_4 = $associate_id;
      } elsif ($var < 5) {
        $result_link_4 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_4/ref=nosim/$ref_aid?dev-t=$developer_token";
        $result_assoc_4 = $ref_aid;
      } else {
        $result_link_4 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_4/ref=nosim/$user_aid?dev-t=$developer_token";
        $result_assoc_4 = $user_aid;
      }

    } else {
      if ($var > 3) {
        $result_link_4 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_4/ref=nosim/$associate_id?dev-t=$developer_token";
        $result_assoc_4 = $associate_id;
      } else {
        $result_link_4 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_4/ref=nosim/$user_aid?dev-t=$developer_token";
        $result_assoc_4 = $user_aid;
      }
    }
  } else {
    if ($var > 6) {
      $result_link_4 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_4/ref=nosim/$associate_id?dev-t=$developer_token";
      $result_assoc_4 = $associate_id;
    } else {
      $result_link_4 = "http://www.$amazon_site/exec/obidos/ASIN/$xml_asin_4/ref=nosim/$user_aid?dev-t=$developer_token";
      $result_assoc_4 = $user_aid;
    }
  }
  $url_4 = "http://www.grepin.com/cgi-bin/amzntrk.pl?uid=$user_id&trknum=$trknum_1&url=$result_link_4";

  $banner_html_4 = qq[
    <TD>
	<TABLE Bgcolor="#ffffff" Border="0" Cellpadding="5" Cellspacing="0" Width="100" height="100%">
	<TR>
	<TD Align="center">
		<FONT Size="1"><A Href="$url_4" target=_blank title="$ProductName">$xml_prod_name_4</A></FONT>
	</TD>
	<TD Align="center">
		<A Href="$url_4" target=_blank title="$ProductName"><IMG Border="0" Vspace="3" Src="$xml_image_s_4" onLoad="noImageCheck(this);"></A>
	</TD>
	<TD Align="center">
		$xml_list_line_4
		$xml_best_line_4
	</TD>
	</TR>
	</TABLE>
    </TD>
  ];

  $tower_html_4 = qq[
    <TD>
	<TABLE Bgcolor="#ffffff" Border="0" Cellpadding="5" Cellspacing="0" Width="100%" height="100%">
	<TR>
	<TD Align="center">
		<FONT Size="1"><A Href="$url_4" target=_blank title="$ProductName">$xml_prod_name_4</A></FONT>
		<BR>
		<A Href="$url_4" target=_blank title="$ProductName"><IMG Border="0" Vspace="3" Src="$xml_image_s_4" onLoad="noImageCheck(this);"></A>
		<BR>
		$xml_list_line_4
		$xml_best_line_4
	</TD>
	</TR>
	</TABLE>
    </TD>
  ];

}

# display result
# kishore if error message, change the look and feel - probably create a sub set_error_message

if ($type  eq 'tower') {
  $html = set_tower_html();
} else {
  $html = set_bar_html();
}
#print "$html \n\n";
if ($error_msg) { 
  if ($debug ne 'yes') { exit; }
  $html = $error_msg;
}
#print "$html\n";
#$html = s/[Â£]/£/gs;
#print "html 2 $html\n";
#print "out $output_type \n\n";
if ($output_type eq "javascript") {
#print "inside output\n\n";
	$html =~ s/"/'/g;
	$html =~ s/\n/"\);\ndocument.write\("/g;
	$html = qq[document.write("] . $html . qq[");\n];
	$html =~ s/(document.write\(")?<\/?SCRIPT[^>]*>("\);)?//gi;
}

print "Content-type: text/html; charset=utf-8\n\n";
print "$html\n";

if ($log eq 'no') { exit; }

log_query();

exit;

#	the end - subs below

sub get_xml_result {

use Fcntl;

if ($search) {
        $result_found = 'n'; 
	$search =~ s/\s/\%20/g;
	if ($blended eq 'y') {
		$this_xml_url = "http://$amazon_server.amazon.com/onca/xml3?t=$associate_id&dev-t=$developer_token&BlendedSearch=$search&type=lite&page=$xml_page&sort=+salesrank&f=xml&locale=$locale"; 
#                $db_key = 'b'.$xml_page.$locale.$key; 
#                if ($amznrslt_db_file{$db_key}) { 
#                  $amznrslt_db_file{$db_key} =~ m/-/; 
#                  $add_time   = $`;
#                  $xml_result = $';
#                  if (($current_time - $add_time) > 86400) { 
#                    delete $amznrslt_db_file{$db_key}; 
#                  } else { 
#                    $result_found = 'y'; 
#                  } 
#		}
	} else {
		$this_xml_url = "http://$amazon_server.amazon.com/onca/xml3?t=$associate_id&dev-t=$developer_token&KeywordSearch=$search&mode=$mode&type=lite&page=$xml_page&sort=+salesrank&f=xml&locale=$locale"; 
#                $db_key = 's'.$xml_page.$locale.$mode.$key; 
#                if ($amznrslt_db_file{$db_key}) { 
#                  $amznrslt_db_file{$db_key} =~ m/-/; 
#                  $add_time   = $`;
#                  $xml_result = $';
#                  if (($current_time - $add_time) > 86400) { 
#                    delete $amznrslt_db_file{$db_key}; 
#                  } else { 
#                    $result_found = 'y'; 
#                  } 
#		}
	}
} elsif ($item_id) {
	$this_xml_url = "http://$amazon_server.amazon.com/onca/xml3?t=$associate_id&dev-t=$developer_token&AsinSearch=$item_id&type=lite&f=xml&locale=$locale";
        $result_found = 'n'; 
#        $db_key = 'i'.$locale.$item_id; 
#        if ($amznrslt_db_file{$db_key}) { 
#          $amznrslt_db_file{$db_key} =~ m/-/; 
#          $add_time   = $`;
#          $xml_result = $';
#          if (($current_time - $add_time) > 86400) { 
#            delete $amznrslt_db_file{$db_key};
#          } else { 
#            $result_found = 'y'; 
#          } 
#        } 
} else {
	$this_xml_url = "http://$amazon_server.amazon.com/onca/xml3?t=$associate_id&dev-t=$developer_token&BrowseNodeSearch=$browse_id&mode=$mode&type=lite&page=$xml_page&sort=+salesrank&f=xml&locale=$locale";
}

print "$this_xml_url \n\n";

# request the XML
eval 'use LWP::Simple qw($ua get)'; if ($@) { print "Content-type: text/html\n\n"; print "Unable to use LWP::Simple and this script cannot function without it.\n"; exit; }
$ua->timeout(15);
#if (($result_found eq 'n') || (!$xml_result)) { 
	$xml_result = get($this_xml_url);
	$tracker = 'x';
#}

return $xml_result;

}


# between the qq[ and ]; is the HTML that formats the result. feel free to change it to whatever you want
# possible variables are: $result_link, $Asin, $ProductName, $Catalog, $ReleaseDate, $Manufacturer, $ImageUrlSmall, $ImageUrlMedium, $ImageUrlLarge, $ListPrice, $OurPrice, $UsedPrice
# kishore - change the look of the box and boxes
sub set_bar_html {

my $amzn_footer = undef;
 
if ($banner_html_2) {
  $amzn_footer = 'of '.$amazon_site;
}

	$banner_html = qq[

<SCRIPT>function noImageCheck(objImg) { if (objImg.width == 1) { objImg.src = "http://g-images.amazon.com/images/G/01/books/icons/books-no-image.gif"; } } </SCRIPT>
<font face=verdana>
<TABLE Bgcolor="#ffffff" Border="0" Width="1" height="1" cellpadding="0" cellspacing="0">
<TR>
<TD>
<TABLE Bgcolor="$border_color" Border="0" Width="100%" height="1" cellpadding="0" cellspacing="1">
<TR>
	$banner_html_1
	$banner_html_2
	$banner_html_3
	$banner_html_4
</TR>
</TABLE>
<TABLE>
<TR>
<TABLE Bgcolor="$border_color" Border="0" Cellpadding="0" Cellspacing="0" Width="100%">
<TR>
<TD align="left">
	<FONT Size="1" color="$footer_color">&nbsp;$amzn_footer</FONT>
</TD>
<TD align="right">
	<FONT Size="1" color="$footer_color">by <A Href="http://www.grepin.com/">Grepin.com</A></FONT>&nbsp;
</TD>
</TR>
</TABLE>
</TR>
</TABLE>
	];

return $banner_html
}



sub set_tower_html {

	$tower_html = qq[

<SCRIPT>function noImageCheck(objImg) { if (objImg.width == 1) { objImg.src = "http://g-images.amazon.com/images/G/01/books/icons/books-no-image.gif"; } } </SCRIPT>
<font face=verdana>
<TABLE Bgcolor="$border_color" Border="0" Width="1" height="1" cellpadding="0" cellspacing="0">
<TR>
<TD>
<TABLE Border="0" Cellpadding="0" Cellspacing="0" Width="100%">
<TR>
<TD align="right">
	<FONT Size="1" color="$footer_color">by <A Href="http://www.grepin.com/">Grepin.com</A></FONT>&nbsp;
</TD>
</TR>
</TABLE>
<TABLE Bgcolor="$border_color" Border="0" Width="100" height="1" cellpadding="0" cellspacing="1">
<TR>
	$tower_html_1
</TR>
<TR>
	$tower_html_2
</TR>
<TR>
	$tower_html_3
</TR>
<TR>
	$tower_html_4
</TR>
</TABLE>
<TABLE>
<TR>
<TABLE Border="0" Cellpadding="0" Cellspacing="0" Width="100%">
<TR>
<TD align="right">
	<FONT Size="0" color="$footer_color">of $amazon_site&nbsp;</FONT>
</TD>
</TR>
</TABLE>
</TR>
</TABLE>
	];

return $tower_html

}


sub log_query {

  my @line = ();
  my $addr = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};

  use Fcntl;

  push(@line, 'amazon-d',
              $tracker || '-',
              $trknum_1 || '-',
              $trknum_2 || '-',
              $trknum_3 || '-',
              $trknum_4 || '-',
              $user_id || '-',
              localtime time() || '-',
              $addr || '-',
              $search || '-',
              $mode || '-',
              $item_id || '-',
              $output_type || '-',
              $locale || '-',
              $input_page || '-',
              $type || '-',
              $seq || '-',
              $border_color || '-',
              $footer_color || '-',
              $disp_num || '-',
              $source || '-',
              $gsource || '-',
              $result_assoc_1 || '-',
              $xml_asin_1 || '-',
              $xml_prod_name_1 || '-',
              $result_assoc_2 || '-',
              $xml_asin_2 || '-',
              $xml_prod_name_2 || '-',
              $result_assoc_3 || '-',
              $xml_asin_3 || '-',
              $xml_prod_name_3 || '-',
              $result_assoc_4 || '-',
              $xml_asin_4 || '-',
              $xml_prod_name_4 || '-');

  #
  # write log in batch
  #

  eval {
    $pid = fork();
    if ($pid == 0) {
      close STDIN;
      close STDOUT;
      close STDERR;

      use Fcntl ':flock';        # import LOCK_* constants
#      if ($user_id) {
#        $LOG_FILE = '/home/grepinco/public_html/cgi-bin/users/users/$user_id/search/amzndspl.txt';
#      } else {
        $LOG_FILE = '/home/grepinco/public_html/cgi-bin/log/amzndspl.txt';
#      }

      open(LOG, ">>$LOG_FILE") or die "Cannot open logfile '$LOG_FILE' for writing: $!";
      flock(LOG, LOCK_EX);
      seek(LOG, 0, 2);
      print LOG join(':::', @line).":::\n";
      flock(LOG, LOCK_UN);
      close(LOG);

    } elsif (!defined $pid) {
      die "fork failed during logquery in amznbar";
    }
  };

}
