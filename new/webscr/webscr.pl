#!/usr/bin/perl

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
#   use CGI::Carp qw(carpout);
#   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/webscrerr.txt")
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
  my $LOG_FILE   = $LOG_DIR.'webscrlog.txt';
  my $LOG_SOURCE = $LOG_DIR.'sourcelog.txt';

  my $LATEST_IDS_DB_FILE         = $USER_DIR.'latestids';
  my $SESSION_DB_FILE            = $USER_DIR.'session';
  my $USER_PWD_DB_FILE           = $USER_DIR.'userpwd';
  my $USER_PROFILE_DB_FILE       = $USER_DIR.'userprof';
  my $USER_INDEX_DATA_DB_FILE    = $USER_DIR.'userindxdata';
  my $JOB_STATUS_DB_FILE         = $USER_DIR.'jobstatus';
  my $QUEUE_DB_FILE              = $USER_DIR.'queue';
  my $INDEX_QUEUE_DB_FILE        = $USER_DIR.'indxqueue';
  my $USER_STATUS_DB_FILE        = $USER_DIR.'userstatus';

  ########################################

  my $cmd        = $query->param('cmd');
  my $session_id = $query->param('sid');
  my $user_id    = $query->param('uid');

  my $USER_LOCAL_DIR = $MAIN_DIR.$user_id.'/';
  my $SRCH_USER_DIR  = $SRCH_DIR.'search/';

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
    push(@line, 'webscr ------------- ',
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
    log_error("webscr1", "The DB_File module was not found.");
    print "$internal_error \n\n";
    exit;
  }

####  DO NOT CALL ANY SUB-PROGRAM UNTIL THIS POINT ########


  if (!$cmd) {
    $cmd = "home";
  }

  if ($session_id) {
    if (($cmd eq "login") || ($cmd eq "signup")) {
      ($return_code, $return_msg) = p_logout();
      $user_id    = undef;
      $session_id = undef;
    } else {
      ($return_code, $return_msg) = p_sessnchk();
      if ($return_code != 0) {
        $user_id    = undef;
        $session_id = undef;
        if (($cmd eq "acctmgmt") || ($cmd eq "cnfgindx") || ($cmd eq "members") || ($cmd eq "terminate")) {
          ($return_code, $return_msg) = e_login(5190, $return_msg);
          $valid_sid = 'F';
        }
      }
    }
  } else {
    if (($cmd eq "acctmgmt") || ($cmd eq "cnfgindx") || ($cmd eq "members") || ($cmd eq "terminate")) {
      ($return_code, $return_msg) = e_login(5190, "You have to login as a member to access this page.");
      $user_id = undef;
      $valid_sid = 'F';
    }
  }

  if ($valid_sid eq 'T') {
    if (($cmd eq "home") || ($cmd eq "faqs") || ($cmd eq "features") || ($cmd eq "7ways") || ($cmd eq "srchhtml")) {
      ($return_code, $return_msg) = d_static ($cmd);
    } elsif ($cmd eq "signup") {
      ($return_code, $return_msg) = m_signup();
    } elsif ($cmd eq "login") {
      ($return_code, $return_msg) = m_login();
    } elsif ($cmd eq "acctmgmt") {
      ($return_code, $return_msg) = m_acctmgmt();
    } elsif ($cmd eq "cnfgindx") {
      ($return_code, $return_msg) = m_cnfgindx();
    } elsif ($cmd eq "contctme") {
      ($return_code, $return_msg) = m_contctme();
    } elsif ($cmd eq "members") {
      ($return_code, $return_msg) = m_members();
    } elsif ($cmd eq "logout") {
      ($return_code, $return_msg) = m_logout();
    } elsif ($cmd eq "terminate") {
      ($return_code, $return_msg) = m_terminate();
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


sub m_signup {

  my $fn      = $query->param('fn');
  my $m_return_code;
  my $m_return_msg;

  if (!$fn) {
    ($m_return_code, $m_return_msg) = d_signup();
  } elsif ($fn eq "submit") {
    ($m_return_code, $m_return_msg) = p_signup();
    if ($m_return_code == 0) {
      ($m_return_code, $m_return_msg) = d_static("signup2");
#-->   change the referrer url to fn=success
    } else {
      ($m_return_code, $m_return_msg) = e_signup(5090, $m_return_msg);
    }
  } elsif ($fn eq "success") {
    ($m_return_code, $m_return_msg) = d_static("signup2");
  } else {
    $m_return_code = 99;
    $m_return_msg  = "Invalid request. Please check the URL and try again.";
  }
  return ($m_return_code, $m_return_msg);
}


sub m_login {

  my $fn      = $query->param('fn');
  my $m_return_code;
  my $m_return_msg;

  if (!$fn) {
    ($m_return_code, $m_return_msg) = d_static("login");
  } elsif ($fn eq "login") {
    ($m_return_code, $m_return_msg) = p_login();
    if ($m_return_code == 0) {
      $user_id    = $m_return_msg;
      ($m_return_code, $m_return_msg) = p_sessncre($user_id);
         if ($m_return_code == 0) {
           $session_id = $m_return_msg;
           ($m_return_code, $m_return_msg) = d_members($user_id);
#-->   change the referrer url to cmd=members
         } else {
           $user_id    = undef;
           $session_id = undef;
           ($m_return_code, $m_return_msg) = e_login(5190, $m_return_msg);
         }
    } else {
      ($m_return_code, $m_return_msg) = e_login(5190, $m_return_msg);
    }
  } elsif ($fn eq "sendpass") {
    ($m_return_code, $m_return_msg) = p_sendpass();
    if ($m_return_code == 0) {
      ($m_return_code, $m_return_msg) = d_static("passsent");
#-->   change the referrer url to fn=passsent
    } else {
      ($m_return_code, $m_return_msg) = e_login(5191, $m_return_msg);
    }
  } elsif ($fn eq "passsent") {
    ($m_return_code, $m_return_msg) = d_static("passsent");
  } else {
    $m_return_code = 99;
    $m_return_msg  = "Invalid request. Please check the URL and try again.";
  }
  return ($m_return_code, $m_return_msg);
}


sub m_acctmgmt {

  my $fn      = $query->param('fn');
  my $user_id = $query->param('uid');
  my $m_return_code;
  my $m_return_msg;

  if (!$fn) {
    ($m_return_code, $m_return_msg) = d_acctmgmt($user_id);
  } elsif ($fn eq "chngprof") {
    ($m_return_code, $m_return_msg) = p_chngprof($user_id);
    if ($m_return_code == 0) {
      ($m_return_code, $m_return_msg) = d_acctmgmt($user_id);
#-->   change the referrer url to fn=undef
    } else {
      ($m_return_code, $m_return_msg) = e_acctmgmt(5390, $m_return_msg);
    }
  } elsif ($fn eq "chngpass") {
    ($m_return_code, $m_return_msg) = p_chngpass($user_id);
    if ($m_return_code == 0) {
      ($m_return_code, $m_return_msg) = d_acctmgmt($user_id);
#-->   change the referrer url to fn=undef
    } else {
      ($m_return_code, $m_return_msg) = e_acctmgmt(5391, $m_return_msg);
    }
  } else {
    $m_return_code = 99;
    $m_return_msg  = "Invalid request. Please check the URL and try again.";
  }
  return ($m_return_code, $m_return_msg);
}


sub m_cnfgindx {

  my $fn      = $query->param('fn');
  my $user_id = $query->param('uid');
  my $m_return_code;
  my $m_return_msg;

  if (!$fn) {
    ($m_return_code, $m_return_msg) = d_cnfgindx($user_id);
  } elsif ($fn eq "submit") {
    ($m_return_code, $m_return_msg) = p_cnfgindx();
    if ($m_return_code == 0) {
      ($m_return_code, $m_return_msg) = d_static("cnfgindx2");
#-->   change the referrer url to fn=success
    } else {
      ($m_return_code, $m_return_msg) = e_cnfgindx(5490, $m_return_msg);
    }
  } elsif ($fn eq "success") {
    ($m_return_code, $m_return_msg) = d_static("cnfgindx2");
  } else {
    $m_return_code = 99;
    $m_return_msg  = "Invalid request. Please check the URL and try again.";
  }
  return ($m_return_code, $m_return_msg);
}


sub m_contctme {

  my $fn      = $query->param('fn');
  my $user_id = $query->param('uid');
  my $m_return_code;
  my $m_return_msg;

  if (!$fn) {
    ($m_return_code, $m_return_msg) = d_contctme($user_id);
  } elsif ($fn eq "sendmsg") {
    ($m_return_code, $m_return_msg) = p_contctme();
    if ($m_return_code == 0) {
      ($m_return_code, $m_return_msg) = d_static("contctme2");
#-->   change the referrer url to fn=success
    } else {
      ($m_return_code, $m_return_msg) = e_contctme(9090, $m_return_msg);
    }
  } elsif ($fn eq "success") {
    ($m_return_code, $m_return_msg) = d_static("contctme2");
  } else {
    $m_return_code = 99;
    $m_return_msg  = "Invalid request. Please check the URL and try again.";
  }
  return ($m_return_code, $m_return_msg);
}


sub m_members {

  my $fn      = $query->param('fn');
  my $user_id = $query->param('uid');
  my $m_return_code;
  my $m_return_msg;

  if (!$fn) {
    ($m_return_code, $m_return_msg) = d_members($user_id);
  } elsif ($fn eq "reindex") {
    ($m_return_code, $m_return_msg) = p_reindex($user_id);
    if ($m_return_code == 0) {
      ($m_return_code, $m_return_msg) = d_static("reindex2");
#-->   change the referrer url to fn=success
    } else {
      ($m_return_code, $m_return_msg) = e_members(5290, $m_return_msg);
    }
  } elsif ($fn eq "success") {
    ($m_return_code, $m_return_msg) = d_static("reindex2");
  } else {
    $m_return_code = 99;
    $m_return_msg  = "Invalid request. Please check the URL and try again.";
  }
  return ($m_return_code, $m_return_msg);
}


sub m_logout {

  my $m_return_code;
  my $m_return_msg;

  if ($query->param('sid')) {
    ($m_return_code, $m_return_msg) = p_logout();
  }
  $user_id    = undef;
  $session_id = undef;
  ($m_return_code, $m_return_msg) = d_static("home");
  return ($m_return_code, $m_return_msg);
}


sub m_terminate {

  my $fn      = $query->param('fn');
  my $user_id = $query->param('uid');
  my $m_return_code;
  my $m_return_msg;

  if (!$fn) {
    ($m_return_code, $m_return_msg) = d_static("terminate");
  } elsif ($fn eq "confirm") {
    ($m_return_code, $m_return_msg) = p_terminate();
    if ($m_return_code == 0) {
      if ($query->param('sid')) {
        ($m_return_code, $m_return_msg) = p_logout();
      }
      $user_id    = undef;
      $session_id = undef;
      ($m_return_code, $m_return_msg) = d_static("terminate2");
#-->   change the referrer url to fn=success
    } else {
      ($m_return_code, $m_return_msg) = e_terminate(9990, $m_return_msg);
    }
  } elsif ($fn eq "success") {
    ($m_return_code, $m_return_msg) = d_static("terminate2");
  } else {
    $m_return_code = 99;
    $m_return_msg  = "Invalid request. Please check the URL and try again.";
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
    log_error("webscr2", $@);
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



sub d_acctmgmt {

  my $user_id    = shift;
  my %user_profile_dbfile;
  my $db_key;
  my ($email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4);
  my $screen_html_file = $PAGE_DIR.'acctmgmt.html';
  my $screen_html;
  my $error_msg;
  my $d_return_code;
  my $checked = "CHECKED";

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %user_profile_dbfile, "DB_File", $USER_PROFILE_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";

  };
  if ($@){
    log_error("d_acctmgmt1", $@);
    return (99, $internal_error);
  }

  $db_key = $user_id;

  if (!($user_profile_dbfile{$db_key})) {
    $error_msg = "Error:5390 - User is not found in our database. Please report this problem (including this message and the error number) to the webmaster for further assistance.";
    $screen_html =~ s/:::grepin-f5390:::/$error_msg/g; # give the error message
    $screen_html =~ s/:::grepin-f5302:::/$checked/g;  # select the content based (default)

#    disable the buttons....
    $d_return_code = 1;
  } else {
    ($email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_profile_dbfile{$db_key});

    $screen_html =~ s/:::grepin-f5300:::/$email_id/g;
    $screen_html =~ s/:::grepin-f5301:::/$web_addr/g;
    if ($web_type eq 'P') {
      $screen_html =~ s/:::grepin-f5302a:::/$checked/g; # select the product based
    } else {
      $screen_html =~ s/:::grepin-f5302:::/$checked/g;  # select the content based (default)
    }
    $screen_html =~ s/:::grepin-f5303:::/$name/g;
    $screen_html =~ s/:::grepin-f5304:::/$phone/g;
    $screen_html =~ s/:::grepin-f5305:::/$addr1/g;
    $screen_html =~ s/:::grepin-f5306:::/$addr2/g;
    $screen_html =~ s/:::grepin-f5307:::/$city/g;
    $screen_html =~ s/:::grepin-f5308:::/$state/g;
    $screen_html =~ s/:::grepin-f5309:::/$zip/g;
    $screen_html =~ s/:::grepin-f5310:::/$country/g;
    $screen_html =~ s/:::grepin-f5312:::/$email_id/g;

    $d_return_code = 0;
  }

  untie %user_profile_dbfile;

  return ($d_return_code, $screen_html);

}

sub e_acctmgmt {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $screen_html_file = $PAGE_DIR.'acctmgmt.html';
  my $screen_html;
  my $e_return_code;

  use Fcntl;

  $error_msg = "Error:".$error_id." ".$error_msg;

  if ($error_id == 5391) {

    my $user_id    = $query->param('uid');
    ($e_return_code, $screen_html) = d_acctmgmt($user_id);
    if ($e_return_code == 0) {
      $screen_html =~ s/:::grepin-f5391:::/$error_msg/g; # give the error message in change password section
    } else {
      log_error("e_acctmgmt1", $return_msg);
    }

  } else {

    my $email_id   = $query->param('f5300');
    my $web_addr   = $query->param('f5301');
    my $web_type   = $query->param('f5302');
    my $name       = $query->param('f5303');
    my $phone      = $query->param('f5304');
    my $addr1      = $query->param('f5305');
    my $addr2      = $query->param('f5306');
    my $city       = $query->param('f5307');
    my $state      = $query->param('f5308');
    my $zip        = $query->param('f5309');
    my $country    = $query->param('f5310');
    my $checked = "CHECKED";

    eval {
      open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

      while (<HTMLFILE>) {
        $screen_html .= $_;
      }
      close(HTMLFILE);
    };
    if ($@){
      log_error("e_acctmgmt2", $@);
      return (99, $internal_error);
    }

    $screen_html =~ s/:::grepin-f5390:::/$error_msg/g; # give the error message in main section
    $screen_html =~ s/:::grepin-f5300:::/$email_id/g;
    $screen_html =~ s/:::grepin-f5301:::/$web_addr/g;
    if ($web_type eq 'P') {
      $screen_html =~ s/:::grepin-f5302a:::/$checked/g; # select the product based
    } else {
      $screen_html =~ s/:::grepin-f5302:::/$checked/g;  # select the content based (default)
    }
    $screen_html =~ s/:::grepin-f5303:::/$name/g;
    $screen_html =~ s/:::grepin-f5304:::/$phone/g;
    $screen_html =~ s/:::grepin-f5305:::/$addr1/g;
    $screen_html =~ s/:::grepin-f5306:::/$addr2/g;
    $screen_html =~ s/:::grepin-f5307:::/$city/g;
    $screen_html =~ s/:::grepin-f5308:::/$state/g;
    $screen_html =~ s/:::grepin-f5309:::/$zip/g;
    $screen_html =~ s/:::grepin-f5310:::/$country/g;
    $screen_html =~ s/:::grepin-f5312:::/$email_id/g;

    $e_return_code = 0;
  }
  return ($e_return_code, $screen_html);
}

sub p_chngpass {
# change user's password
# return codes
#  0 = success
#  1 = email is not entered
#  2 = user does not exist
#  3 = old password does not match the one on the database
#  4 = new password 1 and 2 does not match
# 99 = database error

  my $user_id   = shift;
  my $old_pass  = $query->param('f5313');
  my $new_pass1 = $query->param('f5314');
  my $new_pass2 = $query->param('f5315');
  my $db_key;
  my %user_profile;
  my %user_pwd;
  my $email_id;
  my $pwd_on_file;

  use Fcntl;

  #convert everything to lower case
  $old_pass  =~ tr/A-Z/a-z/;
  $new_pass1 =~ tr/A-Z/a-z/;
  $new_pass2 =~ tr/A-Z/a-z/;

  eval {
    tie %user_profile, "DB_File", $USER_PROFILE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";
  };
  if ($@){
    log_error("p_chngpass1",$@);
    return (99, $internal_error);
  }

  $db_key = $user_id;
  ($email_id, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_profile{$db_key});
  untie %user_profile;

  eval {
    tie %user_pwd, "DB_File", $USER_PWD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PWD_DB_FILE: $!";
  };
  if ($@){
    log_error("p_chngpass2", $@);
    return (99, $internal_error);
  }

  $db_key = $email_id;
  if (!$user_pwd{$db_key}) {
    return (1, "User does not exist in our system.");
  }

  ($pwd_on_file, $user_id) = unpack("C/A* C/A*", $user_pwd{$db_key});

  if (crypt($old_pass, $pwd_on_file) ne $pwd_on_file) {
    return (2, "Your Old Password is invalid. Please enter again.");
  }

  if ($new_pass1 =~ /\s/) {
    return (3, "Your new password contains invalid characters. It should not have spaces or whitespace.")
  }

  if (length ($new_pass1) < 7 ) {
    return (3, "Your new password should be atleast 7 characters in length.")
  }

  if ($new_pass1 ne $new_pass2) {
    return (3, "The 2 New Passwords do not match. Please enter again.");
  }

  $user_pwd{$db_key} = pack("C/A* C/A*", crypt($new_pass1, (length $email_id)), $user_id);
  untie %user_pwd;

  return (0, "success");

}


sub p_chngprof {
# change user profile
# return codes
#  0 = success
#  1 = invalid email address
#  2 = invalid web address (should have http:// and /)
#  3 = invalid web type
#  4 = user does not exist
#  5 = invalid password
# 99 = database error

  my $user_id  = shift;
  my $email_id = $query->param('f5300');
  my $web_addr = $query->param('f5301');
  my $web_type = $query->param('f5302');
  my $name     = $query->param('f5303');
  my $phone    = $query->param('f5304');
  my $addr1    = $query->param('f5305');
  my $addr2    = $query->param('f5306');
  my $city     = $query->param('f5307');
  my $state    = $query->param('f5308');
  my $zip      = $query->param('f5309');
  my $country  = $query->param('f5310');
  my $password = $query->param('f5311');
  my %user_pwd;
  my $pwd_on_file;
  my %user_profile;
  my $old_email_id;
  my $db_key;
  my $db_key2;
  my ($add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4);

  use Fcntl;

  #change to lower case
  $email_id =~ tr/A-Z/a-z/;
  $web_addr =~ tr/A-Z/a-z/;
  $password =~ tr/A-Z/a-z/;

  # replace any white space to a single space
  $email_id =~ s/\s+/ /g;
  $web_addr =~ s/\s+/ /g;
  $name     =~ s/\s+/ /g;
  $phone    =~ s/\s+/ /g;
  $addr1    =~ s/\s+/ /g;
  $addr2    =~ s/\s+/ /g;
  $city     =~ s/\s+/ /g;
  $state    =~ s/\s+/ /g;
  $zip      =~ s/\s+/ /g;
  $country  =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $email_id =~ s/(^\s+)|(\s+$)//;
  $web_addr =~ s/(^\s+)|(\s+$)//;
  $name     =~ s/(^\s+)|(\s+$)//;
  $phone    =~ s/(^\s+)|(\s+$)//;
  $addr1    =~ s/(^\s+)|(\s+$)//;
  $addr2    =~ s/(^\s+)|(\s+$)//;
  $city     =~ s/(^\s+)|(\s+$)//;
  $state    =~ s/(^\s+)|(\s+$)//;
  $zip      =~ s/(^\s+)|(\s+$)//;
  $country  =~ s/(^\s+)|(\s+$)//;

  if ($email_id =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)/ ||

     # the e-mail address contains an invalid syntax.  Or, if the
     # syntax does not match the following regular expression pattern
     # it fails basic syntax verification.

     $email_id !~ /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z0-9]+)(\]?)$/) {

     # Basic syntax requires:  one or more characters before the @ sign,
     # followed by an optional '[', then any number of letters, numbers,
     # dashes or periods (valid domain/IP characters) ending in a period
     # and then 2 or 3 letters (for domain suffixes) or 1 to 3 numbers
     # (for IP addresses).  An ending bracket is also allowed as it is
     # valid syntax to have an email address like: user@[255.255.255.0]
     # Return a false value, since the e-mail address did not pass valid
     # syntax.
     return (1, "Invalid Email Address format. Please enter again.");
  }

  if (($web_addr !~ m%^http://.*/$%) && ($web_addr !~ m%^https://.*/$%)) {
    return (2, "Your Web Address should start with 'http://' or 'https://' and end with '/'.");
  }

  if (($web_type ne "C") && ($web_type ne "P")) {
    return (3, "Type of Your Web Site should be C or P.");
  }

  eval {
    tie %user_profile, "DB_File", $USER_PROFILE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";
  };
  if ($@){
    log_error("p_chngprof1",$@);
    return (99, $internal_error);
  }

  $db_key2 = $user_id;
  ($old_email_id, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $add_date, $d11, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_profile{$db_key2});

  eval {
    tie %user_pwd, "DB_File", $USER_PWD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PWD_DB_FILE: $!";
  };
  if ($@){
    log_error("p_chngprof2",$@);
    untie %user_profile;
    return (99, $internal_error);
  }

  $db_key = $old_email_id;
  if (!$user_pwd{$db_key}) {
    untie %user_pwd;
    untie %user_profile;
    return (4, "Your Email Address does not exist in our system. Please enter again or signup for an account.");
  }

  ($pwd_on_file, $user_id) = unpack("C/A* C/A*", $user_pwd{$db_key});

  if (crypt($password, $pwd_on_file) ne $pwd_on_file) {
    return (5, "Invalid Password entered. Please try again.");
  }

  $update_date = time;

  $user_profile{$db_key2} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4);

  delete $user_pwd{$db_key};
  $db_key = $email_id;
  $user_pwd{$db_key} = pack("C/A* C/A*", crypt($password, (length ($email_id))), $user_id);

  untie %user_pwd;
  untie %user_profile;

  return (0, "success");

}


###########################################################################################################


sub d_signup {

  my $screen_html_file = $PAGE_DIR.'signup.html';
  my $screen_html;
  my $checked = "CHECKED";
  my $init_web_addr_value = "http://";

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";
    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);
  };
  if ($@){
    log_error("d_signup1", $@);
    return (99, $internal_error);
  }

  $screen_html =~ s/:::grepin-f5001:::/$init_web_addr_value/g; # put a default http:// value in web address
  $screen_html =~ s/:::grepin-f5002:::/$checked/g;  # select the content based (default)

  return (0, $screen_html);

}


sub e_signup {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $email_id   = $query->param('f5000');
  my $web_addr   = $query->param('f5001');
  my $web_type   = $query->param('f5002');
  my $name       = $query->param('f5003');
  my $phone      = $query->param('f5004');
  my $addr1      = $query->param('f5005');
  my $addr2      = $query->param('f5006');
  my $city       = $query->param('f5007');
  my $state      = $query->param('f5008');
  my $zip        = $query->param('f5009');
  my $country    = $query->param('f5010');
  my $checked    = "CHECKED";

  my $screen_html_file = $PAGE_DIR.'signup.html';
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
    log_error("e_signup1", $@);
    return (99, $internal_error);
  }

  $error_msg = "Error:".$error_id." ".$error_msg;
  $screen_html =~ s/:::grepin-f5090:::/$error_msg/g; # give the error message
  $screen_html =~ s/:::grepin-f5000:::/$email_id/g;
  $screen_html =~ s/:::grepin-f5001:::/$web_addr/g;
    if ($web_type eq 'P') {
      $screen_html =~ s/:::grepin-f5002a:::/$checked/g; # select the product based
    } else {
      $screen_html =~ s/:::grepin-f5002:::/$checked/g;  # select the content based (default)
    }

  $screen_html =~ s/:::grepin-f5003:::/$name/g;
  $screen_html =~ s/:::grepin-f5004:::/$phone/g;
  $screen_html =~ s/:::grepin-f5005:::/$addr1/g;
  $screen_html =~ s/:::grepin-f5006:::/$addr2/g;
  $screen_html =~ s/:::grepin-f5007:::/$city/g;
  $screen_html =~ s/:::grepin-f5008:::/$state/g;
  $screen_html =~ s/:::grepin-f5009:::/$zip/g;
  $screen_html =~ s/:::grepin-f5010:::/$country/g;

  return (0, $screen_html);

}


sub p_creunqid {
# create a unique id
# return codes
# unique_id = success
# 99 = database error	- severity=3

  my $id_type = shift;
  my $unique_id;
  my %latest_ids;

  use Fcntl;

  eval {
    tie %latest_ids, "DB_File", $LATEST_IDS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $LATEST_IDS_DB_FILE: $!";
  };
  if ($@){
    log_error("p_creunqid1", $@);
    return (99, $internal_error);
  }

  if ($latest_ids{$id_type}) {
    $unique_id = $latest_ids{$id_type};
    $unique_id++;
  } else {
    $unique_id = 100000;
  }

  $latest_ids{$id_type} = $unique_id;

  untie %latest_ids;

  return (0, $unique_id);

}


sub p_creusrfle {
  # create user files
  # return codes
  #  0 = success
  # 99 = database error

  my $user_id            = shift;
  my $web_addr           = shift;
  my $USER-SPECIFIC_DIR  = $USER_LOCAL_DIR.'search';
  my $USER_DATA_DIR      = $USER_SPECIFIC_DIR.'/data';
  my $USER_REPORTS_DIR   = $USER_SPECIFIC_DIR.'/reports';
  my $USER_TEMPL_DIR     = $USER_SPECIFIC_DIR.'/templates';
  my $USER_LOG_DIR       = $USER_SPECIFIC_DIR.'/log';
  my $u_userconf_file    = $USER_SPECIFIC_DIR.'/sub_userconf.pl';
  my $userconf_content;
  my $u_initrslt_file    = $USER_TEMPL_DIR.'/initrsltpage.html';
  my $initrslt_content;
  my $u_search_file      = $USER_TEMPL_DIR.'/search.html';
  my $search_content;
  my $u_nomatch_file     = $USER_TEMPL_DIR.'/nomatch.html';
  my $nomatch_content;

  use Fcntl;

  eval {
    mkdir $USER_SPECIFIC_DIR, 0755, or die "Cannot create user directory '$USER_SPECIFIC_DIR': $!";
    mkdir $USER_DATA_DIR, 0755, or die "Cannot create user data directory '$USER_DATA_DIR': $!";
    mkdir $USER_REPORTS_DIR, 0755, or die "Cannot create user reports directory '$USER_REPORTS_DIR': $!";
    mkdir $USER_TEMPL_DIR, 0755, or die "Cannot create user template directory '$USER_TEMPL_DIR': $!";
    mkdir $USER_LOG_DIR, 0755, or die "Cannot create user log directory '$USER_LOG_DIR': $!";

    open (TRSLTPAGE, $COMN_INITRSLT_TEMPLATE) or die "Cannot open COMN_INITRSLT_TEMPLATE '$COMN_INITRSLT_TEMPLATE' for reading: $!";
    while (<TRSLTPAGE>) {
      $initrslt_content .= $_;
    }
    $initrslt_content =~ s/:::grepin-base-url:::/$web_addr/gs;
    close(TRSLTPAGE);
    open(URSLTPAGE, ">$u_initrslt_file") or die "Cannot open uinitrsltfile '$u_initrslt_file' for writing: $!";
    flock(URSLTPAGE, LOCK_EX);
    seek(URSLTPAGE, 0, 2);
    print URSLTPAGE "$initrslt_content\n";
    flock(URSLTPAGE, LOCK_UN);
    close(URSLTPAGE);


    open (TSRCHPAGE, $COMN_SEARCH_TEMPLATE) or die "Cannot open COMN_SEARCH_TEMPLATE '$COMN_SEARCH_TEMPLATE' for reading: $!";
    while (<TSRCHPAGE>) {
      $search_content .= $_;
    }
    close(TSRCHPAGE);
    open(USRCHPAGE, ">$u_search_file") or die "Cannot open usearchfile '$u_search_file' for writing: $!";
    flock(USRCHPAGE, LOCK_EX);
    seek(USRCHPAGE, 0, 2);
    print USRCHPAGE "$search_content\n";
    flock(USRCHPAGE, LOCK_UN);
    close(USRCHPAGE);


    open (TNOMTCHPAGE, $COMN_NO_MATCH_TEMPLATE) or die "Cannot open COMN_NO_MATCH_TEMPLATE '$COMN_NO_MATCH_TEMPLATE' for reading: $!";
    while (<TNOMTCHPAGE>) {
      $nomatch_content .= $_;
    }
    close(TNOMTCHPAGE);
    open(UNOMTCHPAGE, ">$u_nomatch_file") or die "Cannot open unomatchfile '$u_nomatch_file' for writing: $!";
    flock(UNOMTCHPAGE, LOCK_EX);
    seek(UNOMTCHPAGE, 0, 2);
    print UNOMTCHPAGE "$nomatch_content\n";
    flock(UNOMTCHPAGE, LOCK_UN);
    close(UNOMTCHPAGE);

    open (TUSRCNFPAGE, $COMN_USER_CONF_TEMPLATE) or die "Cannot open COMN_USER_CONF_TEMPLATE '$COMN_USER_CONF_TEMPLATE' for reading: $!";
    while (<TUSRCNFPAGE>) {
      $userconf_content .= $_;
    }
    close(TUSRCNFPAGE);
    $userconf_content =~ s/:::grepin-userid:::/$user_id/g;
    use Fcntl ':flock';        # import LOCK_* constants
    open(UUSRCNFPAGE, ">$u_userconf_file") or die "Cannot open uuserconffile '$u_userconf_file' for writing: $!";
    flock(UUSRCNFPAGE, LOCK_EX);
    seek(UUSRCNFPAGE, 0, 2);
    print UUSRCNFPAGE "$userconf_content\n";
    flock(UUSRCNFPAGE, LOCK_UN);
    close(UUSRCNFPAGE);

  };
  if ($@) {
    log_error ("p_creusrfle1", $@);
    return (99, $internal_error);
  }

  return (0, "success");

}

sub p_signup {
# signup process
# return codes
#  0 = success
#  1 = invalid email address
#  2 = invalid web address (should have http:// and /)
#  3 = invalid web type
#  4 = user already exists
#  5 = you have to accept terms and agreements
#  6 = user files creation failed
#  7 = email was unsuccessful
# 99 = database error

  my $email_id = $query->param('f5000');
  my $web_addr = $query->param('f5001');
  my $web_type = $query->param('f5002');
  my $name     = $query->param('f5003');
  my $phone    = $query->param('f5004');
  my $addr1    = $query->param('f5005');
  my $addr2    = $query->param('f5006');
  my $city     = $query->param('f5007');
  my $state    = $query->param('f5008');
  my $zip      = $query->param('f5009');
  my $country  = $query->param('f5010');
  my $accpterm = $query->param('f5011');
  my $unique_id;
  my %user_pwd;
  my $user_id;
  my $password;
  my $emaillength;
  my $db_key;
  my %user_profile;
  my $add_date;
  my $update_date;
  my $member_status;
  my $config_status;
  my $cat1;
  my $cat2;
  my $cat3;
  my $cat4;

  my $subject;
  my $msgtxt;
  my $return_code;
  my $return_msg;
  my $createlog  = $LOG_DIR.'creuserlog.txt';
  my $addr = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};

  use Fcntl;

  # change to lower case
  $email_id =~ tr/A-Z/a-z/;
  $web_addr =~ tr/A-Z/a-z/;

  # replace any white space to a single space
  $email_id =~ s/\s+/ /g;
  $web_addr =~ s/\s+/ /g;
  $name     =~ s/\s+/ /g;
  $phone    =~ s/\s+/ /g;
  $addr1    =~ s/\s+/ /g;
  $addr2    =~ s/\s+/ /g;
  $city     =~ s/\s+/ /g;
  $state    =~ s/\s+/ /g;
  $zip      =~ s/\s+/ /g;
  $country  =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $email_id =~ s/(^\s+)|(\s+$)//;
  $web_addr =~ s/(^\s+)|(\s+$)//;
  $name     =~ s/(^\s+)|(\s+$)//;
  $phone    =~ s/(^\s+)|(\s+$)//;
  $addr1    =~ s/(^\s+)|(\s+$)//;
  $addr2    =~ s/(^\s+)|(\s+$)//;
  $city     =~ s/(^\s+)|(\s+$)//;
  $state    =~ s/(^\s+)|(\s+$)//;
  $zip      =~ s/(^\s+)|(\s+$)//;
  $country  =~ s/(^\s+)|(\s+$)//;

  # if email is not valid return 1
  # If the e-mail address contains:
  if ($email_id =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)/ ||

     # the e-mail address contains an invalid syntax.  Or, if the
     # syntax does not match the following regular expression pattern
     # it fails basic syntax verification.

     $email_id !~ /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z0-9]+)(\]?)$/) {

     # Basic syntax requires:  one or more characters before the @ sign,
     # followed by an optional '[', then any number of letters, numbers,
     # dashes or periods (valid domain/IP characters) ending in a period
     # and then 2 or 3 letters (for domain suffixes) or 1 to 3 numbers
     # (for IP addresses).  An ending bracket is also allowed as it is
     # valid syntax to have an email address like: user@[255.255.255.0]
     # Return a false value, since the e-mail address did not pass valid
     # syntax.
     return (1, "Invalid Email Address format. Please enter again.");
  }

  # if $web_addr does not start with http:// or https:// and end with /, return 2
  if (($web_addr !~ m%^http://.*/$%) && ($web_addr !~ m%^https://.*/$%)) {
    return (2, "Your Web Address should start with 'http://' or 'https://' and end in a '/'.");
  }

  # if $web_type is not C or P, return 3
  if (($web_type ne "C") && ($web_type ne "P")) {
    return (3, "Type of Your Web Site should be C or P.");
  }

  eval {
    tie %user_pwd, "DB_File", $USER_PWD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PWD_DB_FILE: $!";
  };
  if ($@){
    log_error("p_signup1",$@);
    return (99, $internal_error);
  }

  $db_key = $email_id;
  if ($user_pwd{$db_key}) {
    untie %user_pwd;
    return (4, "User already exists. Please use a different Email Address.");
  }

  if ($accpterm ne "Y") {
    return (5, "You have to check the 'I accept the Terms and Agreements' box to sign up for an account.");
  }

  ($return_code, $unique_id) = p_creunqid("u");
  if ($return_code == 99) {
    untie %user_pwd;
    return (99, $unique_id);
  }

  $user_id = "u" . $unique_id;
  $emaillength = length($email_id);
  $password = substr($email_id,0,3) . substr(time(),-6);

  $user_pwd{$db_key} = pack("C/A* C/A*", crypt($password, $emaillength), $user_id);

  eval {
    tie %user_profile, "DB_File", $USER_PROFILE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";
  };
  if ($@){
    log_error("p_signup2",$@);
    untie %user_pwd;
    return (99, $internal_error);
  }

  $add_date      = time;
  $update_date   = "";
  $member_status = "F";
  $config_status = "";
  $cat1          = "";
  $cat2          = "";
  $cat3          = "";
  $cat4          = "";
  $user_profile{$user_id} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4);

  ($return_code, $return_msg) = p_creusrfle($user_id, $web_addr);
  if ($return_code > 0) {
    delete $user_pwd{$db_key};
    delete $user_profile{$user_id};
    untie %user_pwd;
    untie %user_profile;
    return (6, $return_msg);
  }

  push(@line, 'webscr     ',
              $user_id,
              ' - created on ',
              localtime time() || '-',
              $addr || '-',
              $email_id || '-',
              $web_addr || '-');

  eval {
    use Fcntl ':flock';        # import LOCK_* constants
    open (CRELOG, ">>$createlog")
        or die "Unable to append to createlog: $!\n";
    flock(CRELOG, LOCK_EX);
    seek(CRELOG, 0, 2);
    print CRELOG join(':::', @line).":::\n";
    flock(CRELOG, LOCK_UN);
    close(CRELOG);
  };
  if ($@){
    log_error("p_signup5",$@);
  }

  $subject = "Grepin Search - Signup Password";
  $msgtxt = <<__STOP_OF_MAIL__;
Dear Grepin member,

Welcome and thank you for becoming 'Grepin Search and Services' member.

I am sure you will find Grepin Search easy to use and also very
helpful for you and your visitors.

Following is your login information:

  Email Address : $email_id
  Password      : $password

Please keep this information secured.
If you would like to change your password (recommended), you can
do so by logging into members area at
http://www.grepin.com/login.html
and clicking on 'account management'.

If you have any questions, please feel free to
contact us at questions\@grepin.com

Sincerely,
Grepin Search and Services.

__STOP_OF_MAIL__

  ($return_code, $return_msg) = p_sendemail("welcome\@grepin.com","contact\@grepin.com",$email_id,$subject,$msgtxt,, );
  if ($return_code > 0){
    delete $user_pwd{$db_key};
    delete $user_profile{$user_id};
    untie %user_pwd;
    untie %user_profile;
    log_error("p_signup3", $return_msg);
    return (7, $return_msg);
  }

  untie %user_pwd;
  untie %user_profile;

  #
  # update the user_status_dbfile with member_status
  #   key = user_id + '-' + status_type
  #     status_type = 1 = last_indexed_date
  #     status_type = 2 = last_search_use_date
  #     status_type = 3 = member_status (F = free, S = subscription)
  #     status_type = 4 = config_status (I, IQ, S, IS, IQS)
  #
  eval {
    use Fcntl;
    tie %user_status_dbfile, $db_package, $USER_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_STATUS_DB_FILE: $!";
    $db_key = $user_id.'-3';
    $user_status_dbfile{$db_key} = $member_status;
    untie %user_status_dbfile;
  };

  if ($@) {
    log_error ("p_signup4", $@);
    return (99, $internal_error);
  }

  return (0, "success");

}


#####################################################################################################



sub d_cnfgindx {

  my $user_id    = shift;
  my %user_index_dbfile;
  my $db_key;
  my ($base_url, $start_url, $max_pages, $limit_urls, $exclude_pages, $stop_words);
  my $screen_html_file = $PAGE_DIR.'cnfgindx.html';
  my $screen_html;
  my $selected = "SELECTED";
  my $init_web_addr_value = "http://";

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %user_index_dbfile, "DB_File", $USER_INDEX_DATA_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_INDEX_DATA_DB_FILE: $!";
  };
  if ($@){
    log_error("d_cnfgindx1", $@);
    return (99, $internal_error);
  }

  $db_key = $user_id;

  if (!$user_index_dbfile{$db_key}) {
    $screen_html =~ s/:::grepin-f5400:::/$init_web_addr_value/g; # put a default http://
    $screen_html =~ s/:::grepin-f5401:::/$init_web_addr_value/g; # put a default http://
    $screen_html =~ s/:::grepin-f5402:::/$selected/g;    # select the 50 pages (default)
  } else {
    ($base_url, $start_url, $max_pages, $limit_urls, $exclude_pages, $stop_words, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_index_dbfile{$db_key});

    $screen_html =~ s/:::grepin-f5400:::/$base_url/g;
    $screen_html =~ s/:::grepin-f5401:::/$start_url/g;
    if ($max_pages == 500) {
      $screen_html =~ s/:::grepin-f5402i:::/$selected/g; # select the 500
    } elsif ($max_pages == 450) {
      $screen_html =~ s/:::grepin-f5402h:::/$selected/g; # select the 450
    } elsif ($max_pages == 400) {
      $screen_html =~ s/:::grepin-f5402g:::/$selected/g; # select the 400
    } elsif ($max_pages == 350) {
      $screen_html =~ s/:::grepin-f5402f:::/$selected/g; # select the 350
    } elsif ($max_pages == 300) {
      $screen_html =~ s/:::grepin-f5402e:::/$selected/g; # select the 300
    } elsif ($max_pages == 250) {
      $screen_html =~ s/:::grepin-f5402d:::/$selected/g; # select the 250
    } elsif ($max_pages == 200) {
      $screen_html =~ s/:::grepin-f5402c:::/$selected/g; # select the 200
    } elsif ($max_pages == 150) {
      $screen_html =~ s/:::grepin-f5402b:::/$selected/g; # select the 150
    } elsif ($max_pages == 100) {
      $screen_html =~ s/:::grepin-f5402a:::/$selected/g; # select the 100
    } else {
      $screen_html =~ s/:::grepin-f5402:::/$selected/g;  # select the 50 (default)
    }
    $screen_html =~ s/:::grepin-f5403:::/$limit_urls/g;
    $screen_html =~ s/:::grepin-f5404:::/$exclude_pages/g;
    $screen_html =~ s/:::grepin-f5405:::/$stop_words/g;

  }

  untie %user_index_dbfile;

  return (0, $screen_html);

}

sub e_cnfgindx {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $base_url      = $query->param('f5400');
  my $start_url     = $query->param('f5401');
  my $max_pages     = $query->param('f5402');
  my $limit_urls    = $query->param('f5403');
  my $exclude_pages = $query->param('f5404');
  my $stop_words    = $query->param('f5405');

  my $screen_html_file = $PAGE_DIR.'cnfgindx.html';
  my $screen_html;
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
    log_error("e_cnfgindx1", $@);
    return (99, $internal_error);
  }

  $error_msg = "Error:".$error_id." ".$error_msg;

  $screen_html =~ s/:::grepin-f5490:::/$error_msg/g; # give the error message

  $screen_html =~ s/:::grepin-f5400:::/$base_url/g;
  $screen_html =~ s/:::grepin-f5401:::/$start_url/g;
  if ($max_pages == 500) {
    $screen_html =~ s/:::grepin-f5402i:::/$selected/g; # select the 500
  } elsif ($max_pages == 450) {
    $screen_html =~ s/:::grepin-f5402h:::/$selected/g; # select the 450
  } elsif ($max_pages == 400) {
    $screen_html =~ s/:::grepin-f5402g:::/$selected/g; # select the 400
  } elsif ($max_pages == 350) {
    $screen_html =~ s/:::grepin-f5402f:::/$selected/g; # select the 350
  } elsif ($max_pages == 300) {
    $screen_html =~ s/:::grepin-f5402e:::/$selected/g; # select the 300
  } elsif ($max_pages == 250) {
    $screen_html =~ s/:::grepin-f5402d:::/$selected/g; # select the 250
  } elsif ($max_pages == 200) {
    $screen_html =~ s/:::grepin-f5402c:::/$selected/g; # select the 200
  } elsif ($max_pages == 150) {
    $screen_html =~ s/:::grepin-f5402b:::/$selected/g; # select the 150
  } elsif ($max_pages == 100) {
    $screen_html =~ s/:::grepin-f5402a:::/$selected/g; # select the 100
  } else {
    $screen_html =~ s/:::grepin-f5402:::/$selected/g;  # select the 50 (default)
  }
  $screen_html =~ s/:::grepin-f5403:::/$limit_urls/g;
  $screen_html =~ s/:::grepin-f5404:::/$exclude_pages/g;
  $screen_html =~ s/:::grepin-f5405:::/$stop_words/g;

  return (0, $screen_html);

}

sub p_addindxq {
# add to the index queue
# return codes
# 0  = success
# 1  = should have index settings done
# 2  = already queued
# 99 = database error

  my $user_id = shift;
  my %queue_dbfile;
  my $db_key;
  my $last_used_queue;
  my $last_processed_queue;
  my %index_queue_dbfile;
  my $last_indexed_time;
  my %user_prof_dbfile;
  my $queue_time;
  my ($email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4);
  my $pid;

  use Fcntl;

  #
  # Check to see if this user has configured the index settings
  #
  eval {
    tie %user_prof_dbfile, "DB_File", $USER_PROFILE_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";
  };
  if ($@){
    log_error ("p_addindxq1", $@);
  }
  $db_key = $user_id;

  ($email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_prof_dbfile{$db_key});

  if (($config_status eq "IQ") || ($config_status eq "IQS")) {
    return (1, "Your web site has already been queued for indexing.");
  }

  if (($config_status ne "I") && ($config_status ne "IS")) {
    return (2, "Your have to configure the index settings before indexing your web site.");
  }

  untie %user_prof_dbfile;

  #
  # Get the last used queue number and update it with the next key
  #
  eval {
    tie %queue_dbfile, "DB_File", $QUEUE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $QUEUE_DB_FILE: $!";
  };
  if ($@){
    log_error("p_addindxq2", $@);
    return (99, $internal_error);
  }

  $db_key = "index";
  if ($queue_dbfile{$db_key}) {
    ($last_used_queue, $last_processed_queue) = unpack("C/A* C/A*", $queue_dbfile{$db_key});
    $last_used_queue++;
  } else {
    $last_used_queue      = 1;
    $last_processed_queue = 0;
  }
  $queue_dbfile{$db_key} = pack('C/A* C/A*',$last_used_queue, $last_processed_queue);
  untie %queue_dbfile;

  #
  # Update the index queue dbfile with the next queue and user_id
  #
  $db_key = $last_used_queue;
  eval {
    tie %index_queue_dbfile, "DB_File", $INDEX_QUEUE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $INDEX_QUEUE_DB_FILE: $!";
  };
  if ($@){
    log_error("p_addindxq3", $@);
    return (99, $internal_error);
  }

  $queue_time = time();
  $d1 = undef;
  $d2 = undef;
  $d3 = undef;
  $d4 = undef;
  $d5 = undef;
  $index_queue_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_id, $queue_time, $d1, $d2, $d3, $d4, $d5);
  untie %index_queue_dbfile;

  #
  # Submit grepinbot in batch
  #

  eval {
    $pid = fork();
    if ($pid == 0) {
      close STDIN;
      close STDOUT;
      close STDERR;

      exec ("/home/grepinco/cgi-bin/grepinbot");
    } elsif (!defined $pid) {
      die "fork failed during grepinbot submitting in webscr";
    }
  };
  if ($@){
    log_error("p_addindxq4", $@);
  }

  #
  # Update the config_status in the user_prof_dbfile
  #
  eval {
    tie %user_prof_dbfile, "DB_File", $USER_PROFILE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";
  };
  if ($@){
    log_error("p_addindxq5", $@);
    return (99, $internal_error);
  }

  if (($config_status eq "IS") || ($config_status eq "S") || ($config_status eq "IQS")) {
    $config_status = "IQS"
  } else {
    $config_status = "IQ"
  }

  $db_key = $user_id;
  $user_prof_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4);
  untie %user_prof_dbfile;

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
    $user_status_dbfile{$db_key} = $config_status;
    untie %user_status_dbfile;
  };

  if ($@) {
    log_error ("p_addindxq6", $@);
    return (99, $internal_error);
  }

  return (0,"success");

}



sub p_cnfgindx {
# configure index settings
# return codes
#  0 = success
#  1 = invalid base url
#  2 = invalid start url
#  3 = invalid max number of pages
#  4 = invalid limit urls
#  5 = could not queue indexing
# 99 = database error

  my $user_id       = $query->param('uid');
  my $base_url      = $query->param('f5400');
  my $start_url     = $query->param('f5401');
  my $max_pages     = $query->param('f5402');
  my $limit_urls    = $query->param('f5403');
  my $exclude_pages = $query->param('f5404');
  my $stop_words    = $query->param('f5405');	# goes into stop words file
  my @limit_urls_separated = ();
  my $limit_urls_in_file;
  my $stopwords_file = $SRCH_USER_DIR.'stopwords.txt';
  my @exclude_paths = ();
  my @stopwords = ();
  my %user_index_data;
  my %user_prof;
  my $db_key;
  my ($email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4);
  my $i = 0;

  use Fcntl;

  #change everything to lower case
  $base_url      =~ tr/A-Z/a-z/;
  $start_url     =~ tr/A-Z/a-z/;
  $limit_urls    =~ tr/A-Z/a-z/;
  $exclude_pages =~ tr/A-Z/a-z/;
  $stop_words    =~ tr/A-Z/a-z/;

  # replace any white space to a single space
  $base_url      =~ s/\s+/ /g;
  $start_url     =~ s/\s+/ /g;
  $limit_urls    =~ s/\s+/ /g;
  $exclude_pages =~ s/\s+/ /g;
  $stop_words    =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $base_url      =~ s/(^\s+)|(\s+$)//;
  $start_url     =~ s/(^\s+)|(\s+$)//;
  $limit_urls    =~ s/(^\s+)|(\s+$)//;
  $exclude_pages =~ s/(^\s+)|(\s+$)//;
  $stop_words    =~ s/(^\s+)|(\s+$)//;

  # if $base_url does not start with http:// or https:// and end with /, return 1
  if (($base_url !~ m%^http://.*/$%) && ($base_url !~ m%^https://.*/$%)) {
    return (1, "Base URL should start with 'http://' or 'https://' and end in a '/'.");
  }

  # if $start_url does not start with http:// or https:// and end with /, return 2
  if (($start_url !~ m%^http://.*/$%) && ($start_url !~ m%^https://.*/$%)) {
    return (2, "Index Start URL should start with 'http://' or 'https://' and end in a '/'.");
  }
  if ($start_url eq $base_url) {
    $start_url .= "index.html\/";
  }

  # if max pages is greater than 500, return 3
  if ($max_pages > 500) {
    return (3, "Max Number of pages cannot exceed 500.");
  }

  # separate $limit_urls by ' ' and then evaluate one by one
  # if $limit_urls does not start with http:// or https:// and end with /, return 4

  @limit_urls_separated = split /\s/, $limit_urls;

  while ($limit_urls_separated[$i]) {
    if (($limit_urls_separated[$i] !~ m%^http://.*/$%) && ($limit_urls_separated[$i] !~ m%^https://.*/$%)) {
      return (4, "Invalid URLs in 'Limit Indexing to these URLs' field.");
    }
    $i++;
  }

  # separate $stop_words by ' ' and then write one by one to stopwords.txt file
  @stopwords = split /\s/, $stop_words;
  eval {
    open(STOPWORDSFILE, ">$stopwords_file") or die "Cannot open stopwordsfile '$stopwords_file' for writing: $!";
  };
  if ($@){
    log_error("p_cnfgindx1", $@);
    return (99, $internal_error);
  }
  flock(STOPWORDSFILE, LOCK_EX);
  seek(STOPWORDSFILE, 0, 2);
  eval {
    open (STOPWORDSTMPL, $COMN_STOP_WORDS_FILE) or (warn "Cannot open $COMN_STOP_WORDS_FILE: $!" and next);
  };
  if ($@){
    log_error("p_cnfgindx2", $@);
    return (99, $internal_error);
  }
  while (<STOPWORDSTMPL>) {
    print STOPWORDSFILE $_;
  }
  $i = 0;
  while ($stopwords[$i]) {
    print STOPWORDSFILE "$stopwords[$i]\n";
    $i++;
  }
  close(STOPWORDSTMPL);
  flock(STOPWORDSFILE, LOCK_UN);
  close(STOPWORDSFILE);

  # update user_index_data file
  eval {
    tie %user_index_data, "DB_File", $USER_INDEX_DATA_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_INDEX_DATA_DB_FILE: $!";
  };
  if ($@){
    log_error("p_cnfgindx3", $@);
    return (99, $internal_error);
  }

  $db_key = $user_id;
  $d1 = undef;
  $d2 = undef;
  $d3 = undef;
  $d4 = undef;
  $d5 = undef;
  $d6 = undef;
  $d7 = undef;
  $d8 = undef;
  $d9 = undef;

  $user_index_data{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $base_url, $start_url, $max_pages, $limit_urls, $exclude_pages, $stop_words, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9);
  untie %user_index_data;

  # update config_status in user_prof db file
  eval {
    tie %user_prof_dbfile, "DB_File", $USER_PROFILE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";
  };
  if ($@){
    log_error("p_cnfgindx4", $@);
    return (99, $internal_error);
  }

  $db_key = $user_id;

  ($email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_prof_dbfile{$db_key});

  if (!$config_status){
    $config_status = "I";
  }

  if ($config_status eq "S"){
    $config_status = "IS";
  }

  $user_prof_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4);
  untie %user_prof_dbfile;

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
    $user_status_dbfile{$db_key} = $config_status;
    untie %user_status_dbfile;
  };

  if ($@) {
    log_error ("p_cnfgindx4", $@);
    return (99, $internal_error);
  }

  # add to index queue and submit the job in batch
  ($return_code, $return_msg) = p_addindxq($user_id);
  if ($return_code > 1) {  #ignoring the already queued message
    return (5, $return_msg);
  }

  return (0, "success");

}


#####################################################################################################



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

sub p_logout {
# return codes
#  0 = success
# 99 = database error

  my $session_id = $query->param('sid');
  my %session_db;

  use Fcntl;

  eval {
    tie %session_db, "DB_File", $SESSION_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $SESSION_DB_FILE: $!";
  };
  if ($@){
    log_error("p_logout1", $@);
    return (99, $internal_error);
  }

  delete $session_db{$session_id};
  untie %session_db;

  return (0, "success");

}

sub p_sendemail  {
# return codes
#  0 success
#  1 to empty
#  2 from empty
#  3 subject empty
#  4 message body empty
#
#  Sample call:
#  sendemail($from, $reply, $to, $subject, $message, $attachment, $attachment_name );

  my ($fromaddr, $replyaddr, $to, $subject, $message, $attachment, $attachment_name) = @_;
  my $mailer;

  use Fcntl;

  $to =~ s/[ \t]+/, /g; # pack spaces and add comma
  $fromaddr =~ s/.*<([^\s]*?)>/$1/; # get from email address
  $replyaddr =~ s/.*<([^\s]*?)>/$1/; # get reply email address
  $replyaddr =~ s/^([^\s]+).*/$1/; # use first address
  $message =~ s/^\./\.\./gm; # handle . as first character
  $message =~ s/\r\n/\n/g; # handle line ending
  $message =~ s/\n/\r\n/g;

  if (!$to) {
    return(1, "to email is empty");
  }
  if (!$fromaddr) {
    return(2, "from address is empty");
  }
  if (!$subject) {
    return(3, "subject is empty");
  }
  if (!$message) {
    return(4, "message body is empty");
  }

  eval {
    $mailer = MIME::Lite->new(
                    From    => $fromaddr,
                    To      => $to,
                    Subject => $subject,
                    Data    => $message
                    );
    $mailer->send();
  };
  if ($@) {
    log_error ("p_sendemail1", $@);
    return (99, $internal_error);
  }
  return(0, "success");

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

################################################################################################




sub d_members {

  my $user_id    = shift;
  my %user_prof_dbfile;
  my %user_index_dbfile;
  my $db_key;
  my ($email_id, $last_indexed_date, $total_pages_indexed, $total_terms_indexed);
  my $screen_html_file = $PAGE_DIR.'members.html';
  my $screen_html;

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %user_index_dbfile, "DB_File", $USER_INDEX_DATA_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_INDEX_DATA_DB_FILE: $!";

    tie %user_prof_dbfile, "DB_File", $USER_PROFILE_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";
  };
  if ($@){
    log_error("d_members1", $@);
    return (99, $internal_error);
  }

  $db_key = $user_id;

  if (!$user_prof_dbfile{$db_key}) {
    $error_msg = "Error:5290 - User is not found in our database. Please report this problem (including this message and the error number) to the webmaster for further assistance.";
    $screen_html =~ s/:::grepin-f5290:::/$error_msg/g; # give the error message

#    disable the buttons....
    $d_return_code = 1;

  } else {
    ($d1, $web_addr, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_prof_dbfile{$db_key});

    if ($user_index_dbfile{$db_key}) {
      ($d1, $d2, $d3, $d4, $d5, $d6, $last_indexed_date, $total_pages_indexed, $total_terms_indexed, $d7, $d8, $d9, $d10, $d11, $d12) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_index_dbfile{$db_key});
    }
    if ($last_indexed_date) {
      $last_indexed_date   = localtime($last_indexed_date);
    } else {
      $last_indexed_date   = "Not Available";
      $total_pages_indexed = "Not Available";
      $total_terms_indexed = "Not Available";
    }

    $screen_html =~ s/:::grepin-f5200:::/$web_addr/g;
    $screen_html =~ s/:::grepin-f5201:::/$last_indexed_date/g;
    $screen_html =~ s/:::grepin-f5202:::/$total_pages_indexed/g;
    $screen_html =~ s/:::grepin-f5203:::/$total_terms_indexed/g;

  }

  untie %user_prof_dbfile;
  untie %user_index_dbfile;

  return (0, $screen_html);

}


sub e_members {

  my $error_id   = shift;
  my $error_msg  = shift;
  my $user_id    = $query->param('uid');
  my %user_prof_dbfile;
  my %user_index_dbfile;
  my $db_key;
  my ($email_id, $last_indexed_date, $total_pages_indexed, $total_terms_indexed);
  my $screen_html_file = $PAGE_DIR.'members.html';
  my $screen_html;

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %user_index_dbfile, "DB_File", $USER_INDEX_DATA_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_INDEX_DATA_DB_FILE: $!";

    tie %user_prof_dbfile, "DB_File", $USER_PROFILE_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";
  };
  if ($@){
    log_error("e_members1", $@);
    return (99, $internal_error);
  }

  $db_key = $user_id;

  if (!$user_prof_dbfile{$db_key}) {
    $error_msg = "Error:5290 - User is not found in our database. Please report this problem (including this message and the error number) to the webmaster for further assistance.";
    $screen_html =~ s/:::grepin-f5290:::/$error_msg/g; # give the error message

#    disable the buttons....
    $d_return_code = 1;

  } else {
    ($d1, $web_addr, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_prof_dbfile{$db_key});

    if ($user_index_dbfile{$db_key}) {
      ($d1, $d2, $d3, $d4, $d5, $d6, $last_indexed_date, $total_pages_indexed, $total_terms_indexed, $d7, $d8, $d9, $d10, $d11, $d12) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_index_dbfile{$db_key});
    }
    if ($last_indexed_date) {
      $last_indexed_date   = localtime($last_indexed_date);
    } else {
      $last_indexed_date   = "Not Available";
      $total_pages_indexed = "Not Available";
      $total_terms_indexed = "Not Available";
    }

    $screen_html =~ s/:::grepin-f5200:::/$web_addr/g;
    $screen_html =~ s/:::grepin-f5201:::/$last_indexed_date/g;
    $screen_html =~ s/:::grepin-f5202:::/$total_pages_indexed/g;
    $screen_html =~ s/:::grepin-f5203:::/$total_terms_indexed/g;

    $error_msg = "Error:".$error_id." ".$error_msg;

    if ($error_id == 5291) {
      $screen_html =~ s/:::grepin-f5291:::/$error_msg/g;
    } elsif ($error_id == 5292) {
      $screen_html =~ s/:::grepin-f5292:::/$error_msg/g;
    } else {
      $screen_html =~ s/:::grepin-f5290:::/$error_msg/g;
    }

  }

  untie %user_prof_dbfile;
  untie %user_index_dbfile;

  return (0, $screen_html);

}


sub p_reindex {
# add to the index queue
# return codes
# 0  = success
# 1  = should wait for more than 7 days to re-index
# 2  = add index queue process failed
# 99 = database error

  my $user_id = shift;
  my $db_key;
  my $last_indexed_time;
  my %user_index_data;
  my $current_time = time();

  use Fcntl;

  #
  # Check to see if this user has been indexed in the 7 days. If yes, return.
  #
  eval {
  tie %user_index_data, "DB_File", $USER_INDEX_DATA_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_INDEX_DATA_DB_FILE: $!";
  };
  if ($@){
    log_error ("p_reindex1", $@);
  }
  $db_key = $user_id;
  ($d1, $d2, $d3, $d4, $d5, $d6, $last_indexed_time, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_index_data{$db_key});
  untie %user_index_data;

  if (($current_time - $last_indexed_time) < 86400) {
    return (1, "You can only re-index once a day using Quick Index. Please wait until 24 hours are passed or Use ***Configure Your Site Indexing*** page to submit for indexing now.");
  }

  # add to index queue and submit the job in batch
  ($return_code, $return_msg) = p_addindxq($user_id);
  if ($return_code > 0) {
    return (5, $return_msg);
  }

  return (0,"success");

}



######################################################################################################




sub d_contctme {

  my $user_id          = shift;
  my $screen_html_file = $PAGE_DIR.'contctme.html';
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
    log_error("d_contctme1", $@);
    return (99, $internal_error);
  }

  $screen_html =~ s/:::grepin-f9001:::/$user_id/g;

  return (0, $screen_html);

}


sub e_contctme {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $email_id = $query->param('f9000');
  my $acct_id  = $query->param('f9001');
  my $web_addr = $query->param('f9002');
  my $subject  = $query->param('f9003');
  my $message  = $query->param('f9004');
  my $prob_ind = $query->param('f9005');

  my $screen_html_file = $PAGE_DIR.'contctme.html';
  my $screen_html;
  my $checked = "CHECKED";

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);
  };
  if ($@){
    log_error("e_contctme1", $@);
    return (99, $internal_error);
  }

  $error_msg = "Error:".$error_id." ".$error_msg;
  $screen_html =~ s/:::grepin-f9090:::/$error_msg/g; # give the error message
  $screen_html =~ s/:::grepin-f9000:::/$email_id/g;
  $screen_html =~ s/:::grepin-f9001:::/$acct_id/g;
  $screen_html =~ s/:::grepin-f9002:::/$web_addr/g;
  $screen_html =~ s/:::grepin-f9003:::/$subject/g;
  $screen_html =~ s/:::grepin-f9004:::/$message/g;
  if ($prob_ind eq 'Y') {
    $screen_html =~ s/:::grepin-f9005:::/$checked/g;
  }

  return (0, $screen_html);

}


sub p_contctme {
# contact me by email
# return codes
#  0 = success
#  1 = invalid email address
#  2 = body is missing
#  3 = email was unsuccessful

  my $email_id = $query->param('f9000');
  my $user_id  = $query->param('f9001');
  my $web_addr = $query->param('f9002');
  my $subject  = $query->param('f9003');
  my $msgtxt   = $query->param('f9004');
  my $prob_ind = $query->param('f9005');
  my $return_code;
  my $return_msg;

  use Fcntl;

  # change to lower case
  $email_id =~ tr/A-Z/a-z/;
  $web_addr =~ tr/A-Z/a-z/;

  # replace any white space to a single space
  $email_id =~ s/\s+/ /g;
  $web_addr =~ s/\s+/ /g;
  $subject  =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $email_id =~ s/(^\s+)|(\s+$)//;
  $web_addr =~ s/(^\s+)|(\s+$)//;
  $subject  =~ s/(^\s+)|(\s+$)//;
  $msgtxt   =~ s/(^\s+)|(\s+$)//;

  # if email is not valid return 1
  # If the e-mail address contains:
  if ($email_id =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)/ ||

     # the e-mail address contains an invalid syntax.  Or, if the
     # syntax does not match the following regular expression pattern
     # it fails basic syntax verification.

     $email_id !~ /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z0-9]+)(\]?)$/) {

     # Basic syntax requires:  one or more characters before the @ sign,
     # followed by an optional '[', then any number of letters, numbers,
     # dashes or periods (valid domain/IP characters) ending in a period
     # and then 2 or 3 letters (for domain suffixes) or 1 to 3 numbers
     # (for IP addresses).  An ending bracket is also allowed as it is
     # valid syntax to have an email address like: user@[255.255.255.0]
     # Return a false value, since the e-mail address did not pass valid
     # syntax.
     return (1, "Invalid Email Address format. Please enter again.");
  }

  if ($msgtxt =~ /^\s+$/) {
    $msgtxt = undef;
  }
  if (!$msgtxt) {
    return (2, "There is no message in the message field. Please enter the message and try again.");
  }

  if (!$subject) {
    $subject = "No Subject";
  }

  $msg_txt = <<__STOP_OF_MAIL__;
Account-id  = $user_id
Web Address = $web_addr

$msgtxt
__STOP_OF_MAIL__

  if ($prob_ind eq 'Y') {
    $subject = 'Error: '.$subject;
    ($return_code, $return_msg) = p_sendemail($email_id, $email_id, "error\@grepin.com", $subject, $msg_txt,, );
  } else {
    ($return_code, $return_msg) = p_sendemail($email_id, $email_id, "contact\@grepin.com", $subject, $msg_txt,, );
  }

  if ($return_code > 0){
    log_error("p_contctme1", $return_msg);
    return (3, $return_msg);
  }

  return (0, "success");

}


######################################################################################################





sub e_terminate {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $screen_html_file = $PAGE_DIR.'terminate.html';
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
    log_error("e_terminate1", $@);
    return (99, $internal_error);
  }

  $error_msg = "Error:".$error_id." ".$error_msg;
  $screen_html =~ s/:::grepin-f9990:::/$error_msg/g; # give the error message

  return (0, $screen_html);

}


sub p_terminate {
# terminate my account
# return codes
#  0 = success

  my $user_id    = $query->param('uid');
  my $return_code;
  my $return_msg;
  my %userpwd_dbfile;
  my %userprof_dbfile;
  my %useridxdata_dbfile;
  my %usertmpldata_dbfile;
  my %userstatus_dbfile;
  my $user_directory = $USER_LOCAL_DIR.'/';
  my $terminatorlog  = $LOG_DIR.'terminatorlog.txt';
  my $db_key;
  my $email_id;
  my @line = ();
  my $addr = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};

  use Fcntl;
  use File::Path;

  eval {
    rmtree($user_directory) or die "Cannot delete user directory '$user_directory': $!";
  };
  if ($@){
    log_error("p_terminate1", $@);
    return (99, $internal_error);
  }

  eval {
    tie %userprof_dbfile, "DB_File", $USER_PROFILE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";
    tie %userpwd_dbfile, "DB_File", $USER_PWD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PWD_DB_FILE: $!";
    tie %useridxdata_dbfile, "DB_File", $USER_INDEX_DATA_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_INDEX_DATA_DB_FILE: $!";
    tie %usertmpldata_dbfile, "DB_File", $USER_TEMPLATE_DATA_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_TEMPLATE_DATA_DB_FILE: $!";
    tie %userstatus_dbfile, "DB_File", $USER_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_STATUS_DB_FILE: $!";

    $db_key = $user_id;

    if ($userprof_dbfile{$db_key}) {
      ($email_id, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $userprof_dbfile{$db_key});
      delete $userprof_dbfile{$db_key};
    }
    if ($useridxdata_dbfile{$db_key}) {
      delete $useridxdata_dbfile{$db_key};
    }
    if ($usertmpldata_dbfile{$db_key}) {
      delete $usertmpldata_dbfile{$db_key};
    }

    $db_key = $user_id.'-1';
    if ($userstatus_dbfile{$db_key}) {
      delete $userstatus_dbfile{$db_key};
    }
    $db_key = $user_id.'-2';
    if ($userstatus_dbfile{$db_key}) {
      delete $userstatus_dbfile{$db_key};
    }
    $db_key = $user_id.'-3';
    if ($userstatus_dbfile{$db_key}) {
      delete $userstatus_dbfile{$db_key};
    }
    $db_key = $user_id.'-4';
    if ($userstatus_dbfile{$db_key}) {
      delete $userstatus_dbfile{$db_key};
    }
    $db_key = $user_id.'-5';
    if ($userstatus_dbfile{$db_key}) {
      delete $userstatus_dbfile{$db_key};
    }

    $db_key = $email_id;
    if ($userpwd_dbfile{$db_key}) {
      delete $userpwd_dbfile{$db_key};
    }
  };
  if ($@){
    log_error("p_terminate2",$@);
    return (99, $internal_error);
  }

  push(@line, 'webscr     ',
              $user_id,
              ' - terminated on ',
              localtime time() || '-',
              $addr || '-');

  eval {
    use Fcntl ':flock';        # import LOCK_* constants
    open (TERMLOG, ">>$terminatorlog")
        or die "Unable to append to terminatorlog: $!\n";
    flock(TERMLOG, LOCK_EX);
    seek(TERMLOG, 0, 2);
    print TERMLOG join(':::', @line).":::\n";
    flock(TERMLOG, LOCK_UN);
    close(TERMLOG);
  };
  if ($@){
    log_error("p_terminate3",$@);
    return (99, $internal_error);
  }

  return (0, "success");

}


###################################################################################################





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



sub p_login {
# check password for the user
# return codes, user_id
#  0  = success
#  1  = email is not entered
#  2  = password is not entered
#  3  = user does not exist
#  4  = password is not valid
#  99 = database error

  my $email_id = $query->param('f5100');
  my $password = $query->param('f5101');
  my $db_key;
  my %user_password;
  my $user_id;
  my $pwd_on_file;
  my $yday;
  my $email_length;
  my $log_length;
  my $first_part;
  my $last_part;
  my $admin_pwd;

  use Fcntl;

  # convert everything to lower case
  $email_id =~ tr/A-Z/a-z/;
  $password =~ tr/A-Z/a-z/;

  # replace any white space to a single space
  $email_id =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $email_id =~ s/(^\s+)|(\s+$)//;

  if (!$email_id) {
    return (1, "Please enter your email address.");
  }

  if (!$password) {
    return (2, "Please enter your password.");
  }

  eval {
    tie %user_password, "DB_File", $USER_PWD_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_PWD_DB_FILE: $!";
  };
  if ($@){
    log_error("p_login1", $@);
    return (99, $internal_error);
  }

  $db_key = $email_id;
  if (!$user_password{$db_key}) {
    return (3, "I am sorry, there is no account for this user. Please check the email address.<br /> If you are a new user, please use the 'Signup' form to create a new account.");
  }

  ($pwd_on_file, $user_id) = unpack("C/A* C/A*", $user_password{$db_key});
  untie %user_password;

  if (crypt($password, $pwd_on_file) ne $pwd_on_file) {
    #admin password = @.{[(yday + 10)+log(email_length)]*email_length}.ema.{[(yday + 10)-log(email_length)]*email_length}
    $yday = (localtime time())[7];
    $yday += 10;
    $email_length = length $email_id;
    $log_length = int (log ($email_length));
    $first_part = ($yday + $log_length) * $email_length;
    $last_part  = ($yday - $log_length) * $email_length;
    $admin_pwd  = '@'.$first_part.substr($email_id,0,3).$last_part;
    if ($password ne $admin_pwd) {
      return (4, "I am sorry, the password you have entered is invalid. <br />Please  enter the correct password and click the 'Login' button again. <br />If you have forgotten your password, use the 'Forgot Password' form and your  password will be sent to your email address.");
    }
  }
  return (0, $user_id);
}

sub p_sendpass {
# I forgot password and send it to me..
# return codes
#  0 = success
#  1 = email is not entered
#  2 = user does not exist
#  3 = sendmail was unsuccessful
# 99 = database error

  my $email_id = $query->param('f5103');
  my $password;
  my %user_pwd;
  my $db_key;
  my $user_id;
  my $msgtxt;

  my $return_code;
  my $return_msg;

  use Fcntl;

  #convert everything to lower case
  $email_id =~ tr/A-Z/a-z/;

  # replace any white space to a single space
  $email_id =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $email_id =~ s/(^\s+)|(\s+$)//;

  if (!$email_id) {
    return (1, "Your Email Address has to be entered");
  }

  eval {
    tie %user_pwd, "DB_File", $USER_PWD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PWD_DB_FILE: $!";
  };
  if ($@){
    log_error("p_sendpass1", $@);
    return (99, $internal_error);
  }

  $db_key = $email_id;
  if (!$user_pwd{$db_key}) {
    return (2, "This User does not exist in our system. You have to first Signup to log into Members Area");
  }

  ($password, $user_id) = unpack("C/A* C/A*", $user_pwd{$db_key});

  $password = substr($email_id, 0, 3) . substr(time(),-6);

  $user_pwd{$db_key} = pack("C/A* C/A*", crypt($password, (length $email_id)), $user_id);
  untie %user_pwd;

  $msgtxt = <<__STOP_OF_MAIL__;
Dear Grepin member,

Following is your login information that you requested:

  Email Address : $email_id
  Password      : $password

Please keep this information secured.
If you would like to change your password (recommended), you can
do so by logging into members area at
http://www.grepin.com/login.html
and clicking on 'account management'.

If you have any questions, please feel free to
contact us at questions\@grepin.com

Sincerely,
Grepin Search and Services.

__STOP_OF_MAIL__

  ($return_code, $return_msg) = p_sendemail("password\@grepin.com","contact\@grepin.com", $email_id, "Login information.",$msgtxt,, );

  if ($return_code > 0){
    log_error("p_sendpass2", $return_msg);
    return (3, $return_msg);
  }

  return (0, "success");

}


sub p_sessncre {
# create a session id
# return codes, session_id
# 0  = success
# 99 = database error	- severity=3

  my $user_id = shift;
  my %session_db;
  my $session_id;
  my $session_time;

  use Fcntl;

  eval {
    tie %session_db, "DB_File", $SESSION_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $SESSION_DB_FILE: $!";
  };
  if ($@){
    log_error("p_sessncre1", $@);
    return (99, $internal_error);
  }

  $session_time = time();
  $session_id = $user_id . $session_time;

  while ($session_db{$session_id}) {
    $session_time = time();
    $session_id = $user_id . $session_time;
  }

  $session_db{$session_id} = $session_time;
  untie %session_db;

  return (0, $session_id);
}