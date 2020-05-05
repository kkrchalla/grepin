#!/usr/bin/perl

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
#   use CGI::Carp qw(carpout);
#   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/plscrerr.txt")
#       or die "Unable to append to errorlog: $!\n";
#   carpout(*ERRORLOG);
}

# Grepin Search and Services
# Copyright (C) 2004 Grepin Search and Services <contact@grepin.com>

  {
    $0 =~ /(.*)(\\|\/)/;
    push @INC, $1 if $1;
  }

  $|=1;    # autoflush

  use Fcntl;
  use CGI;
  use MIME::Lite;

  package main;

  my $query = new CGI;

  my ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20);

  ######################################

  #require '/home/grepinco/public_html/cgi-bin/sub_mainconf.pl';
  #my $MAIN_DIR = v_mainconf();
  my $MAIN_DIR = '/home/grepinco/public_html/cgi-bin/';
  my $PAGE_DIR = $MAIN_DIR.'pages/';
  my $USER_DIR = $MAIN_DIR.'users/';
  my $TMPL_DIR = $MAIN_DIR.'templates/';

  my $SRCH_DIR      = $MAIN_DIR.'search/';
  my $SRCH_COMN_DIR = $SRCH_DIR.'common/';

  my $COMN_RESULTS_TEMPLATE   = $TMPL_DIR.'resultspage.html';
  my $COMN_INITRSLT_TEMPLATE  = $TMPL_DIR.'initrsltpage.html';
  my $COMN_SEARCH_TEMPLATE    = $TMPL_DIR.'search.html';
  my $COMN_NO_MATCH_TEMPLATE  = $TMPL_DIR.'nomatch.html';
  my $COMN_USER_CONF_TEMPLATE = $TMPL_DIR.'sub_userconf.pl';
  my $COMN_STOP_WORDS_FILE    = $TMPL_DIR.'stopwords.txt';

  my $LOG_DIR    = $MAIN_DIR.'log/';
  my $LOG_FILE   = $LOG_DIR.'plscrlog.txt';
  my $LOG_SOURCE = $LOG_DIR.'sourcelog.txt';

  my $LATEST_IDS_DB_FILE         = $USER_DIR.'latestids';
  my $SESSION_DB_FILE            = $USER_DIR.'session';
  my $USER_PWD_DB_FILE           = $USER_DIR.'userpwd';
  my $USER_PROFILE_DB_FILE       = $USER_DIR.'userprof';
  my $USER_INDEX_DATA_DB_FILE    = $USER_DIR.'userindxdata';
  my $USER_TEMPLATE_DATA_DB_FILE = $USER_DIR.'usertmpldata';
  my $JOB_STATUS_DB_FILE         = $USER_DIR.'jobstatus';
  my $QUEUE_DB_FILE              = $USER_DIR.'queue';
  my $INDEX_QUEUE_DB_FILE        = $USER_DIR.'indxqueue';
  my $REPORT_QUEUE_DB_FILE       = $USER_DIR.'rprtqueue';
  my $USER_STATUS_DB_FILE        = $USER_DIR.'userstatus';

  my $TOP_BAR_HTML               = $USER_DIR.'topbarhtml';
  my $BOT_BAR_HTML               = $USER_DIR.'botbarhtml';
  my $LEFT_BAR_HTML              = $USER_DIR.'leftbarhtml';

  ########################################

  my $cmd        = $query->param('cmd');
  my $session_id = $query->param('sid');
  my $user_id    = $query->param('uid');

  my $USER_LOCAL_DIR = $MAIN_DIR.$user_id.'/';
  my $SRCH_USER_DIR  = $USER_LOCAL_DIR.'search/';
  my $USER_PL_DIR    = $USER_LOCAL_DIR.'pl/';

  my $PL_DTL_DB_FILE = $USER_PL_DIR.'pldtl';
  my $PL_URL_DB_FILE = $USER_PL_DIR.'plurl';

  my $return_code;
  my $return_msg;
  my $valid_sid = 'T';
  my $internal_error = "An internal error occurred. Sorry for the inconvenience.<br /> Please inform the webmaster about the error at contact\@grepin.com.";
  my $addr = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};

  print "Content-Type: text/html\n\n";

  if ($query->param('source')) {
    my @line = ();
    my $addr = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};
    use Fcntl;
    push(@line, 'plscr ------------- ',
                localtime time() || '-',
                $addr || '-',
                $query->param('source') || '-');
    eval {
      use Fcntl ':flock';        # import LOCK_* constants
      open(LOGSRC, ">>$LOG_SOURCE") or die "Cannot open logsource '$LOG_SOURCE' for writing: $!";
      flock(LOGSRC, LOCK_EX);
      seek(LOGSRC, 0, 2);
      print LOGSRC join(':::', @line).":::\n";
      flock(LOGSRC, LOCK_UN);
      close(LOGSRC);
    };
    if ($@){
      log_error("p_logsource1", $@);
    }
  }

  my $db_package = "";
  package AnyDBM_File;
  @ISA = qw(DB_File);
  # You may try to comment in the next line if you don't have DB_File. Still
  # this is not recommended.
  #@ISA = qw(DB_File GDBM_File SDBM_File ODBM_File NDBM_File);
  foreach my $isa (@ISA) {
    if( eval("require $isa") ) {
      $db_package = $isa;
      last;
    }
  }
  if( $db_package  ne 'DB_File' ) {
    log_error("plscr1", "The DB_File module was not found.");
    print "$internal_error \n\n";
    exit;
  }

####  DO NOT CALL ANY SUB-PROGRAM UNTIL THIS POINT ########


  if (!$cmd) {
    $cmd = "lst";
  }

  if ($session_id) {
    ($return_code, $return_msg) = p_sessnchk();
    if ($return_code != 0) {
      $user_id    = undef;
      $session_id = undef;
      ($return_code, $return_msg) = e_login(5190, $return_msg);
      $valid_sid = 'F';
    }
  } else {
    ($return_code, $return_msg) = e_login(5190, "You have to login as a member to access this page.");
    $user_id = undef;
    $valid_sid = 'F';
  }

  if ($valid_sid eq 'T') {
    if ($cmd eq "list") {
      ($return_code, $return_msg) = m_list();
    } elsif ($cmd eq "prv") {
      ($return_code, $return_msg) = m_preview();
    } elsif ($cmd eq "model") {
      ($return_code, $return_msg) = m_model();
    } elsif ($cmd eq "add") {
      ($return_code, $return_msg) = m_add();
    } elsif ($cmd eq "edit") {
      ($return_code, $return_msg) = m_edit();
    } elsif ($cmd eq "del") {
      ($return_code, $return_msg) = m_delete();
    } else {
      $return_code = 99;
      $return_msg = "Invalid request. Please check the URL and try again.";
    }
  }

  #
  # if return_code == 90, the html is already sent to the screen. This happens in reports.
  #

  if ($return_code != 90) {
    ($return_code, $return_msg) = m_disp_screen ($return_msg);
    print $return_msg;
  }

  exit;





sub m_list {

  my $m_return_code;
  my $m_return_msg;

  ($m_return_code, $m_return_msg) = d_list();
  return ($m_return_code, $m_return_msg);
}


sub m_add {

  my $m_return_code;
  my $m_return_msg;

 # once the add screen is displayed, the path will go thru the edit way.. for prv and save

  if (!$fn) {
    ($m_return_code, $m_return_msg) = d_add();
    if ($m_return_code != 0) {
      ($m_return_code, $m_return_msg) = e_add("1328", $m_return_msg);
    }
  } elsif ($fn eq "prv") {
    ($m_return_code, $m_return_msg) = p_addprv();
    if ($m_return_code == 2) {
      ($m_return_code, $m_return_msg) = e_add("1329", $m_return_msg);
    } elsif ($m_return_code == 3) {
      ($m_return_code, $m_return_msg) = e_add("1330", $m_return_msg);
    } elsif ($m_return_code != 0) {
      ($m_return_code, $m_return_msg) = e_add("1328", $m_return_msg);
    }

  } elsif ($fn eq "save") {
    ($m_return_code, $m_return_msg) = p_save("add");
    if ($m_return_code == 0) {
      ($m_return_code, $m_return_msg) = m_list();
    } else {
      ($m_return_code, $m_return_msg) = e_add("1328", $m_return_msg);
    }
  } else {
    $m_return_code = 99;
    $m_return_msg  = "Invalid request. Please check the URL and try again.";
  }

  return ($m_return_code, $m_return_msg);
}


sub m_preview {

  my $m_return_code;
  my $m_return_msg;

  ($m_return_code, $m_return_msg) = d_preview();
  if ($m_return_code != 0) {
    ($m_return_code, $m_return_msg) = d_static("eprv");
  }
  return ($m_return_code, $m_return_msg);
}


sub m_edit {

  my $fn = $query->param('fn');
  my $m_return_code;
  my $m_return_msg;

  if (!$fn) {
    ($m_return_code, $m_return_msg) = d_edit();
    if ($m_return_code == 1) {
      ($m_return_code, $m_return_msg) = e_add("1328", $m_return_msg);
    } elsif ($m_return_code != 0) {
      ($m_return_code, $m_return_msg) = e_list("0804", $m_return_msg);
    }
  } elsif ($fn eq "prv") {
    ($m_return_code, $m_return_msg) = p_editprv();
    if ($m_return_code == 2) {
      ($m_return_code, $m_return_msg) = e_edit("0929", $m_return_msg);
    } elsif ($m_return_code == 3) {
      ($m_return_code, $m_return_msg) = e_edit("0930", $m_return_msg);
    } elsif ($m_return_code != 0) {
      ($m_return_code, $m_return_msg) = e_edit("0928", $m_return_msg);
    }
  } elsif ($fn eq "save") {
    ($m_return_code, $m_return_msg) = p_save("edit");
    if ($m_return_code == 0) {
      ($m_return_code, $m_return_msg) = m_list();
    } else {
      ($m_return_code, $m_return_msg) = e_edit("0928", $m_return_msg);
    }
  } else {
    $m_return_code = 99;
    $m_return_msg  = "Invalid request. Please check the URL and try again.";
  }

  return ($m_return_code, $m_return_msg);
}


sub m_delete {

  my $fn = $query->param('fn');
  my $m_return_code;
  my $m_return_msg;

  if (!$fn) {
    ($m_return_code, $m_return_msg) = d_del();
  } elsif ($fn eq "del") {
    ($m_return_code, $m_return_msg) = p_del();
    if ($m_return_code == 0) {
      ($m_return_code, $m_return_msg) = m_list();
    } else {
      ($m_return_code, $m_return_msg) = e_del("p490", $m_return_msg);
    }
  } else {
    ($m_return_code, $m_return_msg) = m_list();
  }

  return ($m_return_code, $m_return_msg);
}



sub m_disp_screen {

  my $inner_html = shift;
  my $menu1_html_file = $PAGE_DIR.'menu1.html';
  my $menu2_html_file = $PAGE_DIR.'menu2.html';
  my $menu_html;

  eval {
    if (($user_id) && ($session_id)) {
      open (MENUHTML, $menu2_html_file) or die "Cannot open menu2htmlfile '$menu2_html_file' for reading: $!";
    } else {
      open (MENUHTML, $menu1_html_file) or die "Cannot open menu1htmlfile '$menu1_html_file' for reading: $!";
    }

    while (<MENUHTML>) {
      $menu_html .= $_;
    }
    close(MENUHTML);
  };
  if ($@){
    log_error("plscr2", $@);
    return (99, $internal_error);
  }

  $menu_html =~ s/:::grepin-inner-html:::/$inner_html/g;                 # put the inner screen
  $menu_html =~ s/:::grepin-fld00:::/$user_id/g;                           # user_id
  $menu_html =~ s/:::grepin-fld01:::/$session_id/g;                        # session_id
  $menu_html =~ s/:::grepin-.*::://g;                                      # space out all the other fields

  return (0, $menu_html);

}



######################################################################################


# d_??? display subprogram
# p_??? process subprogram
# e_??? error display subprogram
# $PAGE_DIR
# $USER_PROFILE_DB_FILE, $USER_PWD_DB_FILE


sub d_list {

  my %pldtl_dbfile;
  my $db_key;
  my ($tmpl_id, $title);
  my $screen_html_file = $PAGE_DIR.'pllst.html';
  my $screen_html;
  my $pl_count = 0;
  my @pl_array = ();
  my @row_array  = ();
  my ($row_html_before, $row_html_after, $row_html_temp);

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %pldtl_dbfile, "DB_File", $PL_DTL_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PL_DTL_DB_FILE: $!";
    foreach $title (sort keys %pldtl_dbfile) {
      ( $desc, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $pldtl_dbfile{$title});
      $pl_count++;
      push @pl_array, $pl_count.':::'.$title.':::'.$desc;
    }
    untie %pldtl_dbfile;
  };
  if ($@){
    log_error("d_list1", $@);
    return (99, $internal_error);
  }

  # create template list rows
  $screen_html   =~ /:::grepin-start-0801:::.*:::grepin-end-0801:::/s;
  $row_html_before = $&;

  $row_html_after = undef;
  if ($pl_count > 0) {
    $i = 0;
    while ($pl_array[$i]) {
      @row_array = ();
      @row_array = split /:::/, $pl_array[$i];
      $row_html_temp  = $row_html_before;
      $row_html_temp  =~ s/:::grepin-0802:::/$row_array[1]/g; # sequence number
      $row_html_temp  =~ s/:::grepin-0803:::/$row_array[2]/g; # promotion list title(id)
      $row_html_temp  =~ s/:::grepin-0804:::/$row_array[3]/g; # promotion list description
      $row_html_after .= $row_html_temp;
      $i++;
    }
  }

  # substitute values in the page
  $screen_html =~ s/:::grepin-start-0801:::.*:::grepin-end-0801:::/$row_html_after/gs;
  $screen_html =~ s/(:::grepin-start-0801:::)|(:::grepin-end-0801:::)//gs;

  return (0, $screen_html);

}



sub e_list {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $pl_title = $query->param('s0800');
  my $e_return_code;

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $pl_title =~ tr/a-z/A-Z/;
  $pl_title =~ s/\s+/ /g;
  $pl_title =~ s/(^\s+)|(\s+$)//;

  ($e_return_code, $screen_html) = d_list();

  if ($e_return_code == 0) {
    $error_msg = "Error:".$error_id." ".$error_msg;
    $screen_html =~ s/:::grepin-0804:::/$error_msg/g; # give the error message
    $screen_html =~ s/:::grepin-0800:::/$pl_title/gs;
    return (0, $screen_html);
  } else {
    return ($e_return_code, $screen_html);
  }

}


######################################################################################


sub d_preview {
# preview the template
# return codes
# 90 - success and the page is printed on the screen
# 99 - database error

  my $user_id         = $query->param('uid');
  my $session_id      = $query->param('sid');

  my $srch_rslts_page = $SRCH_USER_DIR.'templates/resultspage.html';
  my $srch_rslts_temp = $TMPL_DIR.'srchrsltstemp.html';
  my $preview_page_content;
  my $srch_rslts_content;

  use Fcntl;

  # create the preview page
  #
  eval {
    open (PRVWPAGE, $srch_rslts_page) or die "Cannot open previewpage '$preview_page' for reading: $!";
    open (RSLTTEMP, $srch_rslts_temp) or die "Cannot open srchrsltstemp '$srch_rslts_temp' for reading: $!";
  };
  if ($@){
    log_error("d_preview1", $@);
    return (99, $internal_error);
  }
  while (<PRVWPAGE>) {
    $preview_page_content .= $_;
  }
  close(PRVWPAGE);

  while (<RSLTTEMP>) {
    $srch_rslts_content .= $_;
  }
  close(RSLTTEMP);

  $preview_page_content =~ s/:::grepin-fld00:::/$user_id/g;
  $preview_page_content =~ s/:::grepin-fld01:::/$session_id/g;

  $preview_page_content =~ s/:::grepin-.*::://g;         # space out all the other fields

  $preview_page_content =~ s/:::search-results:::/$srch_rslts_content/g;

  print $preview_page_content;

  return (90, "success");

}



######################################################################################


sub d_bscadd {

  my $user_id    = $query->param('uid');
  my $session_id = $query->param('sid');
  my ($page_align, $browser_bgcolor, $page_bgcolor, $text_color, $link_color, $vlink_color, $alink_color, $page_width, $srch_bgcolor, $srch_width, $srch_align, $top_image_url, $top_image_height, $top_image_width, $top_image_align, $top_bar_html, $top_bar_title, $left_bar_width, $left_bar_html, $bot_image_url, $bot_image_height, $bot_image_width, $bot_image_align, $bot_bar_html);
  my $screen_html_file = $PAGE_DIR.'bscadd.html';
  my $screen_html;
  my $checked = "CHECKED";
  my $selected = "SELECTED";

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);
  };
  if ($@){
    log_error("d_bscadd1", $@);
    return (99, $internal_error);
  }

  $screen_html =~ s/:::grepin-1302:::/$selected/g; # page align     - left   (default)
  $screen_html =~ s/:::grepin-1303:::/$selected/g; # browserbgcolor - white  (default)
  $screen_html =~ s/:::grepin-1304:::/$selected/g; # pagebgcolor    - white  (default)
  $screen_html =~ s/:::grepin-1305:::/$selected/g; # textcolor      - white  (default)
  $screen_html =~ s/:::grepin-1306:::/$selected/g; # linkcolor      - blue   (default)
  $screen_html =~ s/:::grepin-1307:::/$selected/g; # vlinkcolor     - purple (default)
  $screen_html =~ s/:::grepin-1308:::/$selected/g; # alinkcolor     - red    (default)
  $screen_html =~ s/:::grepin-1309:::/"100"/g;     # pagewidth      - 100    (default)
  $screen_html =~ s/:::grepin-1310:::/$selected/g; # resultsbgcolor - white  (default)
  $screen_html =~ s/:::grepin-1312:::/$selected/g; # results align  - left  (default)
  $screen_html =~ s/:::grepin-1316:::/$selected/g; # topbar align   - left   (default)
  $screen_html =~ s/:::grepin-1319:::/$checked/g;  # leftbar exists - no     (default)
  $screen_html =~ s/:::grepin-1322:::/$checked/g;  # botbar exists  - no     (default)
  $screen_html =~ s/:::grepin-1326:::/$selected/g; # botbar align   - left   (default)

  return (0, $screen_html);

}



sub e_bscadd {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $user_id          = $query->param('uid');
  my $session_id       = $query->param('sid');
  my $function         = $query->param('fn');
  my $tmpl_title       = $query->param('s1301');
  my $page_align       = $query->param('s1302');
  my $browser_bgcolor  = $query->param('s1303');
  my $browser_bgcolorz = $query->param('s1303z');
  my $page_bgcolor     = $query->param('s1304');
  my $page_bgcolorz    = $query->param('s1304z');
  my $text_color       = $query->param('s1305');
  my $text_colorz      = $query->param('s1305z');
  my $link_color       = $query->param('s1306');
  my $link_colorz      = $query->param('s1306z');
  my $vlink_color      = $query->param('s1307');
  my $vlink_colorz     = $query->param('s1307z');
  my $alink_color      = $query->param('s1308');
  my $alink_colorz     = $query->param('s1308z');
  my $page_width       = $query->param('s1309');
  my $srch_bgcolor     = $query->param('s1310');
  my $srch_bgcolorz    = $query->param('s1310z');
  my $srch_width       = $query->param('s1311');
  my $srch_align       = $query->param('s1312');
  my $top_image_url    = $query->param('s1313');
  my $top_image_height = $query->param('s1314');
  my $top_image_width  = $query->param('s1315');
  my $top_image_align  = $query->param('s1316');
  my $top_bar_html     = $query->param('s1317');
  my $top_bar_title    = $query->param('s1318');
  my $left_bar_exists  = $query->param('s1319');
  my $left_bar_width   = $query->param('s1320');
  my $left_bar_html    = $query->param('s1321');
  my $bot_bar_exists   = $query->param('s1322');
  my $bot_image_url    = $query->param('s1323');
  my $bot_image_height = $query->param('s1324');
  my $bot_image_width  = $query->param('s1325');
  my $bot_image_align  = $query->param('s1326');
  my $bot_bar_html     = $query->param('s1327');
  my $screen_html_file = $PAGE_DIR.'bscadd.html';
  my $screen_html;
  my $checked = "CHECKED";
  my $selected = "SELECTED";
  my %user_tmpl_dbfile;
  my %top_bar_html_db;
  my %bot_bar_html_db;
  my %left_bar_html_db;
  my $db_key;

  use Fcntl;

  if ($function eq "save") {
    eval {
      tie %user_tmpl_dbfile, "DB_File", $USER_TEMPLATE_DATA_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_TEMPLATE_DATA_DB_FILE: $!";
      tie %top_bar_html_db, "DB_File", $TOP_BAR_HTML, O_RDONLY, 0755 or die "Cannot open $TOP_BAR_HTML: $!";
      tie %bot_bar_html_db, "DB_File", $BOT_BAR_HTML, O_RDONLY, 0755 or die "Cannot open $BOT_BAR_HTML: $!";
      tie %left_bar_html_db, "DB_File", $LEFT_BAR_HTML, O_RDONLY, 0755 or die "Cannot open $LEFT_BAR_HTML: $!";
    };
    if ($@){
      log_error("e_bscadd1", $@);
      return (99, $internal_error);
    }

    $db_key = $user_id . "temp" . $session_id;

    ($title, $page_align, $browser_bgcolor, $page_bgcolor, $text_color, $link_color, $vlink_color, $alink_color, $page_width, $srch_bgcolor, $srch_width, $srch_align, $top_image_url, $top_image_height, $top_image_width, $top_image_align, $top_bar_title, $left_bar_exists, $left_bar_width, $bot_bar_exists, $bot_image_url, $bot_image_height, $bot_image_width, $bot_image_align) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_tmpl_dbfile{$db_key});
    if ($top_bar_html_db{$db_key}) {
      $top_bar_html  = $top_bar_html_db{$db_key};
    }
    if ($bot_bar_html_db{$db_key}) {
      $bot_bar_html  = $bot_bar_html_db{$db_key};
    }
    if ($left_bar_html_db{$db_key}) {
      $left_bar_html = $left_bar_html_db{$db_key};
    }
    untie %user_tmpl_dbfile;
    untie %top_bar_html_db;
    untie %bot_bar_html_db;
    untie %left_bar_html_db;
  }

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);
  };
  if ($@){
    log_error("e_bscadd2", $@);
    return (99, $internal_error);
  }

  $error_msg = "Error:".$error_id." ".$error_msg;
  if ($error_id == 1329) {
    $screen_html =~ s/:::grepin-1329:::/$error_msg/g; # give the error message in 1329
  } elsif ($error_id == 1330) {
    $screen_html =~ s/:::grepin-1330:::/$error_msg/g; # give the error message in 1330
  } elsif ($error_id == 1331) {
    $screen_html =~ s/:::grepin-1331:::/$error_msg/g; # give the error message in 1331
  } else {
    $screen_html =~ s/:::grepin-1328:::/$error_msg/g; # give the error message in 1328
  }

  $screen_html =~ s/:::grepin-1301:::/$tmpl_title/g;

  if ($page_align eq "Center") {
    $screen_html =~ s/:::grepin-1302a:::/$selected/g;
  } elsif ($page_align eq "Right") {
    $screen_html =~ s/:::grepin-1302b:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-1302:::/$selected/g;
  }

  if ($browser_bgcolor eq "00ffff") {
    $screen_html =~ s/:::grepin-1303a:::/$selected/g;
  } elsif ($browser_bgcolor eq "000000") {
    $screen_html =~ s/:::grepin-1303b:::/$selected/g;
  } elsif ($browser_bgcolor eq "0000ff") {
    $screen_html =~ s/:::grepin-1303c:::/$selected/g;
  } elsif ($browser_bgcolor eq "ff00ff") {
    $screen_html =~ s/:::grepin-1303d:::/$selected/g;
  } elsif ($browser_bgcolor eq "808080") {
    $screen_html =~ s/:::grepin-1303e:::/$selected/g;
  } elsif ($browser_bgcolor eq "008000") {
    $screen_html =~ s/:::grepin-1303f:::/$selected/g;
  } elsif ($browser_bgcolor eq "00ff00") {
    $screen_html =~ s/:::grepin-1303g:::/$selected/g;
  } elsif ($browser_bgcolor eq "800000") {
    $screen_html =~ s/:::grepin-1303h:::/$selected/g;
  } elsif ($browser_bgcolor eq "000080") {
    $screen_html =~ s/:::grepin-1303i:::/$selected/g;
  } elsif ($browser_bgcolor eq "808000") {
    $screen_html =~ s/:::grepin-1303j:::/$selected/g;
  } elsif ($browser_bgcolor eq "xxxxxx") {
    $screen_html =~ s/:::grepin-1303k:::/$selected/g;
  } elsif ($browser_bgcolor eq "ff0000") {
    $screen_html =~ s/:::grepin-1303l:::/$selected/g;
  } elsif ($browser_bgcolor eq "c0c0c0") {
    $screen_html =~ s/:::grepin-1303m:::/$selected/g;
  } elsif ($browser_bgcolor eq "008080") {
    $screen_html =~ s/:::grepin-1303n:::/$selected/g;
  } elsif ($browser_bgcolor eq "ffff00") {
    $screen_html =~ s/:::grepin-1303p:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-1303:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-1303z:::/$browser_bgcolorz/g;

  if ($page_bgcolor eq "00ffff") {
    $screen_html =~ s/:::grepin-1304a:::/$selected/g;
  } elsif ($page_bgcolor eq "000000") {
    $screen_html =~ s/:::grepin-1304b:::/$selected/g;
  } elsif ($page_bgcolor eq "0000ff") {
    $screen_html =~ s/:::grepin-1304c:::/$selected/g;
  } elsif ($page_bgcolor eq "ff00ff") {
    $screen_html =~ s/:::grepin-1304d:::/$selected/g;
  } elsif ($page_bgcolor eq "808080") {
    $screen_html =~ s/:::grepin-1304e:::/$selected/g;
  } elsif ($page_bgcolor eq "008000") {
    $screen_html =~ s/:::grepin-1304f:::/$selected/g;
  } elsif ($page_bgcolor eq "00ff00") {
    $screen_html =~ s/:::grepin-1304g:::/$selected/g;
  } elsif ($page_bgcolor eq "800000") {
    $screen_html =~ s/:::grepin-1304h:::/$selected/g;
  } elsif ($page_bgcolor eq "000080") {
    $screen_html =~ s/:::grepin-1304i:::/$selected/g;
  } elsif ($page_bgcolor eq "808000") {
    $screen_html =~ s/:::grepin-1304j:::/$selected/g;
  } elsif ($page_bgcolor eq "xxxxxx") {
    $screen_html =~ s/:::grepin-1304k:::/$selected/g;
  } elsif ($page_bgcolor eq "ff0000") {
    $screen_html =~ s/:::grepin-1304l:::/$selected/g;
  } elsif ($page_bgcolor eq "c0c0c0") {
    $screen_html =~ s/:::grepin-1304m:::/$selected/g;
  } elsif ($page_bgcolor eq "008080") {
    $screen_html =~ s/:::grepin-1304n:::/$selected/g;
  } elsif ($page_bgcolor eq "ffff00") {
    $screen_html =~ s/:::grepin-1304p:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-1304:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-1304z:::/$page_bgcolorz/g;

  if ($text_color eq "00ffff") {
    $screen_html =~ s/:::grepin-1305a:::/$selected/g;
  } elsif ($text_color eq "0000ff") {
    $screen_html =~ s/:::grepin-1305c:::/$selected/g;
  } elsif ($text_color eq "ff00ff") {
    $screen_html =~ s/:::grepin-1305d:::/$selected/g;
  } elsif ($text_color eq "808080") {
    $screen_html =~ s/:::grepin-1305e:::/$selected/g;
  } elsif ($text_color eq "008000") {
    $screen_html =~ s/:::grepin-1305f:::/$selected/g;
  } elsif ($text_color eq "00ff00") {
    $screen_html =~ s/:::grepin-1305g:::/$selected/g;
  } elsif ($text_color eq "800000") {
    $screen_html =~ s/:::grepin-1305h:::/$selected/g;
  } elsif ($text_color eq "000080") {
    $screen_html =~ s/:::grepin-1305i:::/$selected/g;
  } elsif ($text_color eq "808000") {
    $screen_html =~ s/:::grepin-1305j:::/$selected/g;
  } elsif ($text_color eq "xxxxxx") {
    $screen_html =~ s/:::grepin-1305k:::/$selected/g;
  } elsif ($text_color eq "ff0000") {
    $screen_html =~ s/:::grepin-1305l:::/$selected/g;
  } elsif ($text_color eq "c0c0c0") {
    $screen_html =~ s/:::grepin-1305m:::/$selected/g;
  } elsif ($text_color eq "008080") {
    $screen_html =~ s/:::grepin-1305n:::/$selected/g;
  } elsif ($text_color eq "ffffff") {
    $screen_html =~ s/:::grepin-1305o:::/$selected/g;
  } elsif ($text_color eq "ffff00") {
    $screen_html =~ s/:::grepin-1305p:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-1305:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-1305z:::/$text_colorz/g;


  if ($link_color eq "00ffff") {
    $screen_html =~ s/:::grepin-1306a:::/$selected/g;
  } elsif ($link_color eq "000000") {
    $screen_html =~ s/:::grepin-1306b:::/$selected/g;
  } elsif ($link_color eq "ff00ff") {
    $screen_html =~ s/:::grepin-1306d:::/$selected/g;
  } elsif ($link_color eq "808080") {
    $screen_html =~ s/:::grepin-1306e:::/$selected/g;
  } elsif ($link_color eq "008000") {
    $screen_html =~ s/:::grepin-1306f:::/$selected/g;
  } elsif ($link_color eq "00ff00") {
    $screen_html =~ s/:::grepin-1306g:::/$selected/g;
  } elsif ($link_color eq "800000") {
    $screen_html =~ s/:::grepin-1306h:::/$selected/g;
  } elsif ($link_color eq "000080") {
    $screen_html =~ s/:::grepin-1306i:::/$selected/g;
  } elsif ($link_color eq "808000") {
    $screen_html =~ s/:::grepin-1306j:::/$selected/g;
  } elsif ($link_color eq "xxxxxx") {
    $screen_html =~ s/:::grepin-1306k:::/$selected/g;
  } elsif ($link_color eq "ff0000") {
    $screen_html =~ s/:::grepin-1306l:::/$selected/g;
  } elsif ($link_color eq "c0c0c0") {
    $screen_html =~ s/:::grepin-1306m:::/$selected/g;
  } elsif ($link_color eq "008080") {
    $screen_html =~ s/:::grepin-1306n:::/$selected/g;
  } elsif ($link_color eq "ffffff") {
    $screen_html =~ s/:::grepin-1306o:::/$selected/g;
  } elsif ($link_color eq "ffff00") {
    $screen_html =~ s/:::grepin-1306p:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-1306:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-1306z:::/$link_colorz/g;

  if ($vlink_color eq "00ffff") {
    $screen_html =~ s/:::grepin-1307a:::/$selected/g;
  } elsif ($vlink_color eq "000000") {
    $screen_html =~ s/:::grepin-1307b:::/$selected/g;
  } elsif ($vlink_color eq "0000ff") {
    $screen_html =~ s/:::grepin-1307c:::/$selected/g;
  } elsif ($vlink_color eq "ff00ff") {
    $screen_html =~ s/:::grepin-1307d:::/$selected/g;
  } elsif ($vlink_color eq "808080") {
    $screen_html =~ s/:::grepin-1307e:::/$selected/g;
  } elsif ($vlink_color eq "008000") {
    $screen_html =~ s/:::grepin-1307f:::/$selected/g;
  } elsif ($vlink_color eq "00ff00") {
    $screen_html =~ s/:::grepin-1307g:::/$selected/g;
  } elsif ($vlink_color eq "800000") {
    $screen_html =~ s/:::grepin-1307h:::/$selected/g;
  } elsif ($vlink_color eq "000080") {
    $screen_html =~ s/:::grepin-1307i:::/$selected/g;
  } elsif ($vlink_color eq "808000") {
    $screen_html =~ s/:::grepin-1307j:::/$selected/g;
  } elsif ($vlink_color eq "ff0000") {
    $screen_html =~ s/:::grepin-1307l:::/$selected/g;
  } elsif ($vlink_color eq "c0c0c0") {
    $screen_html =~ s/:::grepin-1307m:::/$selected/g;
  } elsif ($vlink_color eq "008080") {
    $screen_html =~ s/:::grepin-1307n:::/$selected/g;
  } elsif ($vlink_color eq "ffffff") {
    $screen_html =~ s/:::grepin-1307o:::/$selected/g;
  } elsif ($vlink_color eq "ffff00") {
    $screen_html =~ s/:::grepin-1307p:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-1307:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-1307z:::/$vlink_colorz/g;

  if ($alink_color eq "00ffff") {
    $screen_html =~ s/:::grepin-1308a:::/$selected/g;
  } elsif ($alink_color eq "000000") {
    $screen_html =~ s/:::grepin-1308b:::/$selected/g;
  } elsif ($alink_color eq "0000ff") {
    $screen_html =~ s/:::grepin-1308c:::/$selected/g;
  } elsif ($alink_color eq "ff00ff") {
    $screen_html =~ s/:::grepin-1308d:::/$selected/g;
  } elsif ($alink_color eq "808080") {
    $screen_html =~ s/:::grepin-1308e:::/$selected/g;
  } elsif ($alink_color eq "008000") {
    $screen_html =~ s/:::grepin-1308f:::/$selected/g;
  } elsif ($alink_color eq "00ff00") {
    $screen_html =~ s/:::grepin-1308g:::/$selected/g;
  } elsif ($alink_color eq "800000") {
    $screen_html =~ s/:::grepin-1308h:::/$selected/g;
  } elsif ($alink_color eq "000080") {
    $screen_html =~ s/:::grepin-1308i:::/$selected/g;
  } elsif ($alink_color eq "808000") {
    $screen_html =~ s/:::grepin-1308j:::/$selected/g;
  } elsif ($alink_color eq "xxxxxx") {
    $screen_html =~ s/:::grepin-1308k:::/$selected/g;
  } elsif ($alink_color eq "c0c0c0") {
    $screen_html =~ s/:::grepin-1308m:::/$selected/g;
  } elsif ($alink_color eq "008080") {
    $screen_html =~ s/:::grepin-1308n:::/$selected/g;
  } elsif ($alink_color eq "ffffff") {
    $screen_html =~ s/:::grepin-1308o:::/$selected/g;
  } elsif ($alink_color eq "ffff00") {
    $screen_html =~ s/:::grepin-1308p:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-1308:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-1308z:::/$alink_colorz/g;

  $screen_html =~ s/:::grepin-1309:::/$page_width/g;

  if ($srch_bgcolor eq "00ffff") {
    $screen_html =~ s/:::grepin-1310a:::/$selected/g;
  } elsif ($srch_bgcolor eq "000000") {
    $screen_html =~ s/:::grepin-1310b:::/$selected/g;
  } elsif ($srch_bgcolor eq "0000ff") {
    $screen_html =~ s/:::grepin-1310c:::/$selected/g;
  } elsif ($srch_bgcolor eq "ff00ff") {
    $screen_html =~ s/:::grepin-1310d:::/$selected/g;
  } elsif ($srch_bgcolor eq "808080") {
    $screen_html =~ s/:::grepin-1310e:::/$selected/g;
  } elsif ($srch_bgcolor eq "008000") {
    $screen_html =~ s/:::grepin-1310f:::/$selected/g;
  } elsif ($srch_bgcolor eq "00ff00") {
    $screen_html =~ s/:::grepin-1310g:::/$selected/g;
  } elsif ($srch_bgcolor eq "800000") {
    $screen_html =~ s/:::grepin-1310h:::/$selected/g;
  } elsif ($srch_bgcolor eq "000080") {
    $screen_html =~ s/:::grepin-1310i:::/$selected/g;
  } elsif ($srch_bgcolor eq "808000") {
    $screen_html =~ s/:::grepin-1310j:::/$selected/g;
  } elsif ($srch_bgcolor eq "xxxxxx") {
    $screen_html =~ s/:::grepin-1310k:::/$selected/g;
  } elsif ($srch_bgcolor eq "ff0000") {
    $screen_html =~ s/:::grepin-1310l:::/$selected/g;
  } elsif ($srch_bgcolor eq "c0c0c0") {
    $screen_html =~ s/:::grepin-1310m:::/$selected/g;
  } elsif ($srch_bgcolor eq "008080") {
    $screen_html =~ s/:::grepin-1310n:::/$selected/g;
  } elsif ($srch_bgcolor eq "ffff00") {
    $screen_html =~ s/:::grepin-1310p:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-1310:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-1310z:::/$srch_bgcolorz/g;

  $screen_html =~ s/:::grepin-1311:::/$srch_width/g;

  if ($srch_align eq "Center") {
    $screen_html =~ s/:::grepin-1312a:::/$selected/g;
  } elsif ($srch_align eq "Right") {
    $screen_html =~ s/:::grepin-1312b:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-1312:::/$selected/g;
  }

  $screen_html =~ s/:::grepin-1313:::/$top_image_url/g;
  $screen_html =~ s/:::grepin-1314:::/$top_image_height/g;
  $screen_html =~ s/:::grepin-1315:::/$top_image_width/g;

  if ($top_image_align eq "Center") {
    $screen_html =~ s/:::grepin-1316a:::/$selected/g;
  } elsif ($top_image_align eq "Right") {
    $screen_html =~ s/:::grepin-1316b:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-1316:::/$selected/g;
  }

  $screen_html =~ s/:::grepin-1317:::/$top_bar_html/g;
  $screen_html =~ s/:::grepin-1318:::/$top_bar_title/g;

  if ($left_bar_exists eq "Yes") {
    $screen_html =~ s/:::grepin-1319a:::/$checked/g;
  } else {
    $screen_html =~ s/:::grepin-1319:::/$checked/g;
  }

  $screen_html =~ s/:::grepin-1320:::/$left_bar_width/g;
  $screen_html =~ s/:::grepin-1321:::/$left_bar_html/g;

  if ($bot_bar_exists eq "Yes") {
    $screen_html =~ s/:::grepin-1322a:::/$checked/g;
  } else {
    $screen_html =~ s/:::grepin-1322:::/$checked/g;
  }

  $screen_html =~ s/:::grepin-1323:::/$bot_image_url/g;
  $screen_html =~ s/:::grepin-1324:::/$bot_image_height/g;
  $screen_html =~ s/:::grepin-1325:::/$bot_image_width/g;

  if ($bot_image_align eq "Center") {
    $screen_html =~ s/:::grepin-1326a:::/$selected/g;
  } elsif ($bot_image_align eq "Right") {
    $screen_html =~ s/:::grepin-1326b:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-1326:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-1327:::/$bot_bar_html/g;

  return (0, $screen_html);

}




sub p_bscaddprv {
# preview the search results page - basic add
# return codes
# 90 - success and the page is printed on the screen
#  1 - error in general settings
#  2 - error in top bar settings
#  3 - error in left bar settings
#  4 - error in bot bar settings
# 99 - database error

  my $user_id          = $query->param('uid');
  my $session_id       = $query->param('sid');
  my $tmpl_title       = $query->param('s1301');
  my $page_align       = $query->param('s1302');
  my $browser_bgcolor  = $query->param('s1303');;
  my $page_bgcolor     = $query->param('s1304');;
  my $text_color       = $query->param('s1305');;
  my $link_color       = $query->param('s1306');;
  my $vlink_color      = $query->param('s1307');;
  my $alink_color      = $query->param('s1308');;
  my $page_width       = $query->param('s1309');
  my $srch_bgcolor     = $query->param('s1310');;
  my $srch_width       = $query->param('s1311');
  my $srch_align       = $query->param('s1312');
  my $top_image_url    = $query->param('s1313');
  my $top_image_height = $query->param('s1314');
  my $top_image_width  = $query->param('s1315');
  my $top_image_align  = $query->param('s1316');
  my $top_bar_html     = $query->param('s1317');
  my $top_bar_title    = $query->param('s1318');
  my $left_bar_exists  = $query->param('s1319');
  my $left_bar_width   = $query->param('s1320');
  my $left_bar_html    = $query->param('s1321');
  my $bot_bar_exists   = $query->param('s1322');
  my $bot_image_url    = $query->param('s1323');
  my $bot_image_height = $query->param('s1324');
  my $bot_image_width  = $query->param('s1325');
  my $bot_image_align  = $query->param('s1326');
  my $bot_bar_html     = $query->param('s1327');
  my %user_tmpl_data;
  my %top_bar_html;
  my %bot_bar_html;
  my %left_bar_html;
  my %user_prof;
  my $web_addr;
  my $db_key;

  my $srch_rslts_tmpl_content;
  my $srch_rslts_page = $SRCH_USER_DIR.'templates/resultspage.html';
  my $preview_page    = $PAGE_DIR.'bscprv.html';
  my $srch_rslts_temp = $TMPL_DIR.'srchrsltstemp.html';
  my $preview_page_content;
  my $srch_rslts_content;

  use Fcntl;

  # change to upper case
  $tmpl_title         =~ tr/a-z/A-Z/;

  # change to lower case
  $top_image_url      =~ tr/A-Z/a-z/;
  $bot_image_url      =~ tr/A-Z/a-z/;

  # replace any white space to a single space
  $tmpl_title      =~ s/\s+/ /g;
  $browser_bgcolor =~ s/\s+/ /g;
  $page_bgcolor    =~ s/\s+/ /g;
  $text_color      =~ s/\s+/ /g;
  $link_color      =~ s/\s+/ /g;
  $vlink_color     =~ s/\s+/ /g;
  $alink_color     =~ s/\s+/ /g;
  $srch_bgcolor    =~ s/\s+/ /g;
  $top_image_url   =~ s/\s+/ /g;
  $top_bar_title   =~ s/\s+/ /g;
  $bot_image_url   =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $tmpl_title      =~ s/(^\s+)|(\s+$)//;
  $browser_bgcolor =~ s/(^\s+)|(\s+$)//;
  $page_bgcolor    =~ s/(^\s+)|(\s+$)//;
  $text_color      =~ s/(^\s+)|(\s+$)//;
  $link_color      =~ s/(^\s+)|(\s+$)//;
  $vlink_color     =~ s/(^\s+)|(\s+$)//;
  $alink_color     =~ s/(^\s+)|(\s+$)//;
  $srch_bgcolor    =~ s/(^\s+)|(\s+$)//;
  $top_image_url   =~ s/(^\s+)|(\s+$)//;
  $top_bar_title   =~ s/(^\s+)|(\s+$)//;
  $bot_image_url   =~ s/(^\s+)|(\s+$)//;


  # template title
  if (!$tmpl_title) {
    return(1, "Template Title cannot be empty.");
  }

  if ($tmpl_title !~ /[\dA-Z_]/) {
    return(1, "Template Title has invalid characters. A to Z, numbers and '_' are only allowed.");
  }

  # page align
  if (($page_align ne "Left") && ($page_align ne "Center") && ($page_align ne "Right")) {
    return (1, "Alignment of the Page should be Left, Center, or Right.");
  }

  # background color of the browser
  if (($query->param('s1303z') && ($query->param('s1303z') =~ /[\dA-Fa-f]{6}/)) {
    $browser_bgcolor = $query->param('s1303z');
  } else {
    return (1, "Browser Background Color should be a HEX code of 6 characters");
  }

  # background color of the page
  if (($query->param('s1304z') && ($query->param('s1304z') =~ /[\dA-Fa-f]{6}/)) {
    $page_bgcolor = $query->param('s1304z');
  } else {
    return (1, "Your Results Page Background Color should be a HEX code of 6 characters");
  }

  # text color
  if (($query->param('s1305z') && ($query->param('s1305z') =~ /[\dA-Fa-f]{6}/)) {
    $text_color = $query->param('s1305z');
  } else {
    return (1, "Text Color should be a HEX code of 6 characters");
  }

  # links color
  if (($query->param('s1306z') && ($query->param('s1306z') =~ /[\dA-Fa-f]{6}/)) {
    $link_color = $query->param('s1306z');
  } else {
    return (1, "Links Color should be a HEX code of 6 characters");
  }

  # vlink color
  if (($query->param('s1307z') && ($query->param('s1307z') =~ /[\dA-Fa-f]{6}/)) {
    $vlink_color = $query->param('s1307z');
  } else {
    return (1, "Visited Link Color should be a HEX code of 6 characters");
  }

  # alink color
  if (($query->param('s1308z') && ($query->param('s1308z') =~ /[\dA-Fa-f]{6}/)) {
    $alink_color = $query->param('s1308z');
  } else {
    return (1, "Active Link Color should be a HEX code of 6 characters");
  }

  # width of the page
  if (!$page_width) {
    $page_width = 80;
  } else {
    if ($page_width !~ /\d+/) {
      return (1, "Width of the Page shoud be a numeric value");
    }
    if (($page_width > 100) || ($page_width < 50)) {
      return (1, "Width of the Page should be between 50 and 100%.");
    }
  }

  # background color of search results area
  if (($query->param('s1310z') && ($query->param('s1310z') =~ /[\dA-Fa-f]{6}/)) {
    $srch_bgcolor = $query->param('s1310z')
  } else {
    return (1, "Color of Search Results Area should be a HEX code of 6 characters.");
  }

  # width of the search results area
  if (!$srch_width) {
    $srch_width = 100;
  } else {
    if ($srch_width !~ /\d+/) {
      return (1, "Width of the Search Results Area shoud be a numeric value");
    }
    if (($srch_width > 100) || ($srch_width < 50)) {
      return (1, "Width of the Search Results Area should be between 50 and 100%.");
    }
  }

  # search results area align
  if (($srch_align ne "Left") && ($srch_align ne "Center") && ($srch_align ne "Right")) {
    return (1, "Alignment of the Search Results Area should be Left, Center, or Right.");
  }

  # top bar
  if ($top_bar_html =~ /^\s+$/) {
    $top_bar_html = undef;
  }
  if ($top_bar_html) {
    if ($top_bar_html =~ /<html>|<body>|<\/html>|<\/body>/) {
      return (2, "HTML or BODY tags are not allowed in Top Bar Html. Please change the HTML and try again.")
    } else {
      $top_image_url    = undef;
      $top_image_height = undef;
      $top_image_width  = undef;
    }
  }

  if ($top_image_url) {
    if (($top_image_url !~ m%^http://.*%) && ($top_image_url !~ m%^https://.*%)) {
      return (2, "Invalid Top Bar Image URL - should start in http:// or https://.");
    }
    if (!$top_image_height) {
      $top_image_height = 100;
    } else {
      if ($top_image_height !~ /\d+/) {
        return (2, "Top Bar Image Height should be a numeric value.");
      }
    }
    if (!$top_image_width) {
      $top_image_width  = 700;
    } else {
      if ($top_image_width !~ /\d+/) {
        return (2, "Top Bar Image Width should be a numeric value.");
      }
    }
  }

  if ((!$top_bar_html) && (!$top_image_url) && (!$top_bar_title)) {
    return (2, "Top Bar HTML or Top Bar Image or Title should be specified.");
  }

  # left nav bar
  if ($left_bar_html =~ /^\s+$/) {
    $left_bar_html = undef;
  }
  if ($left_bar_exists eq "Yes") {
    if (($left_bar_html) && ($left_bar_html =~ /<html>|<body>|<\/html>|<\/body>/)) {
      return (3, "HTML or BODY tags are not allowed in Left Bar Html. Please change the HTML and try again.")
    }
    if (!$left_bar_width) {
      $left_bar_width = 0;
    } else {
      if ($left_bar_width !~ /\d+/) {
        return (3, "Width of Left Navigation Bar should be a numeric value.");
      }
      if ($left_bar_width > 180) {
        return (3, "Width of Left Navigation Bar should not exceed 180.");
      }
    }
  } else {
    $left_bar_exists = "No";
    $left_bar_width  = undef;
    $left_bar_html   = undef;
  }

  # bottom bar
  if ($bot_bar_html =~ /^\s+$/) {
    $bot_bar_html = undef;
  }
  if ($bot_bar_exists eq "Yes") {
    if ($bot_bar_html) {
      if ($bot_bar_html =~ /<html>|<body>|<\/html>|<\/body>/) {
        return (4, "HTML or BODY tags are not allowed in Bottom Bar Html. Please change the HTML and try again.")
      } else {
        $bot_image_url    = undef;
        $bot_image_height = undef;
        $bot_image_width  = undef;
      }
    }

    if ($bot_image_url) {
      if (($bot_image_url !~ m%^http://.*%) && ($bot_image_url !~ m%^https://.*%)) {
        return (4, "Invalid Bottom Bar Image URL - should start in http:// or https://.");
      }
      if (!$bot_image_height) {
        $bot_image_height = 100;
      } else {
        if ($bot_image_height !~ /\d+/) {
          return (4, "Bottom Bar Image Height should be a numeric value.");
        }
      }
      if (!$bot_image_width) {
        $bot_image_width  = 700;
      } else {
        if ($bot_image_width !~ /\d+/) {
          return (4, "Bottom Bar Image Width should be a numeric value.");
        }
      }
    }
  } else {
    $bot_bar_exists   = "No";
    $bot_image_url    = undef;
    $bot_image_height = undef;
    $bot_image_width  = undef;
    $bot_bar_html     = undef;
  }

  # bottom bar image align
  if (($bot_image_align ne "Left") && ($bot_image_align ne "Center") && ($bot_image_align ne "Right")) {
    return (4, "Alignment of the Bottom Bar Image should be Left, Center, or Right.");
  }


  # read profile database
  $db_key = $user_id;
  eval {
    tie %user_prof, "DB_File", $USER_PROFILE_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";
  };
  if ($@){
    log_error("p_bscaddprv0", $@);
    return (99, $internal_error);
  }

  ($d1, $web_addr, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_prof{$db_key});


  # create the user search results page
  #
  # read from the template page
  eval {
    open (TEMPLPAGE, $COMN_RESULTS_TEMPLATE) or die "Cannot open COMN_RESULTS_TEMPLATE '$COMN_RESULTS_TEMPLATE' for reading: $!";
    while (<TEMPLPAGE>) {
      $srch_rslts_tmpl_content .= $_;
    }
    close(TEMPLPAGE);
  };
  if ($@){
    log_error("p_bscaddprv1", $@);
    return (99, $internal_error);
  }

  # substitute the variables with the actual data
  $srch_rslts_tmpl_content =~ s/:::grepin-page-align:::/$page_align/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-browser-bgcolor:::/$browser_bgcolor/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-page-bgcolor:::/$page_bgcolor/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-text-color:::/$text_color/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-link-color:::/$link_color/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-vlink-color:::/$vlink_color/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-alink-color:::/$alink_color/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-page-width:::/$page_width/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-srch-bgcolor:::/$srch_bgcolor/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-srch-width:::/$srch_width/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-srch-align:::/$srch_align/g;

  if ($top_bar_html) {
    $srch_rslts_tmpl_content =~ s/:::grepin-start-top-bar:::.*:::grepin-end-top-bar:::/$top_bar_html/s;
    $srch_rslts_tmpl_content =~ s/:::grepin-start-top-title:::.*:::grepin-end-top-title::://g;
  } else {
    $srch_rslts_tmpl_content =~ s/:::grepin-top-image-align:::/$top_image_align/g;
    if ($top_image_url) {
      $srch_rslts_tmpl_content =~ s/:::grepin-start-top-bar:::|:::grepin-end-top-bar::://g;
      $srch_rslts_tmpl_content =~ s/:::grepin-top-image-url:::/$top_image_url/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-top-image-height:::/$top_image_height/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-top-image-width:::/$top_image_width/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-start-top-title:::.*:::grepin-end-top-title::://g;
    } else {
      $srch_rslts_tmpl_content =~ s/:::grepin-start-top-bar:::.*:::grepin-end-top-bar::://g;
      $srch_rslts_tmpl_content =~ s/:::grepin-start-top-title:::|:::grepin-end-top-title::://g;
      $srch_rslts_tmpl_content =~ s/:::grepin-top-title:::/$top_bar_title/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-home-link:::/$web_addr/g;
    }
  }

  $srch_rslts_tmpl_content =~ s/:::grepin-left-bar-width:::/$left_bar_width/g;
  if ($left_bar_html) {
    $srch_rslts_tmpl_content =~ s/:::grepin-left-bar-html:::/$left_bar_html/g;
  } else {
    $srch_rslts_tmpl_content =~ s/:::grepin-left-bar-html::://g;
  }

  if ($bot_bar_exists eq "Yes") {
    if ($bot_bar_html) {
      $srch_rslts_tmpl_content =~ s/:::grepin-start-bot-bar:::.*:::grepin-end-bot-bar:::/$bot_bar_html/s;
    } else {
      $srch_rslts_tmpl_content =~ s/:::grepin-start-bot-bar:::|:::grepin-end-bot-bar::://g;
      $srch_rslts_tmpl_content =~ s/:::grepin-bot-image-url:::/$bot_image_url/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-bot-image-height:::/$bot_image_height/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-bot-image-width:::/$bot_image_width/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-bot-image-align:::/$bot_image_align/g;
    }
  } else {
    $srch_rslts_tmpl_content =~ s/:::grepin-start-bot-bar:::.*:::grepin-end-bot-bar::://s;
  }

  # create the preview page
  #
  eval {
    open (PRVWPAGE, $preview_page) or die "Cannot open previewpage '$preview_page' for reading: $!";
    while (<PRVWPAGE>) {
      $preview_page_content .= $_;
    }
    close(PRVWPAGE);

    open (RSLTTEMP, $srch_rslts_temp) or die "Cannot open srchrsltstemp '$srch_rslts_temp' for reading: $!";
    while (<RSLTTEMP>) {
      $srch_rslts_content .= $_;
    }
    close(RSLTTEMP);
  };
  if ($@){
    log_error("p_bscaddprv2", $@);
    return (99, $internal_error);
  }

  # update user_tmpl_data, top_bar_html, bot_bar_html, left_bar_html
  eval {
    tie %user_tmpl_data, "DB_File", $USER_TEMPLATE_DATA_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_TEMPLATE_DATA_DB_FILE: $!";
    tie %top_bar_html_db, "DB_File", $TOP_BAR_HTML, O_CREAT|O_RDWR, 0755 or die "Cannot open $TOP_BAR_HTML: $!";
    tie %bot_bar_html_db, "DB_File", $BOT_BAR_HTML, O_CREAT|O_RDWR, 0755 or die "Cannot open $BOT_BAR_HTML: $!";
    tie %left_bar_html_db, "DB_File", $LEFT_BAR_HTML, O_CREAT|O_RDWR, 0755 or die "Cannot open $LEFT_BAR_HTML: $!";

    $db_key = $user_id . "temp" . $session_id;

    $user_tmpl_data{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $tmpl_title, $page_align, $browser_bgcolor, $page_bgcolor, $text_color, $link_color, $vlink_color, $alink_color, $page_width, $srch_bgcolor, $srch_width, $srch_align, $top_image_url, $top_image_height, $top_image_width, $top_image_align, $top_bar_title, $left_bar_exists, $left_bar_width, $bot_bar_exists, $bot_image_url, $bot_image_height, $bot_image_width, $bot_image_align);
    if ($top_bar_html) {
      $tob_bar_html_db{$db_key};
    }
    if ($bot_bar_html) {
      $bot_bar_html_db{$db_key};
    }
    if ($left_bar_html) {
      $left_bar_html_db{$db_key};
    }
    untie %user_tmpl_data;
    untie %tob_bar_html_db;
    untie %bot_bar_html_db;
    untie %left_bar_html_db;
  };
  if ($@){
    log_error("p_bscaddprv3", $@);
    return (99, $internal_error);
  }

  $preview_page_content =~ s/:::grepin-fld00:::/$user_id/g;
  $preview_page_content =~ s/:::grepin-fld01:::/$session_id/g;

  $preview_page_content .= $srch_rslts_tmpl_content;

  $preview_page_content =~ s/:::grepin-.*::://g;         # space out all the other fields

  $preview_page_content =~ s/:::search-results:::/$srch_rslts_content/g;

  print $preview_page_content;

  return (90, "success");

}




######################################################################################


sub e_advadd {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $user_id    = $query->param('uid');
  my $session_id = $query->param('sid');
  my $function   = $query->param('fn');
  my $tmpl_title = $query->param('s1401');
  my $temp_page              = $SRCH_USER_DIR.'templates/temppage.html';
  my $results_form_html;
  my $screen_html_file       = $PAGE_DIR.'advadd.html';
  my $screen_html;

  use Fcntl;

  if ($function eq "save") {
    eval {
      if (-e $temp_page) {
        open (RSLTFILE, $temp_page) or die "Cannot open temppage '$temp_page' for reading: $!";
        while (<RSLTFILE>) {
          $results_form_html .= $_;
        }
        close(RSLTFILE);
      }
    };
    if ($@){
      log_error("e_advadd0", $@);
      return (99, $internal_error);
    }
  } else {
    $results_form_html = $query->param('s1402');
  }

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);
  };
  if ($@){
    log_error("e_advadd1", $@);
    return (99, $internal_error);
  }

  $error_msg = "Error:".$error_id." ".$error_msg;
  $screen_html =~ s/:::grepin-1403:::/$error_msg/g; # give the error message
  $screen_html =~ s/:::grepin-1401:::/$tmpl_title;
  $screen_html =~ s/:::grepin-1402:::/$results_form_html/g;

  return (0, $screen_html);

}




sub p_advaddprv {
# preview results - advanced way...
# return codes
# 90 - success and the page is printed on the screen
#  1 - title is missing
#  2 - invalid characters in title
#  3 - html code missing
#  4 - :::search-results::: phrase missing
# 99 - database error

  my $user_id         = $query->param('uid');
  my $session_id      = $query->param('sid');
  my $tmpl_title      = $query->param('s1401');
  my $template_html   = $query->param('s1402');

  my $temp_page       = $SRCH_USER_DIR.'templates/temppage.html';
  my $preview_page    = $PAGE_DIR.'advprv.html';
  my $srch_rslts_temp = $TMPL_DIR.'srchrsltstemp.html';
  my $preview_page_content;
  my $srch_rslts_content;
  my %user_tmpl_data;

  use Fcntl;

  $tmpl_title   =~ tr/a-z/A-Z/;       # change case
  $tmpl_title   =~ s/\s+/ /g;         # replace any white space to a single space
  $tmpl_title   =~ s/(^\s+)|(\s+$)//; # remove leading and trailing whitespace

  if (!$tmpl_title) {
    return(1, "Template Title cannot be empty.");
  }

  if ($tmpl_title !~ /[\dA-Z_]/) {
    return(2, "Template Title has invalid characters. A to Z, numbers and '_' are only allowed.");
  }

  if ($template_html =~ /^\s+$/) {
    return(3, "The HTML code is missing. Please enter it and try again.");
  }

  if ($template_html !~ /:::search-results:::/) {
    return(4, "The HTML code should contain the phrase :::search-results::: Please correct the HTML and try again.");
  }

  # create the preview page
  #
  eval {
    open (PRVWPAGE, $preview_page) or die "Cannot open previewpage '$preview_page' for reading: $!";
    while (<PRVWPAGE>) {
      $preview_page_content .= $_;
    }
    close(PRVWPAGE);

    open (RSLTTEMP, $srch_rslts_temp) or die "Cannot open srchrsltstemp '$srch_rslts_temp' for reading: $!";
    while (<RSLTTEMP>) {
      $srch_rslts_content .= $_;
    }
    close(RSLTTEMP);
  };
  if ($@){
    log_error("p_advaddprv0", $@);
    return (99, $internal_error);
  }

  # write to user temporary search results page
  use Fcntl ':flock';        # import LOCK_* constants
  eval {
    open(TEMPPAGE, ">$temp_page") or die "Cannot open temppage '$temp_page' for writing: $!";
    flock(TEMPPAGE, LOCK_EX);
    seek(TEMPPAGE, 0, 2);
    print TEMPPAGE "$template_html\n";
    flock(TEMPPAGE, LOCK_UN);
    close(TEMPPAGE);
  };
  if ($@){
    log_error("p_advaddprv1", $@);
    return (99, $internal_error);
  }

  eval {
    tie %user_tmpl_data, "DB_File", $USER_TEMPLATE_DATA_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_TEMPLATE_DATA_DB_FILE: $!";
    $db_key = $user_id . "temp" . $session_id;
    $d1 = undef;
    $user_tmpl_data{$db_key} = pack("C/A* C/A*", $tmpl_title, $d1);
    untie %user_tmpl_data;
  };
  if ($@){
    log_error("p_advaddprv2", $@);
    return (99, $internal_error);
  }

  $preview_page_content =~ s/:::grepin-fld00:::/$user_id/g;
  $preview_page_content =~ s/:::grepin-fld01:::/$session_id/g;

  $preview_page_content .= $template_html;

  $preview_page_content =~ s/:::grepin-.*::://g;         # space out all the other fields

  $preview_page_content =~ s/:::search-results:::/$srch_rslts_content/g;

  print $preview_page_content;

  return (90, "success");

}



######################################################################################


sub d_bscedit {

  my $user_id    = $query->param('uid');
  my $session_id = $query->param('sid');
  my $tmpl_id    = $query->param('id');
  my %user_tmpl_dbfile;
  my %top_bar_html_db;
  my %bot_bar_html_db;
  my %left_bar_html_db;
  my $db_key;
  my ($tmpl_title, $page_align, $browser_bgcolor, $page_bgcolor, $text_color, $link_color, $vlink_color, $alink_color, $page_width, $srch_bgcolor, $srch_width, $srch_align, $top_image_url, $top_image_height, $top_image_width, $top_image_align, $top_bar_html, $top_bar_title, $left_bar_width, $left_bar_html, $bot_image_url, $bot_image_height, $bot_image_width, $bot_image_align, $bot_bar_html);
  my $screen_html_file = $PAGE_DIR.'bscedit.html';
  my $screen_html;
  my $checked = "CHECKED";
  my $selected = "SELECTED";

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %user_tmpl_dbfile, "DB_File", $USER_TEMPLATE_DATA_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_TEMPLATE_DATA_DB_FILE: $!";
    tie %top_bar_html_db, "DB_File", $TOP_BAR_HTML, O_RDONLY, 0755 or die "Cannot open $TOP_BAR_HTML: $!";
    tie %bot_bar_html_db, "DB_File", $BOT_BAR_HTML, O_RDONLY, 0755 or die "Cannot open $BOT_BAR_HTML: $!";
    tie %left_bar_html_db, "DB_File", $LEFT_BAR_HTML, O_RDONLY, 0755 or die "Cannot open $LEFT_BAR_HTML: $!";

    $db_key = $user_id . $tmpl_id;

    if (!$user_tmpl_dbfile{$db_key}) {
      return (1, "This template is not found. Please create a new template.");
    } else {
      ($tmpl_title, $page_align, $browser_bgcolor, $page_bgcolor, $text_color, $link_color, $vlink_color, $alink_color, $page_width, $srch_bgcolor, $srch_width, $srch_align, $top_image_url, $top_image_height, $top_image_width, $top_image_align, $top_bar_title, $left_bar_exists, $left_bar_width, $bot_bar_exists, $bot_image_url, $bot_image_height, $bot_image_width, $bot_image_align) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_tmpl_dbfile{$db_key});
      if ($top_bar_html_db{$db_key}) {
        $top_bar_html = $top_bar_html_db{$db_key};
      } else {
        $top_bar_html = undef;
      }
      if ($bot_bar_html_db{$db_key}) {
        $bot_bar_html = $bot_bar_html_db{$db_key};
      } else {
        $bot_bar_html = undef;
      }
      if ($left_bar_html_db{$db_key}) {
        $left_bar_html = $left_bar_html_db{$db_key};
      } else {
        $left_bar_html = undef;
      }

    }
    untie %user_tmpl_dbfile;
    untie %top_bar_html_db;
    untie %bot_bar_html_db;
    untie %left_bar_html_db;
  }
  };
  if ($@){
    log_error("d_cnfgrsltb1", $@);
    return (99, $internal_error);
  }

  $screen_html =~ s/:::grepin-0900:::/$tmpl_id/g;
  $screen_html =~ s/:::grepin-0901:::/$tmpl_title/g;

  if ($page_align eq "Center") {
    $screen_html =~ s/:::grepin-0902a:::/$selected/g;
  } elsif ($page_align eq "Right") {
    $screen_html =~ s/:::grepin-0902b:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0902:::/$selected/g;
  }

  if ($browser_bgcolor eq "00ffff") {
    $screen_html =~ s/:::grepin-0903a:::/$selected/g;
  } elsif ($browser_bgcolor eq "000000") {
    $screen_html =~ s/:::grepin-0903b:::/$selected/g;
  } elsif ($browser_bgcolor eq "0000ff") {
    $screen_html =~ s/:::grepin-0903c:::/$selected/g;
  } elsif ($browser_bgcolor eq "ff00ff") {
    $screen_html =~ s/:::grepin-0903d:::/$selected/g;
  } elsif ($browser_bgcolor eq "808080") {
    $screen_html =~ s/:::grepin-0903e:::/$selected/g;
  } elsif ($browser_bgcolor eq "008000") {
    $screen_html =~ s/:::grepin-0903f:::/$selected/g;
  } elsif ($browser_bgcolor eq "00ff00") {
    $screen_html =~ s/:::grepin-0903g:::/$selected/g;
  } elsif ($browser_bgcolor eq "800000") {
    $screen_html =~ s/:::grepin-0903h:::/$selected/g;
  } elsif ($browser_bgcolor eq "000080") {
    $screen_html =~ s/:::grepin-0903i:::/$selected/g;
  } elsif ($browser_bgcolor eq "808000") {
    $screen_html =~ s/:::grepin-0903j:::/$selected/g;
  } elsif ($browser_bgcolor eq "a020f0") {
    $screen_html =~ s/:::grepin-0903k:::/$selected/g;
  } elsif ($browser_bgcolor eq "ff0000") {
    $screen_html =~ s/:::grepin-0903l:::/$selected/g;
  } elsif ($browser_bgcolor eq "c0c0c0") {
    $screen_html =~ s/:::grepin-0903m:::/$selected/g;
  } elsif ($browser_bgcolor eq "008080") {
    $screen_html =~ s/:::grepin-0903n:::/$selected/g;
  } elsif ($browser_bgcolor eq "ffff00") {
    $screen_html =~ s/:::grepin-0903p:::/$selected/g;
  } elsif ($browser_bgcolor eq "ffffff") {
    $screen_html =~ s/:::grepin-0903:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0903:::/$selected/g;
    $screen_html =~ s/:::grepin-0903z:::/$browser_bgcolor/g;
  }

  if ($page_bgcolor eq "00ffff") {
    $screen_html =~ s/:::grepin-0904a:::/$selected/g;
  } elsif ($page_bgcolor eq "000000") {
    $screen_html =~ s/:::grepin-0904b:::/$selected/g;
  } elsif ($page_bgcolor eq "0000ff") {
    $screen_html =~ s/:::grepin-0904c:::/$selected/g;
  } elsif ($page_bgcolor eq "ff00ff") {
    $screen_html =~ s/:::grepin-0904d:::/$selected/g;
  } elsif ($page_bgcolor eq "808080") {
    $screen_html =~ s/:::grepin-0904e:::/$selected/g;
  } elsif ($page_bgcolor eq "008000") {
    $screen_html =~ s/:::grepin-0904f:::/$selected/g;
  } elsif ($page_bgcolor eq "00ff00") {
    $screen_html =~ s/:::grepin-0904g:::/$selected/g;
  } elsif ($page_bgcolor eq "800000") {
    $screen_html =~ s/:::grepin-0904h:::/$selected/g;
  } elsif ($page_bgcolor eq "000080") {
    $screen_html =~ s/:::grepin-0904i:::/$selected/g;
  } elsif ($page_bgcolor eq "808000") {
    $screen_html =~ s/:::grepin-0904j:::/$selected/g;
  } elsif ($page_bgcolor eq "a020f0") {
    $screen_html =~ s/:::grepin-0904k:::/$selected/g;
  } elsif ($page_bgcolor eq "ff0000") {
    $screen_html =~ s/:::grepin-0904l:::/$selected/g;
  } elsif ($page_bgcolor eq "c0c0c0") {
    $screen_html =~ s/:::grepin-0904m:::/$selected/g;
  } elsif ($page_bgcolor eq "008080") {
    $screen_html =~ s/:::grepin-0904n:::/$selected/g;
  } elsif ($page_bgcolor eq "ffff00") {
    $screen_html =~ s/:::grepin-0904p:::/$selected/g;
  } elsif ($page_bgcolor eq "ffffff") {
    $screen_html =~ s/:::grepin-0904:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0904:::/$selected/g;
    $screen_html =~ s/:::grepin-0904z:::/$page_bgcolor/g;
  }

  if ($text_color eq "00ffff") {
    $screen_html =~ s/:::grepin-0908a:::/$selected/g;
  } elsif ($text_color eq "0000ff") {
    $screen_html =~ s/:::grepin-0908c:::/$selected/g;
  } elsif ($text_color eq "ff00ff") {
    $screen_html =~ s/:::grepin-0908d:::/$selected/g;
  } elsif ($text_color eq "808080") {
    $screen_html =~ s/:::grepin-0908e:::/$selected/g;
  } elsif ($text_color eq "008000") {
    $screen_html =~ s/:::grepin-0908f:::/$selected/g;
  } elsif ($text_color eq "00ff00") {
    $screen_html =~ s/:::grepin-0908g:::/$selected/g;
  } elsif ($text_color eq "800000") {
    $screen_html =~ s/:::grepin-0908h:::/$selected/g;
  } elsif ($text_color eq "000080") {
    $screen_html =~ s/:::grepin-0908i:::/$selected/g;
  } elsif ($text_color eq "808000") {
    $screen_html =~ s/:::grepin-0908j:::/$selected/g;
  } elsif ($text_color eq "a020f0") {
    $screen_html =~ s/:::grepin-0908k:::/$selected/g;
  } elsif ($text_color eq "ff0000") {
    $screen_html =~ s/:::grepin-0908l:::/$selected/g;
  } elsif ($text_color eq "c0c0c0") {
    $screen_html =~ s/:::grepin-0908m:::/$selected/g;
  } elsif ($text_color eq "008080") {
    $screen_html =~ s/:::grepin-0908n:::/$selected/g;
  } elsif ($text_color eq "ffffff") {
    $screen_html =~ s/:::grepin-0908o:::/$selected/g;
  } elsif ($text_color eq "ffff00") {
    $screen_html =~ s/:::grepin-0908p:::/$selected/g;
  } elsif ($text_color eq "000000") {
    $screen_html =~ s/:::grepin-0908:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0908:::/$selected/g;
    $screen_html =~ s/:::grepin-0908z:::/$text_color/g;
  }


  if ($link_color eq "00ffff") {
    $screen_html =~ s/:::grepin-0906a:::/$selected/g;
  } elsif ($link_color eq "000000") {
    $screen_html =~ s/:::grepin-0906b:::/$selected/g;
  } elsif ($link_color eq "ff00ff") {
    $screen_html =~ s/:::grepin-0906d:::/$selected/g;
  } elsif ($link_color eq "808080") {
    $screen_html =~ s/:::grepin-0906e:::/$selected/g;
  } elsif ($link_color eq "008000") {
    $screen_html =~ s/:::grepin-0906f:::/$selected/g;
  } elsif ($link_color eq "00ff00") {
    $screen_html =~ s/:::grepin-0906g:::/$selected/g;
  } elsif ($link_color eq "800000") {
    $screen_html =~ s/:::grepin-0906h:::/$selected/g;
  } elsif ($link_color eq "000080") {
    $screen_html =~ s/:::grepin-0906i:::/$selected/g;
  } elsif ($link_color eq "808000") {
    $screen_html =~ s/:::grepin-0906j:::/$selected/g;
  } elsif ($link_color eq "a020f0") {
    $screen_html =~ s/:::grepin-0906k:::/$selected/g;
  } elsif ($link_color eq "ff0000") {
    $screen_html =~ s/:::grepin-0906l:::/$selected/g;
  } elsif ($link_color eq "c0c0c0") {
    $screen_html =~ s/:::grepin-0906m:::/$selected/g;
  } elsif ($link_color eq "008080") {
    $screen_html =~ s/:::grepin-0906n:::/$selected/g;
  } elsif ($link_color eq "ffffff") {
    $screen_html =~ s/:::grepin-0906o:::/$selected/g;
  } elsif ($link_color eq "ffff00") {
    $screen_html =~ s/:::grepin-0906p:::/$selected/g;
  } elsif ($link_color eq "0000ff") {
    $screen_html =~ s/:::grepin-0906:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0906:::/$selected/g;
    $screen_html =~ s/:::grepin-0906z:::/$link_color/g;
  }

  if ($vlink_color eq "00ffff") {
    $screen_html =~ s/:::grepin-0907a:::/$selected/g;
  } elsif ($vlink_color eq "000000") {
    $screen_html =~ s/:::grepin-0907b:::/$selected/g;
  } elsif ($vlink_color eq "0000ff") {
    $screen_html =~ s/:::grepin-0907c:::/$selected/g;
  } elsif ($vlink_color eq "ff00ff") {
    $screen_html =~ s/:::grepin-0907d:::/$selected/g;
  } elsif ($vlink_color eq "808080") {
    $screen_html =~ s/:::grepin-0907e:::/$selected/g;
  } elsif ($vlink_color eq "008000") {
    $screen_html =~ s/:::grepin-0907f:::/$selected/g;
  } elsif ($vlink_color eq "00ff00") {
    $screen_html =~ s/:::grepin-0907g:::/$selected/g;
  } elsif ($vlink_color eq "800000") {
    $screen_html =~ s/:::grepin-0907h:::/$selected/g;
  } elsif ($vlink_color eq "000080") {
    $screen_html =~ s/:::grepin-0907i:::/$selected/g;
  } elsif ($vlink_color eq "808000") {
    $screen_html =~ s/:::grepin-0907j:::/$selected/g;
  } elsif ($vlink_color eq "ff0000") {
    $screen_html =~ s/:::grepin-0907l:::/$selected/g;
  } elsif ($vlink_color eq "c0c0c0") {
    $screen_html =~ s/:::grepin-0907m:::/$selected/g;
  } elsif ($vlink_color eq "008080") {
    $screen_html =~ s/:::grepin-0907n:::/$selected/g;
  } elsif ($vlink_color eq "ffffff") {
    $screen_html =~ s/:::grepin-0907o:::/$selected/g;
  } elsif ($vlink_color eq "ffff00") {
    $screen_html =~ s/:::grepin-0907p:::/$selected/g;
  } elsif ($vlink_color eq "a020f0") {
    $screen_html =~ s/:::grepin-0907:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0907:::/$selected/g;
    $screen_html =~ s/:::grepin-0907z:::/$vlink_color/g;
  }

  if ($alink_color eq "00ffff") {
    $screen_html =~ s/:::grepin-0908a:::/$selected/g;
  } elsif ($alink_color eq "000000") {
    $screen_html =~ s/:::grepin-0908b:::/$selected/g;
  } elsif ($alink_color eq "0000ff") {
    $screen_html =~ s/:::grepin-0908c:::/$selected/g;
  } elsif ($alink_color eq "ff00ff") {
    $screen_html =~ s/:::grepin-0908d:::/$selected/g;
  } elsif ($alink_color eq "808080") {
    $screen_html =~ s/:::grepin-0908e:::/$selected/g;
  } elsif ($alink_color eq "008000") {
    $screen_html =~ s/:::grepin-0908f:::/$selected/g;
  } elsif ($alink_color eq "00ff00") {
    $screen_html =~ s/:::grepin-0908g:::/$selected/g;
  } elsif ($alink_color eq "800000") {
    $screen_html =~ s/:::grepin-0908h:::/$selected/g;
  } elsif ($alink_color eq "000080") {
    $screen_html =~ s/:::grepin-0908i:::/$selected/g;
  } elsif ($alink_color eq "808000") {
    $screen_html =~ s/:::grepin-0908j:::/$selected/g;
  } elsif ($alink_color eq "a020f0") {
    $screen_html =~ s/:::grepin-0908k:::/$selected/g;
  } elsif ($alink_color eq "c0c0c0") {
    $screen_html =~ s/:::grepin-0908m:::/$selected/g;
  } elsif ($alink_color eq "008080") {
    $screen_html =~ s/:::grepin-0908n:::/$selected/g;
  } elsif ($alink_color eq "ffffff") {
    $screen_html =~ s/:::grepin-0908o:::/$selected/g;
  } elsif ($alink_color eq "ffff00") {
    $screen_html =~ s/:::grepin-0908p:::/$selected/g;
  } elsif ($alink_color eq "ff0000") {
    $screen_html =~ s/:::grepin-0908:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0908:::/$selected/g;
    $screen_html =~ s/:::grepin-0908z:::/$alink_color/g;
  }

  $screen_html =~ s/:::grepin-0909:::/$page_width/g;

  if ($srch_bgcolor eq "00ffff") {
    $screen_html =~ s/:::grepin-0910a:::/$selected/g;
  } elsif ($srch_bgcolor eq "000000") {
    $screen_html =~ s/:::grepin-0910b:::/$selected/g;
  } elsif ($srch_bgcolor eq "0000ff") {
    $screen_html =~ s/:::grepin-0910c:::/$selected/g;
  } elsif ($srch_bgcolor eq "ff00ff") {
    $screen_html =~ s/:::grepin-0910d:::/$selected/g;
  } elsif ($srch_bgcolor eq "808080") {
    $screen_html =~ s/:::grepin-0910e:::/$selected/g;
  } elsif ($srch_bgcolor eq "008000") {
    $screen_html =~ s/:::grepin-0910f:::/$selected/g;
  } elsif ($srch_bgcolor eq "00ff00") {
    $screen_html =~ s/:::grepin-0910g:::/$selected/g;
  } elsif ($srch_bgcolor eq "800000") {
    $screen_html =~ s/:::grepin-0910h:::/$selected/g;
  } elsif ($srch_bgcolor eq "000080") {
    $screen_html =~ s/:::grepin-0910i:::/$selected/g;
  } elsif ($srch_bgcolor eq "808000") {
    $screen_html =~ s/:::grepin-0910j:::/$selected/g;
  } elsif ($srch_bgcolor eq "a020f0") {
    $screen_html =~ s/:::grepin-0910k:::/$selected/g;
  } elsif ($srch_bgcolor eq "ff0000") {
    $screen_html =~ s/:::grepin-0910l:::/$selected/g;
  } elsif ($srch_bgcolor eq "c0c0c0") {
    $screen_html =~ s/:::grepin-0910m:::/$selected/g;
  } elsif ($srch_bgcolor eq "008080") {
    $screen_html =~ s/:::grepin-0910n:::/$selected/g;
  } elsif ($srch_bgcolor eq "ffff00") {
    $screen_html =~ s/:::grepin-0910p:::/$selected/g;
  } elsif ($srch_bgcolor eq "ffffff") {
    $screen_html =~ s/:::grepin-0910:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0910:::/$selected/g;
    $screen_html =~ s/:::grepin-0910z:::/$srch_bgcolor/g;
  }

  $screen_html =~ s/:::grepin-0911:::/$srch_width/g;

  if ($srch_align eq "Center") {
    $screen_html =~ s/:::grepin-0912a:::/$selected/g;
  } elsif ($srch_align eq "Right") {
    $screen_html =~ s/:::grepin-0912b:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0912:::/$selected/g;
  }

  $screen_html =~ s/:::grepin-0913:::/$top_image_url/g;
  $screen_html =~ s/:::grepin-0914:::/$top_image_height/g;
  $screen_html =~ s/:::grepin-0915:::/$top_image_width/g;

  if ($top_image_align eq "Center") {
    $screen_html =~ s/:::grepin-0916a:::/$selected/g;
  } elsif ($top_image_align eq "Right") {
    $screen_html =~ s/:::grepin-0916b:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0916:::/$selected/g;
  }

  $screen_html =~ s/:::grepin-0917:::/$top_bar_html/g;
  $screen_html =~ s/:::grepin-0918:::/$top_bar_title/g;

  if ($left_bar_exists eq "Yes") {
    $screen_html =~ s/:::grepin-0919a:::/$checked/g;
  } else {
    $screen_html =~ s/:::grepin-0919:::/$checked/g;
  }

  $screen_html =~ s/:::grepin-0920:::/$left_bar_width/g;
  $screen_html =~ s/:::grepin-0921:::/$left_bar_html/g;

  if ($bot_bar_exists eq "Yes") {
    $screen_html =~ s/:::grepin-0922a:::/$checked/g;
  } else {
    $screen_html =~ s/:::grepin-0922:::/$checked/g;
  }

  $screen_html =~ s/:::grepin-0923:::/$bot_image_url/g;
  $screen_html =~ s/:::grepin-0924:::/$bot_image_height/g;
  $screen_html =~ s/:::grepin-0925:::/$bot_image_width/g;

  if ($bot_image_align eq "Center") {
    $screen_html =~ s/:::grepin-0926a:::/$selected/g;
  } elsif ($bot_image_align eq "Right") {
    $screen_html =~ s/:::grepin-0926b:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0926:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-0927:::/$bot_bar_html/g;

  return (0, $screen_html);

}




sub e_bscedit {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $user_id          = $query->param('uid');
  my $session_id       = $query->param('sid');
  my $tmpl_id          = $query->param('id');
  my $function         = $query->param('fn');
  my $tmpl_title       = $query->param('s0901');
  my $page_align       = $query->param('s0902');
  my $browser_bgcolor  = $query->param('s0903');
  my $browser_bgcolorz = $query->param('s0903z');
  my $page_bgcolor     = $query->param('s0904');
  my $page_bgcolorz    = $query->param('s0904z');
  my $text_color       = $query->param('s0905');
  my $text_colorz      = $query->param('s0905z');
  my $link_color       = $query->param('s0906');
  my $link_colorz      = $query->param('s0906z');
  my $vlink_color      = $query->param('s0907');
  my $vlink_colorz     = $query->param('s0907z');
  my $alink_color      = $query->param('s0908');
  my $alink_colorz     = $query->param('s0908z');
  my $page_width       = $query->param('s0909');
  my $srch_bgcolor     = $query->param('s0910');
  my $srch_bgcolorz    = $query->param('s0910z');
  my $srch_width       = $query->param('s0911');
  my $srch_align       = $query->param('s0912');
  my $top_image_url    = $query->param('s0913');
  my $top_image_height = $query->param('s0914');
  my $top_image_width  = $query->param('s0915');
  my $top_image_align  = $query->param('s0916');
  my $top_bar_html     = $query->param('s0917');
  my $top_bar_title    = $query->param('s0918');
  my $left_bar_exists  = $query->param('s0919');
  my $left_bar_width   = $query->param('s0920');
  my $left_bar_html    = $query->param('s0921');
  my $bot_bar_exists   = $query->param('s0922');
  my $bot_image_url    = $query->param('s0923');
  my $bot_image_height = $query->param('s0924');
  my $bot_image_width  = $query->param('s0925');
  my $bot_image_align  = $query->param('s0926');
  my $bot_bar_html     = $query->param('s0927');
  my $screen_html_file = $PAGE_DIR.'bscedit.html';
  my $screen_html;
  my $checked = "CHECKED";
  my $selected = "SELECTED";
  my %user_tmpl_dbfile;
  my %top_bar_html_db;
  my %bot_bar_html_db;
  my %left_bar_html_db;
  my $db_key;

  use Fcntl;

  if ($function eq "save") {
    eval {
      tie %user_tmpl_dbfile, "DB_File", $USER_TEMPLATE_DATA_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_TEMPLATE_DATA_DB_FILE: $!";
      tie %top_bar_html_db, "DB_File", $TOP_BAR_HTML, O_RDONLY, 0755 or die "Cannot open $TOP_BAR_HTML: $!";
      tie %bot_bar_html_db, "DB_File", $BOT_BAR_HTML, O_RDONLY, 0755 or die "Cannot open $BOT_BAR_HTML: $!";
      tie %left_bar_html_db, "DB_File", $LEFT_BAR_HTML, O_RDONLY, 0755 or die "Cannot open $LEFT_BAR_HTML: $!";

      $db_key = $user_id . "temp" . $session_id;

      ($title, $page_align, $browser_bgcolor, $page_bgcolor, $text_color, $link_color, $vlink_color, $alink_color, $page_width, $srch_bgcolor, $srch_width, $srch_align, $top_image_url, $top_image_height, $top_image_width, $top_image_align, $top_bar_title, $left_bar_exists, $left_bar_width, $bot_bar_exists, $bot_image_url, $bot_image_height, $bot_image_width, $bot_image_align) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_tmpl_dbfile{$db_key});
      if ($top_bar_html_db{$db_key}) {
        $top_bar_html  = $top_bar_html_db{$db_key};
      }
      if ($bot_bar_html_db{$db_key}) {
        $bot_bar_html  = $bot_bar_html_db{$db_key};
      }
      if ($left_bar_html_db{$db_key}) {
        $left_bar_html = $left_bar_html_db{$db_key};
      }
      untie %user_tmpl_dbfile;
      untie %top_bar_html_db;
      untie %bot_bar_html_db;
      untie %left_bar_html_db;
    };
    if ($@){
      log_error("e_bscedit0", $@);
      return (99, $internal_error);
    }

  }

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);
  };
  if ($@){
    log_error("e_bscedit1", $@);
    return (99, $internal_error);
  }

  $error_msg = "Error:".$error_id." ".$error_msg;
  if ($error_id == 0929) {
    $screen_html =~ s/:::grepin-0929:::/$error_msg/g; # give the error message in 0929
  } elsif ($error_id == 0930) {
    $screen_html =~ s/:::grepin-0930:::/$error_msg/g; # give the error message in 0930
  } elsif ($error_id == 0931) {
    $screen_html =~ s/:::grepin-0931:::/$error_msg/g; # give the error message in 0931
  } else {
    $screen_html =~ s/:::grepin-0928:::/$error_msg/g; # give the error message in 0928
  }

  $screen_html =~ s/:::grepin-0900:::/$tmpl_id/g;
  $screen_html =~ s/:::grepin-0901:::/$tmpl_title/g;

  if ($page_align eq "Center") {
    $screen_html =~ s/:::grepin-0902a:::/$selected/g;
  } elsif ($page_align eq "Right") {
    $screen_html =~ s/:::grepin-0902b:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0902:::/$selected/g;
  }

  if ($browser_bgcolor eq "00ffff") {
    $screen_html =~ s/:::grepin-0903a:::/$selected/g;
  } elsif ($browser_bgcolor eq "000000") {
    $screen_html =~ s/:::grepin-0903b:::/$selected/g;
  } elsif ($browser_bgcolor eq "0000ff") {
    $screen_html =~ s/:::grepin-0903c:::/$selected/g;
  } elsif ($browser_bgcolor eq "ff00ff") {
    $screen_html =~ s/:::grepin-0903d:::/$selected/g;
  } elsif ($browser_bgcolor eq "808080") {
    $screen_html =~ s/:::grepin-0903e:::/$selected/g;
  } elsif ($browser_bgcolor eq "008000") {
    $screen_html =~ s/:::grepin-0903f:::/$selected/g;
  } elsif ($browser_bgcolor eq "00ff00") {
    $screen_html =~ s/:::grepin-0903g:::/$selected/g;
  } elsif ($browser_bgcolor eq "800000") {
    $screen_html =~ s/:::grepin-0903h:::/$selected/g;
  } elsif ($browser_bgcolor eq "000080") {
    $screen_html =~ s/:::grepin-0903i:::/$selected/g;
  } elsif ($browser_bgcolor eq "808000") {
    $screen_html =~ s/:::grepin-0903j:::/$selected/g;
  } elsif ($browser_bgcolor eq "xxxxxx") {
    $screen_html =~ s/:::grepin-0903k:::/$selected/g;
  } elsif ($browser_bgcolor eq "ff0000") {
    $screen_html =~ s/:::grepin-0903l:::/$selected/g;
  } elsif ($browser_bgcolor eq "c0c0c0") {
    $screen_html =~ s/:::grepin-0903m:::/$selected/g;
  } elsif ($browser_bgcolor eq "008080") {
    $screen_html =~ s/:::grepin-0903n:::/$selected/g;
  } elsif ($browser_bgcolor eq "ffff00") {
    $screen_html =~ s/:::grepin-0903p:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0903:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-0903z:::/$browser_bgcolorz/g;

  if ($page_bgcolor eq "00ffff") {
    $screen_html =~ s/:::grepin-0904a:::/$selected/g;
  } elsif ($page_bgcolor eq "000000") {
    $screen_html =~ s/:::grepin-0904b:::/$selected/g;
  } elsif ($page_bgcolor eq "0000ff") {
    $screen_html =~ s/:::grepin-0904c:::/$selected/g;
  } elsif ($page_bgcolor eq "ff00ff") {
    $screen_html =~ s/:::grepin-0904d:::/$selected/g;
  } elsif ($page_bgcolor eq "808080") {
    $screen_html =~ s/:::grepin-0904e:::/$selected/g;
  } elsif ($page_bgcolor eq "008000") {
    $screen_html =~ s/:::grepin-0904f:::/$selected/g;
  } elsif ($page_bgcolor eq "00ff00") {
    $screen_html =~ s/:::grepin-0904g:::/$selected/g;
  } elsif ($page_bgcolor eq "800000") {
    $screen_html =~ s/:::grepin-0904h:::/$selected/g;
  } elsif ($page_bgcolor eq "000080") {
    $screen_html =~ s/:::grepin-0904i:::/$selected/g;
  } elsif ($page_bgcolor eq "808000") {
    $screen_html =~ s/:::grepin-0904j:::/$selected/g;
  } elsif ($page_bgcolor eq "xxxxxx") {
    $screen_html =~ s/:::grepin-0904k:::/$selected/g;
  } elsif ($page_bgcolor eq "ff0000") {
    $screen_html =~ s/:::grepin-0904l:::/$selected/g;
  } elsif ($page_bgcolor eq "c0c0c0") {
    $screen_html =~ s/:::grepin-0904m:::/$selected/g;
  } elsif ($page_bgcolor eq "008080") {
    $screen_html =~ s/:::grepin-0904n:::/$selected/g;
  } elsif ($page_bgcolor eq "ffff00") {
    $screen_html =~ s/:::grepin-0904p:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0904:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-0904z:::/$page_bgcolorz/g;

  if ($text_color eq "00ffff") {
    $screen_html =~ s/:::grepin-0905a:::/$selected/g;
  } elsif ($text_color eq "0000ff") {
    $screen_html =~ s/:::grepin-0905c:::/$selected/g;
  } elsif ($text_color eq "ff00ff") {
    $screen_html =~ s/:::grepin-0905d:::/$selected/g;
  } elsif ($text_color eq "808080") {
    $screen_html =~ s/:::grepin-0905e:::/$selected/g;
  } elsif ($text_color eq "008000") {
    $screen_html =~ s/:::grepin-0905f:::/$selected/g;
  } elsif ($text_color eq "00ff00") {
    $screen_html =~ s/:::grepin-0905g:::/$selected/g;
  } elsif ($text_color eq "800000") {
    $screen_html =~ s/:::grepin-0905h:::/$selected/g;
  } elsif ($text_color eq "000080") {
    $screen_html =~ s/:::grepin-0905i:::/$selected/g;
  } elsif ($text_color eq "808000") {
    $screen_html =~ s/:::grepin-0905j:::/$selected/g;
  } elsif ($text_color eq "xxxxxx") {
    $screen_html =~ s/:::grepin-0905k:::/$selected/g;
  } elsif ($text_color eq "ff0000") {
    $screen_html =~ s/:::grepin-0905l:::/$selected/g;
  } elsif ($text_color eq "c0c0c0") {
    $screen_html =~ s/:::grepin-0905m:::/$selected/g;
  } elsif ($text_color eq "008080") {
    $screen_html =~ s/:::grepin-0905n:::/$selected/g;
  } elsif ($text_color eq "ffffff") {
    $screen_html =~ s/:::grepin-0905o:::/$selected/g;
  } elsif ($text_color eq "ffff00") {
    $screen_html =~ s/:::grepin-0905p:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0905:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-0905z:::/$text_colorz/g;


  if ($link_color eq "00ffff") {
    $screen_html =~ s/:::grepin-0906a:::/$selected/g;
  } elsif ($link_color eq "000000") {
    $screen_html =~ s/:::grepin-0906b:::/$selected/g;
  } elsif ($link_color eq "ff00ff") {
    $screen_html =~ s/:::grepin-0906d:::/$selected/g;
  } elsif ($link_color eq "808080") {
    $screen_html =~ s/:::grepin-0906e:::/$selected/g;
  } elsif ($link_color eq "008000") {
    $screen_html =~ s/:::grepin-0906f:::/$selected/g;
  } elsif ($link_color eq "00ff00") {
    $screen_html =~ s/:::grepin-0906g:::/$selected/g;
  } elsif ($link_color eq "800000") {
    $screen_html =~ s/:::grepin-0906h:::/$selected/g;
  } elsif ($link_color eq "000080") {
    $screen_html =~ s/:::grepin-0906i:::/$selected/g;
  } elsif ($link_color eq "808000") {
    $screen_html =~ s/:::grepin-0906j:::/$selected/g;
  } elsif ($link_color eq "xxxxxx") {
    $screen_html =~ s/:::grepin-0906k:::/$selected/g;
  } elsif ($link_color eq "ff0000") {
    $screen_html =~ s/:::grepin-0906l:::/$selected/g;
  } elsif ($link_color eq "c0c0c0") {
    $screen_html =~ s/:::grepin-0906m:::/$selected/g;
  } elsif ($link_color eq "008080") {
    $screen_html =~ s/:::grepin-0906n:::/$selected/g;
  } elsif ($link_color eq "ffffff") {
    $screen_html =~ s/:::grepin-0906o:::/$selected/g;
  } elsif ($link_color eq "ffff00") {
    $screen_html =~ s/:::grepin-0906p:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0906:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-0906z:::/$link_colorz/g;

  if ($vlink_color eq "00ffff") {
    $screen_html =~ s/:::grepin-0907a:::/$selected/g;
  } elsif ($vlink_color eq "000000") {
    $screen_html =~ s/:::grepin-0907b:::/$selected/g;
  } elsif ($vlink_color eq "0000ff") {
    $screen_html =~ s/:::grepin-0907c:::/$selected/g;
  } elsif ($vlink_color eq "ff00ff") {
    $screen_html =~ s/:::grepin-0907d:::/$selected/g;
  } elsif ($vlink_color eq "808080") {
    $screen_html =~ s/:::grepin-0907e:::/$selected/g;
  } elsif ($vlink_color eq "008000") {
    $screen_html =~ s/:::grepin-0907f:::/$selected/g;
  } elsif ($vlink_color eq "00ff00") {
    $screen_html =~ s/:::grepin-0907g:::/$selected/g;
  } elsif ($vlink_color eq "800000") {
    $screen_html =~ s/:::grepin-0907h:::/$selected/g;
  } elsif ($vlink_color eq "000080") {
    $screen_html =~ s/:::grepin-0907i:::/$selected/g;
  } elsif ($vlink_color eq "808000") {
    $screen_html =~ s/:::grepin-0907j:::/$selected/g;
  } elsif ($vlink_color eq "ff0000") {
    $screen_html =~ s/:::grepin-0907l:::/$selected/g;
  } elsif ($vlink_color eq "c0c0c0") {
    $screen_html =~ s/:::grepin-0907m:::/$selected/g;
  } elsif ($vlink_color eq "008080") {
    $screen_html =~ s/:::grepin-0907n:::/$selected/g;
  } elsif ($vlink_color eq "ffffff") {
    $screen_html =~ s/:::grepin-0907o:::/$selected/g;
  } elsif ($vlink_color eq "ffff00") {
    $screen_html =~ s/:::grepin-0907p:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0907:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-0907z:::/$vlink_colorz/g;

  if ($alink_color eq "00ffff") {
    $screen_html =~ s/:::grepin-0908a:::/$selected/g;
  } elsif ($alink_color eq "000000") {
    $screen_html =~ s/:::grepin-0908b:::/$selected/g;
  } elsif ($alink_color eq "0000ff") {
    $screen_html =~ s/:::grepin-0908c:::/$selected/g;
  } elsif ($alink_color eq "ff00ff") {
    $screen_html =~ s/:::grepin-0908d:::/$selected/g;
  } elsif ($alink_color eq "808080") {
    $screen_html =~ s/:::grepin-0908e:::/$selected/g;
  } elsif ($alink_color eq "008000") {
    $screen_html =~ s/:::grepin-0908f:::/$selected/g;
  } elsif ($alink_color eq "00ff00") {
    $screen_html =~ s/:::grepin-0908g:::/$selected/g;
  } elsif ($alink_color eq "800000") {
    $screen_html =~ s/:::grepin-0908h:::/$selected/g;
  } elsif ($alink_color eq "000080") {
    $screen_html =~ s/:::grepin-0908i:::/$selected/g;
  } elsif ($alink_color eq "808000") {
    $screen_html =~ s/:::grepin-0908j:::/$selected/g;
  } elsif ($alink_color eq "xxxxxx") {
    $screen_html =~ s/:::grepin-0908k:::/$selected/g;
  } elsif ($alink_color eq "c0c0c0") {
    $screen_html =~ s/:::grepin-0908m:::/$selected/g;
  } elsif ($alink_color eq "008080") {
    $screen_html =~ s/:::grepin-0908n:::/$selected/g;
  } elsif ($alink_color eq "ffffff") {
    $screen_html =~ s/:::grepin-0908o:::/$selected/g;
  } elsif ($alink_color eq "ffff00") {
    $screen_html =~ s/:::grepin-0908p:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0908:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-0908z:::/$alink_colorz/g;

  $screen_html =~ s/:::grepin-0909:::/$page_width/g;

  if ($srch_bgcolor eq "00ffff") {
    $screen_html =~ s/:::grepin-0910a:::/$selected/g;
  } elsif ($srch_bgcolor eq "000000") {
    $screen_html =~ s/:::grepin-0910b:::/$selected/g;
  } elsif ($srch_bgcolor eq "0000ff") {
    $screen_html =~ s/:::grepin-0910c:::/$selected/g;
  } elsif ($srch_bgcolor eq "ff00ff") {
    $screen_html =~ s/:::grepin-0910d:::/$selected/g;
  } elsif ($srch_bgcolor eq "808080") {
    $screen_html =~ s/:::grepin-0910e:::/$selected/g;
  } elsif ($srch_bgcolor eq "008000") {
    $screen_html =~ s/:::grepin-0910f:::/$selected/g;
  } elsif ($srch_bgcolor eq "00ff00") {
    $screen_html =~ s/:::grepin-0910g:::/$selected/g;
  } elsif ($srch_bgcolor eq "800000") {
    $screen_html =~ s/:::grepin-0910h:::/$selected/g;
  } elsif ($srch_bgcolor eq "000080") {
    $screen_html =~ s/:::grepin-0910i:::/$selected/g;
  } elsif ($srch_bgcolor eq "808000") {
    $screen_html =~ s/:::grepin-0910j:::/$selected/g;
  } elsif ($srch_bgcolor eq "xxxxxx") {
    $screen_html =~ s/:::grepin-0910k:::/$selected/g;
  } elsif ($srch_bgcolor eq "ff0000") {
    $screen_html =~ s/:::grepin-0910l:::/$selected/g;
  } elsif ($srch_bgcolor eq "c0c0c0") {
    $screen_html =~ s/:::grepin-0910m:::/$selected/g;
  } elsif ($srch_bgcolor eq "008080") {
    $screen_html =~ s/:::grepin-0910n:::/$selected/g;
  } elsif ($srch_bgcolor eq "ffff00") {
    $screen_html =~ s/:::grepin-0910p:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0910:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-0910z:::/$srch_bgcolorz/g;

  $screen_html =~ s/:::grepin-0911:::/$srch_width/g;

  if ($srch_align eq "Center") {
    $screen_html =~ s/:::grepin-0912a:::/$selected/g;
  } elsif ($srch_align eq "Right") {
    $screen_html =~ s/:::grepin-0912b:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0912:::/$selected/g;
  }

  $screen_html =~ s/:::grepin-0913:::/$top_image_url/g;
  $screen_html =~ s/:::grepin-0914:::/$top_image_height/g;
  $screen_html =~ s/:::grepin-0915:::/$top_image_width/g;

  if ($top_image_align eq "Center") {
    $screen_html =~ s/:::grepin-0916a:::/$selected/g;
  } elsif ($top_image_align eq "Right") {
    $screen_html =~ s/:::grepin-0916b:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0916:::/$selected/g;
  }

  $screen_html =~ s/:::grepin-0917:::/$top_bar_html/g;
  $screen_html =~ s/:::grepin-0918:::/$top_bar_title/g;

  if ($left_bar_exists eq "Yes") {
    $screen_html =~ s/:::grepin-0919a:::/$checked/g;
  } else {
    $screen_html =~ s/:::grepin-0919:::/$checked/g;
  }

  $screen_html =~ s/:::grepin-0920:::/$left_bar_width/g;
  $screen_html =~ s/:::grepin-0921:::/$left_bar_html/g;

  if ($bot_bar_exists eq "Yes") {
    $screen_html =~ s/:::grepin-0922a:::/$checked/g;
  } else {
    $screen_html =~ s/:::grepin-0922:::/$checked/g;
  }

  $screen_html =~ s/:::grepin-0923:::/$bot_image_url/g;
  $screen_html =~ s/:::grepin-0924:::/$bot_image_height/g;
  $screen_html =~ s/:::grepin-0925:::/$bot_image_width/g;

  if ($bot_image_align eq "Center") {
    $screen_html =~ s/:::grepin-0926a:::/$selected/g;
  } elsif ($bot_image_align eq "Right") {
    $screen_html =~ s/:::grepin-0926b:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-0926:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-0927:::/$bot_bar_html/g;

  return (0, $screen_html);

}




sub p_bsceditprv {
# preview the search results page - basic edit
# return codes
# 90 - success and the page is printed on the screen
#  1 - error in general settings
#  2 - error in top bar settings
#  3 - error in left bar settings
#  4 - error in bot bar settings
# 99 - database error

  my $user_id          = $query->param('uid');
  my $session_id       = $query->param('sid');
  my $tmpl_id          = $query->param('id');
  my $tmpl_title       = $query->param('s0901');
  my $page_align       = $query->param('s0902');
  my $browser_bgcolor  = $query->param('s0903');
  my $page_bgcolor     = $query->param('s0904');
  my $text_color       = $query->param('s0905');
  my $link_color       = $query->param('s0906');
  my $vlink_color      = $query->param('s0907');
  my $alink_color      = $query->param('s0908');
  my $page_width       = $query->param('s0909');
  my $srch_bgcolor     = $query->param('s0910');
  my $srch_width       = $query->param('s0911');
  my $srch_align       = $query->param('s0912');
  my $top_image_url    = $query->param('s0913');
  my $top_image_height = $query->param('s0914');
  my $top_image_width  = $query->param('s0915');
  my $top_image_align  = $query->param('s0916');
  my $top_bar_html     = $query->param('s0917');
  my $top_bar_title    = $query->param('s0918');
  my $left_bar_exists  = $query->param('s0919');
  my $left_bar_width   = $query->param('s0920');
  my $left_bar_html    = $query->param('s0921');
  my $bot_bar_exists   = $query->param('s0922');
  my $bot_image_url    = $query->param('s0923');
  my $bot_image_height = $query->param('s0924');
  my $bot_image_width  = $query->param('s0925');
  my $bot_image_align  = $query->param('s0926');
  my $bot_bar_html     = $query->param('s0927');
  my %user_tmpl_data;
  my %top_bar_html;
  my %bot_bar_html;
  my %left_bar_html;
  my %user_prof;
  my $web_addr;
  my $db_key;

  my $srch_rslts_tmpl_content;
  my $srch_rslts_page = $SRCH_USER_DIR.'templates/resultspage.html';
  my $preview_page    = $PAGE_DIR.'bscprv.html';
  my $srch_rslts_temp = $TMPL_DIR.'srchrsltstemp.html';
  my $preview_page_content;
  my $srch_rslts_content;

  use Fcntl;

  # change to upper case
  $tmpl_title         =~ tr/a-z/A-Z/;

  # change to lower case
  $top_image_url      =~ tr/A-Z/a-z/;
  $bot_image_url      =~ tr/A-Z/a-z/;

  # replace any white space to a single space
  $tmpl_title      =~ s/\s+/ /g;
  $browser_bgcolor =~ s/\s+/ /g;
  $page_bgcolor    =~ s/\s+/ /g;
  $text_color      =~ s/\s+/ /g;
  $link_color      =~ s/\s+/ /g;
  $vlink_color     =~ s/\s+/ /g;
  $alink_color     =~ s/\s+/ /g;
  $srch_bgcolor    =~ s/\s+/ /g;
  $top_image_url   =~ s/\s+/ /g;
  $top_bar_title   =~ s/\s+/ /g;
  $bot_image_url   =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $tmpl_title      =~ s/(^\s+)|(\s+$)//;
  $browser_bgcolor =~ s/(^\s+)|(\s+$)//;
  $page_bgcolor    =~ s/(^\s+)|(\s+$)//;
  $text_color      =~ s/(^\s+)|(\s+$)//;
  $link_color      =~ s/(^\s+)|(\s+$)//;
  $vlink_color     =~ s/(^\s+)|(\s+$)//;
  $alink_color     =~ s/(^\s+)|(\s+$)//;
  $srch_bgcolor    =~ s/(^\s+)|(\s+$)//;
  $top_image_url   =~ s/(^\s+)|(\s+$)//;
  $top_bar_title   =~ s/(^\s+)|(\s+$)//;
  $bot_image_url   =~ s/(^\s+)|(\s+$)//;


  # template title
  if (!$tmpl_title) {
    return(1, "Template Title cannot be empty.");
  }

  if ($tmpl_title !~ /[\dA-Z_]/) {
    return(1, "Template Title has invalid characters. A to Z, numbers and '_' are only allowed.");
  }

  # page align
  if (($page_align ne "Left") && ($page_align ne "Center") && ($page_align ne "Right")) {
    return (1, "Alignment of the Page should be Left, Center, or Right.");
  }

  # background color of the browser
  if (($query->param('s0903z') && ($query->param('s0903z') =~ /[\dA-Fa-f]{6}/)) {
    $browser_bgcolor = $query->param('s0903z');
  } else {
    return (1, "Browser Background Color should be a HEX code of 6 characters");
  }

  # background color of the page
  if (($query->param('s0904z') && ($query->param('s0904z') =~ /[\dA-Fa-f]{6}/)) {
    $page_bgcolor = $query->param('s0904z');
  } else {
    return (1, "Your Results Page Background Color should be a HEX code of 6 characters");
  }

  # text color
  if (($query->param('s0905z') && ($query->param('s0905z') =~ /[\dA-Fa-f]{6}/)) {
    $text_color = $query->param('s0905z');
  } else {
    return (1, "Text Color should be a HEX code of 6 characters");
  }

  # links color
  if (($query->param('s0906z') && ($query->param('s0906z') =~ /[\dA-Fa-f]{6}/)) {
    $link_color = $query->param('s0906z');
  } else {
    return (1, "Links Color should be a HEX code of 6 characters");
  }

  # vlink color
  if (($query->param('s0907z') && ($query->param('s0907z') =~ /[\dA-Fa-f]{6}/)) {
    $vlink_color = $query->param('s0907z');
  } else {
    return (1, "Visited Link Color should be a HEX code of 6 characters");
  }

  # alink color
  if (($query->param('s0908z') && ($query->param('s0908z') =~ /[\dA-Fa-f]{6}/)) {
    $alink_color = $query->param('s0908z');
  } else {
    return (1, "Active Link Color should be a HEX code of 6 characters");
  }

  # width of the page
  if (!$page_width) {
    $page_width = 80;
  } else {
    if ($page_width !~ /\d+/) {
      return (1, "Width of the Page shoud be a numeric value");
    }
    if (($page_width > 100) || ($page_width < 50)) {
      return (1, "Width of the Page should be between 50 and 100%.");
    }
  }

  # background color of search results area
  if (($query->param('s0910z') && ($query->param('s0910z') =~ /[\dA-Fa-f]{6}/)) {
    $srch_bgcolor = $query->param('s0910z')
  } else {
    return (1, "Color of Search Results Area should be a HEX code of 6 characters.");
  }

  # width of the search results area
  if (!$srch_width) {
    $srch_width = 100;
  } else {
    if ($srch_width !~ /\d+/) {
      return (1, "Width of the Search Results Area shoud be a numeric value");
    }
    if (($srch_width > 100) || ($srch_width < 50)) {
      return (1, "Width of the Search Results Area should be between 50 and 100%.");
    }
  }

  # search results area align
  if (($srch_align ne "Left") && ($srch_align ne "Center") && ($srch_align ne "Right")) {
    return (1, "Alignment of the Search Results Area should be Left, Center, or Right.");
  }

  # top bar
  if ($top_bar_html =~ /^\s+$/) {
    $top_bar_html = undef;
  }
  if ($top_bar_html) {
    if ($top_bar_html =~ /<html>|<body>|<\/html>|<\/body>/) {
      return (2, "HTML or BODY tags are not allowed in Top Bar Html. Please change the HTML and try again.")
    } else {
      $top_image_url    = undef;
      $top_image_height = undef;
      $top_image_width  = undef;
    }
  }

  if ($top_image_url) {
    if (($top_image_url !~ m%^http://.*%) && ($top_image_url !~ m%^https://.*%)) {
      return (2, "Invalid Top Bar Image URL - should start in http:// or https://.");
    }
    if (!$top_image_height) {
      $top_image_height = 100;
    } else {
      if ($top_image_height !~ /\d+/) {
        return (2, "Top Bar Image Height should be a numeric value.");
      }
    }
    if (!$top_image_width) {
      $top_image_width  = 700;
    } else {
      if ($top_image_width !~ /\d+/) {
        return (2, "Top Bar Image Width should be a numeric value.");
      }
    }
  }

  if ((!$top_bar_html) && (!$top_image_url) && (!$top_bar_title)) {
    return (2, "Top Bar HTML or Top Bar Image or Title should be specified.");
  }

  # left nav bar
  if ($left_bar_html =~ /^\s+$/) {
    $left_bar_html = undef;
  }
  if ($left_bar_exists eq "Yes") {
    if (($left_bar_html) && ($left_bar_html =~ /<html>|<body>|<\/html>|<\/body>/)) {
      return (3, "HTML or BODY tags are not allowed in Left Bar Html. Please change the HTML and try again.")
    }
    if (!$left_bar_width) {
      $left_bar_width = 0;
    } else {
      if ($left_bar_width !~ /\d+/) {
        return (3, "Width of Left Navigation Bar should be a numeric value.");
      }
      if ($left_bar_width > 180) {
        return (3, "Width of Left Navigation Bar should not exceed 180.");
      }
    }
  } else {
    $left_bar_exists = "No";
    $left_bar_width  = undef;
    $left_bar_html   = undef;
  }

  # bottom bar
  if ($bot_bar_html =~ /^\s+$/) {
    $bot_bar_html = undef;
  }
  if ($bot_bar_exists eq "Yes") {
    if ($bot_bar_html) {
      if ($bot_bar_html =~ /<html>|<body>|<\/html>|<\/body>/) {
        return (4, "HTML or BODY tags are not allowed in Bottom Bar Html. Please change the HTML and try again.")
      } else {
        $bot_image_url    = undef;
        $bot_image_height = undef;
        $bot_image_width  = undef;
      }
    }

    if ($bot_image_url) {
      if (($bot_image_url !~ m%^http://.*%) && ($bot_image_url !~ m%^https://.*%)) {
        return (4, "Invalid Bottom Bar Image URL - should start in http:// or https://.");
      }
      if (!$bot_image_height) {
        $bot_image_height = 100;
      } else {
        if ($bot_image_height !~ /\d+/) {
          return (4, "Bottom Bar Image Height should be a numeric value.");
        }
      }
      if (!$bot_image_width) {
        $bot_image_width  = 700;
      } else {
        if ($bot_image_width !~ /\d+/) {
          return (4, "Bottom Bar Image Width should be a numeric value.");
        }
      }
    }
  } else {
    $bot_bar_exists   = "No";
    $bot_image_url    = undef;
    $bot_image_height = undef;
    $bot_image_width  = undef;
    $bot_bar_html     = undef;
  }

  # bottom bar image align
  if (($bot_image_align ne "Left") && ($bot_image_align ne "Center") && ($bot_image_align ne "Right")) {
    return (4, "Alignment of the Bottom Bar Image should be Left, Center, or Right.");
  }


  # read profile database
  $db_key = $user_id;
  eval {
    tie %user_prof, "DB_File", $USER_PROFILE_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";
  };
  if ($@){
    log_error("p_bscaddprv0", $@);
    return (99, $internal_error);
  }

  ($d1, $web_addr, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_prof{$db_key});


  # create the user search results page
  #
  # read from the template page
  eval {
    open (TEMPLPAGE, $COMN_RESULTS_TEMPLATE) or die "Cannot open COMN_RESULTS_TEMPLATE '$COMN_RESULTS_TEMPLATE' for reading: $!";
    while (<TEMPLPAGE>) {
      $srch_rslts_tmpl_content .= $_;
    }
    close(TEMPLPAGE);
  };
  if ($@){
    log_error("p_bscaddprv1", $@);
    return (99, $internal_error);
  }

  # substitute the variables with the actual data
  $srch_rslts_tmpl_content =~ s/:::grepin-1100:::/$tmpl_id/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-page-align:::/$page_align/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-browser-bgcolor:::/$browser_bgcolor/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-page-bgcolor:::/$page_bgcolor/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-text-color:::/$text_color/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-link-color:::/$link_color/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-vlink-color:::/$vlink_color/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-alink-color:::/$alink_color/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-page-width:::/$page_width/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-srch-bgcolor:::/$srch_bgcolor/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-srch-width:::/$srch_width/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-srch-align:::/$srch_align/g;

  if ($top_bar_html) {
    $srch_rslts_tmpl_content =~ s/:::grepin-start-top-bar:::.*:::grepin-end-top-bar:::/$top_bar_html/s;
    $srch_rslts_tmpl_content =~ s/:::grepin-start-top-title:::.*:::grepin-end-top-title::://g;
  } else {
    $srch_rslts_tmpl_content =~ s/:::grepin-top-image-align:::/$top_image_align/g;
    if ($top_image_url) {
      $srch_rslts_tmpl_content =~ s/:::grepin-start-top-bar:::|:::grepin-end-top-bar::://g;
      $srch_rslts_tmpl_content =~ s/:::grepin-top-image-url:::/$top_image_url/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-top-image-height:::/$top_image_height/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-top-image-width:::/$top_image_width/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-start-top-title:::.*:::grepin-end-top-title::://g;
    } else {
      $srch_rslts_tmpl_content =~ s/:::grepin-start-top-bar:::.*:::grepin-end-top-bar::://g;
      $srch_rslts_tmpl_content =~ s/:::grepin-start-top-title:::|:::grepin-end-top-title::://g;
      $srch_rslts_tmpl_content =~ s/:::grepin-top-title:::/$top_bar_title/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-home-link:::/$web_addr/g;
    }
  }

  $srch_rslts_tmpl_content =~ s/:::grepin-left-bar-width:::/$left_bar_width/g;
  if ($left_bar_html) {
    $srch_rslts_tmpl_content =~ s/:::grepin-left-bar-html:::/$left_bar_html/g;
  } else {
    $srch_rslts_tmpl_content =~ s/:::grepin-left-bar-html::://g;
  }

  if ($bot_bar_exists eq "Yes") {
    if ($bot_bar_html) {
      $srch_rslts_tmpl_content =~ s/:::grepin-start-bot-bar:::.*:::grepin-end-bot-bar:::/$bot_bar_html/s;
    } else {
      $srch_rslts_tmpl_content =~ s/:::grepin-start-bot-bar:::|:::grepin-end-bot-bar::://g;
      $srch_rslts_tmpl_content =~ s/:::grepin-bot-image-url:::/$bot_image_url/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-bot-image-height:::/$bot_image_height/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-bot-image-width:::/$bot_image_width/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-bot-image-align:::/$bot_image_align/g;
    }
  } else {
    $srch_rslts_tmpl_content =~ s/:::grepin-start-bot-bar:::.*:::grepin-end-bot-bar::://s;
  }

  # create the preview page
  #
  eval {
    open (PRVWPAGE, $preview_page) or die "Cannot open previewpage '$preview_page' for reading: $!";
    while (<PRVWPAGE>) {
      $preview_page_content .= $_;
    }
    close(PRVWPAGE);

    open (RSLTTEMP, $srch_rslts_temp) or die "Cannot open srchrsltstemp '$srch_rslts_temp' for reading: $!";
    while (<RSLTTEMP>) {
      $srch_rslts_content .= $_;
    }
    close(RSLTTEMP);
  };
  if ($@){
    log_error("p_bscaddprv2", $@);
    return (99, $internal_error);
  }

  # update user_tmpl_data, top_bar_html, bot_bar_html, left_bar_html
  eval {
    tie %user_tmpl_data, "DB_File", $USER_TEMPLATE_DATA_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_TEMPLATE_DATA_DB_FILE: $!";
    tie %top_bar_html_db, "DB_File", $TOP_BAR_HTML, O_CREAT|O_RDWR, 0755 or die "Cannot open $TOP_BAR_HTML: $!";
    tie %bot_bar_html_db, "DB_File", $BOT_BAR_HTML, O_CREAT|O_RDWR, 0755 or die "Cannot open $BOT_BAR_HTML: $!";
    tie %left_bar_html_db, "DB_File", $LEFT_BAR_HTML, O_CREAT|O_RDWR, 0755 or die "Cannot open $LEFT_BAR_HTML: $!";

    $db_key = $user_id . "temp" . $session_id;

    $user_tmpl_data{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $tmpl_title, $page_align, $browser_bgcolor, $page_bgcolor, $text_color, $link_color, $vlink_color, $alink_color, $page_width, $srch_bgcolor, $srch_width, $srch_align, $top_image_url, $top_image_height, $top_image_width, $top_image_align, $top_bar_title, $left_bar_exists, $left_bar_width, $bot_bar_exists, $bot_image_url, $bot_image_height, $bot_image_width, $bot_image_align);
    if ($top_bar_html) {
      $tob_bar_html_db{$db_key};
    }
    if ($bot_bar_html) {
      $bot_bar_html_db{$db_key};
    }
    if ($left_bar_html) {
      $left_bar_html_db{$db_key};
    }
    untie %user_tmpl_data;
    untie %tob_bar_html_db;
    untie %bot_bar_html_db;
    untie %left_bar_html_db;
  };
  if ($@){
    log_error("p_bscaddprv3", $@);
    return (99, $internal_error);
  }

  $preview_page_content =~ s/:::grepin-fld00:::/$user_id/g;
  $preview_page_content =~ s/:::grepin-fld01:::/$session_id/g;

  $preview_page_content .= $srch_rslts_tmpl_content;

  $preview_page_content =~ s/:::grepin-.*::://g;         # space out all the other fields

  $preview_page_content =~ s/:::search-results:::/$srch_rslts_content/g;

  print $preview_page_content;

  return (90, "success");

}



######################################################################################


sub d_advedit {

  my $user_id          = $query->param('uid');
  my $session_id       = $query->param('sid');
  my $tmpl_id          = $query->param('id');
  my $tmpl_title;
  my $db_key;
  my $results_form_html_file = $SRCH_USER_DIR.'templates/'$user_id.$tmpl_id.'.html';
  my $screen_html_file = $PAGE_DIR.'advedit.html';
  my $screen_html;
  my $results_form_html;
  my %user_tmpl_dbfile;

  use Fcntl;

  eval {
    tie %user_tmpl_dbfile, "DB_File", $USER_TEMPLATE_DATA_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_TEMPLATE_DATA_DB_FILE: $!";
    $db_key = $user_id . $tmpl_id;
    ($tmpl_title, $d1) = unpack("C/A* C/A*", $user_tmpl_dbfile{$db_key});
    untie %user_tmpl_dbfile;
  };
  if ($@){
    log_error("d_advedit0", $@);
    return (99, $internal_error);
  }


  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    if (-e $results_form_html_file) {
      open (RESULTSFILE, $results_form_html_file) or die "Cannot open resultsformhtmlfile '$results_form_html_file' for reading: $!";

      while (<RESULTSFILE>) {
        $results_form_html .= $_;
      }
      close(RESULTSFILE);

      $screen_html =~ s/:::grepin-1000:::/$tmpl_id/g;
      $screen_html =~ s/:::grepin-1001:::/$tmpl_title/g;
      $screen_html =~ s/:::grepin-1002:::/$results_form_html/g;

    } else {
      return (1, "This template is not found. Please create a new template.");
    }
  };
  if ($@){
    log_error("d_advedit1", $@);
    return (99, $internal_error);
  }


  return (0, $screen_html);

}




sub e_advedit {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $user_id    = $query->param('uid');
  my $function   = $query->param('fn');
  my $tmpl_id    = $query->param('id');
  my $tmpl_title = $query->param('s1001');
  my $temp_page              = $SRCH_USER_DIR.'templates/temppage.html';
  my $results_form_html;
  my $screen_html_file       = $PAGE_DIR.'advedit.html';
  my $screen_html;

  use Fcntl;

  if ($function eq "save") {
    eval {
      if (-e $temp_page) {
        open (RSLTFILE, $temp_page) or die "Cannot open temppage '$temp_page' for reading: $!";
        while (<RSLTFILE>) {
          $results_form_html .= $_;
        }
        close(RSLTFILE);
      }
    };
    if ($@){
      log_error("e_advedit0", $@);
      return (99, $internal_error);
    }
  } else {
    $results_form_html = $query->param('s1002');
  }

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);
  };
  if ($@){
    log_error("e_advedit1", $@);
    return (99, $internal_error);
  }

  $error_msg = "Error:".$error_id." ".$error_msg;
  $screen_html =~ s/:::grepin-1000:::/$tmpl_id;
  $screen_html =~ s/:::grepin-1003:::/$error_msg/g; # give the error message
  $screen_html =~ s/:::grepin-1001:::/$tmpl_title;
  $screen_html =~ s/:::grepin-1002:::/$results_form_html/g;

  return (0, $screen_html);

}


######################################################################################



sub p_bscsave {
# save the results page template - basic add
# return codes
# 0 - success
# 99 = database error

  my $caller     = shift;
  my $user_id    = $query->param('uid');
  my $session_id = $query->param('sid');
  my $cmd        = $query->param('cmd');
  my ($tmpl_id, $tmpl_title, $page_align, $browser_bgcolor, $page_bgcolor, $text_color, $link_color, $vlink_color, $alink_color, $page_width, $srch_bgcolor, $srch_width, $srch_align, $top_image_url, $top_image_height, $top_image_width, $top_image_align, $top_bar_html, $top_bar_title, $left_bar_width, $left_bar_html, $bot_image_url, $bot_image_height, $bot_image_width, $bot_image_align, $bot_bar_html);

  my $srch_rslts_tmpl_content;
  my $srch_rslts_page;
  my %user_tmpl_data;
  my %top_bar_html_db;
  my %bot_bar_html_db;
  my %left_bar_html_db;
  my ($db_key, $db_key2, $db_key3);

  my %user_prof;
  my ($email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4);

  use Fcntl;

  # read profile database
  $db_key = $user_id;
  eval {
    tie %user_prof, "DB_File", $USER_PROFILE_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";
    ($email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_prof{$db_key});
  };
  if ($@){
    log_error("p_bscsave0", $@);
    return (99, $internal_error);
  }

  $db_key2 = $user_id . "temp" . $session_id;

  # read and update user_tmpl_data, top_bar_html, bot_bar_html, left_bar_html database
  eval {
    tie %user_tmpl_data, "DB_File", $USER_TEMPLATE_DATA_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_TEMPLATE_DATA_DB_FILE: $!";
    tie %top_bar_html_db, "DB_File", $TOP_BAR_HTML, O_CREAT|O_RDWR, 0755 or die "Cannot open $TOP_BAR_HTML: $!";
    tie %bot_bar_html_db, "DB_File", $BOT_BAR_HTML, O_CREAT|O_RDWR, 0755 or die "Cannot open $BOT_BAR_HTML: $!";
    tie %left_bar_html_db, "DB_File", $LEFT_BAR_HTML, O_CREAT|O_RDWR, 0755 or die "Cannot open $LEFT_BAR_HTML: $!";

    if (!$user_tmpl_data{$db_key2}) {
      return (1, "The template could not be saved due to an internal error. Please create the template again.");
    } else {

      if ($caller == "edit") {
        $tmpl_id = $query->param('id');
      } else {
        $tmpl_id = $user_tmpl_data{$db_key};
        $tmpl_id++;
        $user_tmpl_data{$db_key} = $tmpl_id;
      }
      $db_key3 = $user_id . $tmpl_id;

      $user_tmpl_data{$db_key3} = $user_tmpl_data{$db_key2};
      delete $user_tmpl_data{$db_key2};

      if ($top_bar_html_db{$db_key2}) {
        $top_bar_html_db{$db_key3} = $top_bar_html_db{$db_key2};
        delete $top_bar_html_db{$db_key2};
      } else {
        delete $top_bar_html_db{$db_key3};
      }

      if ($bot_bar_html_db{$db_key2}) {
        $bot_bar_html_db{$db_key3} = $bot_bar_html_db{$db_key2};
        delete $bot_bar_html_db{$db_key2};
      } else {
        delete $bot_bar_html_db{$db_key3};
      }

      if ($left_bar_html_db{$db_key2}) {
        $left_bar_html_db{$db_key3} = $left_bar_html_db{$db_key2};
        delete $left_bar_html_db{$db_key2};
      } else {
        delete $left_bar_html_db{$db_key3};
      }

    }
  };
  if ($@){
    log_error("p_bscsave1", $@);
    return (99, $internal_error);
  }

  # create the user search results page
  #
  # read from the template page
  eval {
    open (TEMPLPAGE, $COMN_RESULTS_TEMPLATE) or die "Cannot open COMN_RESULTS_TEMPLATE '$COMN_RESULTS_TEMPLATE' for reading: $!";
    while (<TEMPLPAGE>) {
      $srch_rslts_tmpl_content .= $_;
    }
    close(TEMPLPAGE);
  };
  if ($@){
    log_error("p_bscsave2", $@);
    return (99, $internal_error);
  }

  # substitute the variables with the actual data
  $srch_rslts_tmpl_content =~ s/:::grepin-page-align:::/$page_align/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-browser-bgcolor:::/$browser_bgcolor/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-page-bgcolor:::/$page_bgcolor/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-text-color:::/$text_color/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-link-color:::/$link_color/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-vlink-color:::/$vlink_color/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-alink-color:::/$alink_color/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-page-width:::/$page_width/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-srch-bgcolor:::/$srch_bgcolor/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-srch-width:::/$srch_width/g;
  $srch_rslts_tmpl_content =~ s/:::grepin-srch-align:::/$srch_align/g;

  if ($top_bar_html) {
    $srch_rslts_tmpl_content =~ s/:::grepin-start-top-bar:::.*:::grepin-end-top-bar:::/$top_bar_html/s;
    $srch_rslts_tmpl_content =~ s/:::grepin-start-top-title:::.*:::grepin-end-top-title::://g;
  } else {
    $srch_rslts_tmpl_content =~ s/:::grepin-top-image-align:::/$top_image_align/g;
    if ($top_image_url) {
      $srch_rslts_tmpl_content =~ s/:::grepin-start-top-bar:::|:::grepin-end-top-bar::://g;
      $srch_rslts_tmpl_content =~ s/:::grepin-top-image-url:::/$top_image_url/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-top-image-height:::/$top_image_height/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-top-image-width:::/$top_image_width/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-start-top-title:::.*:::grepin-end-top-title::://g;
    } else {
      $srch_rslts_tmpl_content =~ s/:::grepin-start-top-bar:::.*:::grepin-end-top-bar::://g;
      $srch_rslts_tmpl_content =~ s/:::grepin-start-top-title:::|:::grepin-end-top-title::://g;
      $srch_rslts_tmpl_content =~ s/:::grepin-top-title:::/$top_bar_title/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-home-link:::/$web_addr/g;
    }
  }
  $srch_rslts_tmpl_content =~ s/:::grepin-left-bar-width:::/$left_bar_width/g;
  if ($left_bar_html) {
    $srch_rslts_tmpl_content =~ s/:::grepin-left-bar-html:::/$left_bar_html/g;
  } else {
    $srch_rslts_tmpl_content =~ s/:::grepin-left-bar-html::://g;
  }

  if ($bot_bar_exists eq "Yes") {
    if ($bot_bar_html) {
      $srch_rslts_tmpl_content =~ s/:::grepin-start-bot-bar:::.*:::grepin-end-bot-bar:::/$bot_bar_html/s;
    } else {
      $srch_rslts_tmpl_content =~ s/:::grepin-start-bot-bar:::|:::grepin-end-bot-bar::://g;
      $srch_rslts_tmpl_content =~ s/:::grepin-bot-image-url:::/$bot_image_url/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-bot-image-height:::/$bot_image_height/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-bot-image-width:::/$bot_image_width/g;
      $srch_rslts_tmpl_content =~ s/:::grepin-bot-image-align:::/$bot_image_align/g;
    }
  } else {
    $srch_rslts_tmpl_content =~ s/:::grepin-start-bot-bar:::.*:::grepin-end-bot-bar::://s;
    $srch_rslts_tmpl_content =~ s/:::grepin-bot-image-align::://g;
  }


  # write to user search results page
  $srch_rslts_page = $SRCH_USER_DIR.'templates/'$user_id.$tmpl_id.'.html';
  use Fcntl ':flock';        # import LOCK_* constants
  eval {
    open(RSLTSPAGE, ">$srch_rslts_page") or die "Cannot open srchrsltspage '$srch_rslts_page' for writing: $!";
    flock(RSLTSPAGE, LOCK_EX);
    seek(RSLTSPAGE, 0, 2);
    print RSLTSPAGE "$srch_rslts_tmpl_content\n";
    flock(RSLTSPAGE, LOCK_UN);
    close(RSLTSPAGE);
  };
  if ($@){
    log_error("p_bscsave3", $@);
    return (99, $internal_error);
  }

  # update user_prof database
  eval {
    tie %user_prof, "DB_File", $USER_PROFILE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";

    if (($config_status ne "IS") && ($config_status ne "IQS") && ($config_status ne "S")) {
      if ($config_status eq "I") {
        $config_status = "IS"
      } else {
        if ($config_status eq "IQ") {
          $config_status = "IQS"
        } else {
          $config_status = "S"
        }
      }
      $user_prof{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4);
    }
    untie %user_prof;
  };
  if ($@){
    log_error("p_bscsave4", $@);
    return (99, $internal_error);
  }

  #
  # update the user_status_dbfile with last_search_use_date
  #   key = user_id + '-' + status_type
  #     status_type = 1 = last_indexed_date
  #     status_type = 2 = last_search_use_date
  #     status_type = 3 = member_status (F = free, S = subscription)
  #     status_type = 4 = config_status (I, IQ, S, IS, IQS)
  #
  eval {
    tie %user_status_dbfile, $db_package, $USER_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_STATUS_DB_FILE: $!";
    $db_key = $user_id.'-4';
    if ($user_status_dbfile{$db_key} ne $config_status) {
      $user_status_dbfile{$db_key} = $config_status;
    }
    untie %user_status_dbfile;
  };

  if ($@) {
    log_error ("p_bscsave5", $@);
    return (99, $internal_error);
  }

  return (0, "success");

}



sub p_advsave {
# save template - advanced way...
# return codes
#  0 - success
# 99 - database error

  my $caller          = shift;
  my $user_id         = $query->param('uid');
  my $session_id      = $query->param('sid');

  my $temp_page       = $SRCH_USER_DIR.'templates/temppage.html';
  my $srch_rslts_page;
  my %user_tmpl_data;
  my %top_bar_html_db;
  my %bot_bar_html_db;
  my %left_bar_html_db;

  my $db_key;
  my $db_key2;

  my %user_prof;
  my ($email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4);

  use Fcntl;

  $db_key2 = $user_id . "temp" . $session_id;

  # read and update user_tmpl_data, top_bar_html, bot_bar_html, left_bar_html database
  eval {
    tie %user_tmpl_data, "DB_File", $USER_TEMPLATE_DATA_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_TEMPLATE_DATA_DB_FILE: $!";
    tie %top_bar_html_db, "DB_File", $TOP_BAR_HTML, O_CREAT|O_RDWR, 0755 or die "Cannot open $TOP_BAR_HTML: $!";
    tie %bot_bar_html_db, "DB_File", $BOT_BAR_HTML, O_CREAT|O_RDWR, 0755 or die "Cannot open $BOT_BAR_HTML: $!";
    tie %left_bar_html_db, "DB_File", $LEFT_BAR_HTML, O_CREAT|O_RDWR, 0755 or die "Cannot open $LEFT_BAR_HTML: $!";

    if (!$user_tmpl_data{$db_key2}) {
      return (1, "The template could not be saved due to an internal error. Please create the template again.");
    } else {
      if ($caller == "edit") {
        $tmpl_id = $query->param('id');
      } else {
        $tmpl_id = $user_tmpl_data{$db_key};
        $tmpl_id++;
        $user_tmpl_data{$db_key} = $tmpl_id;
      }
      $db_key3 = $user_id . $tmpl_id;

      $user_tmpl_data{$db_key3} = $user_tmpl_data{$db_key2};
      delete $user_tmpl_data{$db_key2};
      delete $top_bar_html_db{$db_key3};
      delete $bot_bar_html_db{$db_key3};
      delete $left_bar_html_db{$db_key3};
    }
  };

  if ($@){
    log_error("p_advadd0", $@);
    return (99, $internal_error);
  }

  $srch_rslts_page = $SRCH_USER_DIR.'templates/'$user_id.$tmpl_id.'.html';

  if (-e $temp_page) {
    # write to user search results page
    use Fcntl ':flock';        # import LOCK_* constants
    eval {
      rename $temp_page, $srch_rslts_page;
    };
    if ($@){
      log_error("p_advadd1", $@);
      return (99, $internal_error);
    }
  } else {
    return (1, "The template could not be saved due to an internal error. Please create the template again.");
  }


  # update user_prof database
  eval {
    tie %user_prof, "DB_File", $USER_PROFILE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";
    ($email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_prof{$db_key});

    if (($config_status ne "IS") && ($config_status ne "IQS") && ($config_status ne "S")) {
      if ($config_status eq "I") {
        $config_status = "IS"
      } else {
        if ($config_status eq "IQ") {
          $config_status = "IQS"
        } else {
          $config_status = "S"
        }
      }
      $user_prof{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4);
    }
    untie %user_prof;
  };
  if ($@){
    log_error("p_advadd2", $@);
    return (99, $internal_error);
  }


  #
  # update the user_status_dbfile with config_status
  #   key = user_id + '-' + status_type
  #     status_type = 1 = last_indexed_date
  #     status_type = 2 = last_search_use_date
  #     status_type = 3 = member_status (F = free, S = subscription)
  #     status_type = 4 = config_status (I, IQ, S, IS, IQS)
  #
  eval {
    tie %user_status_dbfile, $db_package, $USER_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_STATUS_DB_FILE: $!";
    $db_key = $user_id.'-4';
    if ($user_status_dbfile{$db_key} ne $config_status) {
      $user_status_dbfile{$db_key} = $config_status;
    }
    untie %user_status_dbfile;
  };

  if ($@) {
    log_error ("p_advadd3", $@);
    return (99, $internal_error);
  }

  return (0, "success");

}




sub d_del {

  my $user_id    = $query->param('uid');
  my $session_id = $query->param('sid');
  my $tmpl_id    = $query->param('id');
  my $tmpl_title = $query->param('title');
  my $screen_html_file = $PAGE_DIR.'tmpldel.html';
  my $screen_html;

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);
  };
  if ($@){
    log_error("d_del0", $@);
    return (99, $internal_error);
  }

  $screen_html =~ s/:::grepin-1500:::/$tmpl_id/g;
  $screen_html =~ s/:::grepin-1501:::/$tmpl_title/g;

  return (0, $screen_html);

}



sub e_del {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $e_return_code;
  my $screen_html;

  use Fcntl;

  ($e_return_code, $screen_html) = d_del();

  if ($e_return_code == 0) {
    $error_msg = "Error:".$error_id." ".$error_msg;
    $screen_html =~ s/:::grepin-1502:::/$error_msg/g; # give the error message
    return (0, $screen_html);
  } else {
    return ($e_return_code, $screen_html);
  }

}



sub p_del {

  my $user_id    = $query->param('uid');
  my $session_id = $query->param('sid');
  my $tmpl_id    = $query->param('id');
  my ($db_key, $db_key2);
  my %user_tmpl_dbfile;
  my %top_bar_html_db;
  my %bot_bar_html_db;
  my %left_bar_html_db;

  my $srch_rslts_page;
  my $srch_rslts_page2;

  use Fcntl;

  eval {
    tie %user_tmpl_data, "DB_File", $USER_TEMPLATE_DATA_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_TEMPLATE_DATA_DB_FILE: $!";
    tie %top_bar_html_db, "DB_File", $TOP_BAR_HTML, O_CREAT|O_RDWR, 0755 or die "Cannot open $TOP_BAR_HTML: $!";
    tie %bot_bar_html_db, "DB_File", $BOT_BAR_HTML, O_CREAT|O_RDWR, 0755 or die "Cannot open $BOT_BAR_HTML: $!";
    tie %left_bar_html_db, "DB_File", $LEFT_BAR_HTML, O_CREAT|O_RDWR, 0755 or die "Cannot open $LEFT_BAR_HTML: $!";

    $db_key  = $user_id . $tmpl_id;
    $srch_rslts_page = $SRCH_USER_DIR.'templates/'$user_id.$tmpl_id.'.html';
    $tmpl_id++;
    $db_key2 = $user_id . $tmpl_id;
    $srch_rslts_page2 = $SRCH_USER_DIR.'templates/'$user_id.$tmpl_id.'.html';

    use Fcntl ':flock';        # import LOCK_* constants
    while ($user_tmpl_data{$db_key2}) {
      $user_tmpl_data{$db_key} = $user_tmpl_data{$db_key2};
      if ($top_bar_html_db{$db_key2}) {
        $top_bar_html_db{$db_key} = $top_bar_html_db{$db_key2};
      } else {
        delete $top_bar_html_db{$db_key};
      }
      if ($bot_bar_html_db{$db_key2}) {
        $bot_bar_html_db{$db_key} = $bot_bar_html_db{$db_key2};
      } else {
        delete $bot_bar_html_db{$db_key};
      }
      if ($left_bar_html_db{$db_key2}) {
        $left_bar_html_db{$db_key} = $left_bar_html_db{$db_key2};
      } else {
        delete $left_bar_html_db{$db_key};
      }

      rename $srch_rslts_page2, $srch_rslts_page;

      $db_key = $db_key2;
      $srch_rslts_page = $srch_rslts_page2;
      $tmpl_id++;
      $db_key2 = $user_id . $tmpl_id;
      $srch_rslts_page2 = $SRCH_USER_DIR.'templates/'$user_id.$tmpl_id.'.html';

    }

    delete $user_tmpl_data{$db_key}
    delete $top_bar_html_db{$db_key};
    delete $bot_bar_html_db{$db_key};
    delete $left_bar_html_db{$db_key};
    if (-e $srch_rslts_page) {					# if this file exists
      unlink($srch_rslts_page) or die "Cannot delete $srch_rslts_page: $!";
    }
  };
  if ($@){
    log_error("d_del0", $@);
    return (99, $internal_error);
  }

  return (0, "success");

}




































































































###############################################################################################



sub d_static {
  # return codes
  #  0 = success
  # 99 = error in accessing files and database

  # Following screens use this subroutine
  #  config index after
  #  config search results
  #  config search results after
  #  home
  #  faq
  #  features
  #  10benefits
  #  howitworks
  #  signup
  #
  #

  # Usage
  #  ($return_code, $screen_html) = d_static($screen_name)
  #

  my $screen_name  = shift;
  my $screen_html_file = $PAGE_DIR.$screen_name.'.html';
  my $screen_html;
  my $log_process = "d_static_".$screen_name;

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);
  };
  if ($@){
    log_error($log_process, $@);
    return (99, $internal_error);
  }

  return (0, $screen_html);

}




sub log_error {
# log error in the error file
# return codes
#  0 = success
# 99 = database error

  my $log_process   = shift;
  my $log_message   = shift;
  my @line = ();
  my $addr = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};

  use Fcntl;

  push(@line, $log_process || '-',
              $log_message || '-',
              $query->param('cmd') || '-',
              $query->param('fn') || '-',
              $query->param('arg') || '-',
              $query->param('uid') || '-',
              $query->param('sid') || '-',
              localtime time() || '-',
              $addr || '-');

  use Fcntl ':flock';        # import LOCK_* constants
  open(LOG, ">>$LOG_FILE") or die "Cannot open logfile '$LOG_FILE' for writing: $!";
  flock(LOG, LOCK_EX);
  seek(LOG, 0, 2);
  print LOG join(':::', @line).":::\n";
  flock(LOG, LOCK_UN);
  close(LOG);

  return (0, "success");

}




sub p_sessnchk {
# check the validity of the session id
# return codes
#  0 - session-id is valid
#  1 - session-id is not sent to this program
#  2 - session-id is not in database - has to login
#  3 - session has expired
#  99 - database error

  my $user_id    = $query->param('uid');
  my $session_id = $query->param('sid');
  my %session_db;     # session_id -> (last_accessed_timestamp)
  my $current_time = time;
  my $session_time;

  use Fcntl;

  if ((!$session_id) || ($session_id =~ /^\s+$/)) {
    return (1, "Session Id is not sent or is spaces.");
  }

  # The data structure for session information
  eval {
    tie %session_db,    "DB_File", $SESSION_DB_FILE, O_CREAT|O_RDWR, 0755      or die "Cannot open $SESSION_DB_FILE: $!";
  };
  if ($@){
    log_error("p_sessnchk1", $@);
    return (99, $internal_error);
  }

  if ((!$session_db{$session_id}) || ($session_id !~ /$user_id/))  {
    return (2, "This Session is invalid. You have to login again.");
  }

  $session_time = $session_db{$session_id};

  if (($current_time - $session_time) > 1800) {
    delete $session_db{$session_id};
    return (3, "This Session has expired. You have to login again.");
  }

  $session_db{$session_id} = $current_time;
  untie %session_db;
  return (0, "success");
}




sub e_login {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $email_id = undef;

  my $screen_html_file = $PAGE_DIR.'login.html';
  my $screen_html;

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);
  };
  if ($@){
    log_error("e_login1", $@);
    return (99, $internal_error);
  }

  $error_msg = "Error:".$error_id." ".$error_msg;

  if ($error_id == 5191) {
    $email_id = $query->param('f5103');
    $screen_html =~ s/:::grepin-f5103:::/$email_id/g;
    $screen_html =~ s/:::grepin-f5191:::/$error_msg/g; # give the error message
  } else {
    $email_id = $query->param('f5100');
    $screen_html =~ s/:::grepin-f5100:::/$email_id/g;
    $screen_html =~ s/:::grepin-f5190:::/$error_msg/g; # give the error message
  }

  return (0, $screen_html);

}

