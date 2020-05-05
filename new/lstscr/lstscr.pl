#!/usr/bin/perl -w

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
#   use CGI::Carp qw(carpout);
#   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/lstscrerr.txt")
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

  my $MAIN_DIR = '/home/grepinco/public_html/cgi-bin/';
  my $PAGE_DIR = $MAIN_DIR.'pages/';
  my $USER_DIR = $MAIN_DIR.'users/';

  my $LOG_DIR    = $MAIN_DIR.'log/';
  my $LOG_FILE   = $LOG_DIR.'lstscrlog.txt';
  my $LOG_SOURCE = $LOG_DIR.'sourcelog.txt';

  my $SESSION_DB_FILE            = $USER_DIR.'session';
  my $PWRLST_DB_FILE           = $USER_DIR.'pwrlst';

  ########################################

  my $cmd        = $query->param('cmd');
  my $session_id = $query->param('sid');
  my $user_id    = $query->param('uid');

  my $USER_LOCAL_DIR           = $MAIN_DIR.$user_id.'/';
  my $PROD_USER_DIR            = $USER_LOCAL_DIR.'products/';
  my $PROD_PROF_DB_FILE        = $PROD_USER_DIR.'profile';
  my $PROD_THEME_DB_FILE       = $PROD_USER_DIR.'theme';
  my $PROD_KEYWORD_DB_FILE     = $PROD_USER_DIR.'prdkwd';
  my $KEYWORD_DB_FILE          = $PROD_USER_DIR.'keyword';

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
    push(@line, 'lstscr ------------- ',
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
    log_error("lstscr1", "The DB_File module was not found.");
    print "$internal_error \n\n";
    exit;
  }

####  DO NOT CALL ANY SUB-PROGRAM UNTIL THIS POINT ########


  if (!$cmd) {
    $cmd = "home";
  }


  if ($session_id) {
    if ($cmd eq "login") {
      ($return_code, $return_msg) = p_logout();
      $user_id    = undef;
      $session_id = undef;
    } else {
      ($return_code, $return_msg) = p_sessnchk();
      if ($return_code != 0) {
        $user_id    = undef;
        $session_id = undef;
        if (($cmd eq "chgpln") || ($cmd eq "subscribe") || ($cmd eq "terminate")) {
          ($return_code, $return_msg) = e_login(5190, $return_msg);
          $valid_sid = 'F';
        }
      }
    }
  } else {
    if (($cmd eq "chgpln") || ($cmd eq "subscribe") || ($cmd eq "terminate")) {
      ($return_code, $return_msg) = e_login(5190, "You have to login as a member to access this page.");
      $user_id = undef;
      $valid_sid = 'F';
    }
  }

  if ($valid_sid eq 'T') {
    if (($cmd eq "choose") || ($cmd eq "chgpln") || ($cmd eq "terminate")) {
      ($return_code, $return_msg) = p_memberchk();
      if ($return_code != 0) {
        $cmd = "home";
      }
    }
    if ($cmd eq "home") {
      ($return_code, $return_msg) = d_static ("prhome");
    } elsif ($cmd eq "features") {
      ($return_code, $return_msg) = d_static ("prfeatures");
    } elsif ($cmd eq "html") {
      ($return_code, $return_msg) = d_static ("prhtml");
    } elsif ($cmd eq "subscribe") {
      ($return_code, $return_msg) = m_subscribe();
    } elsif ($cmd eq "choose") {
      ($return_code, $return_msg) = m_choose();
    } elsif ($cmd eq "chgpln") {
      ($return_code, $return_msg) = m_chgpln();
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


sub m_subscribe {

  check for the user already subscription...

  if he is already subscribed
     direct him to change plan with error that he is already subscribed (dynamic)
  else
     show him the subscription screen (static)


sub m_chgpln {

  check for the user already subscription...

  if he is already subscribed
     direct him to change plan displaying his subscription details (dynamic)
  else
     show him the subscription screen with error that he has no subscription done yet (static)


sub m_choose {

  my $user_id = $query->param('uid');
  my $m_return_code;
  my $m_return_msg;

  ($m_return_code, $m_return_msg) = p_memberchk();
  if ($m_return_code == 0) {
    show him the choose page with user_id (dynamic using the template)
    he can send other parameters like affiliate id, keyword
  } else {
    show him the error page (static but with user-id displayed in error message)
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
    log_error("lstscr2", $@);
    return (99, $internal_error);
  }

  $menu_html =~ s/:::grepin-inner-html:::/$inner_html/g;                 # put the inner screen
  $menu_html =~ s/:::grepin-fld00:::/$user_id/g;                           # user_id
  $menu_html =~ s/:::grepin-fld01:::/$session_id/g;                        # session_id
  $menu_html =~ s/:::grepin-.*::://g;                                      # space out all the other fields

  return (0, $menu_html);

}




###########################################################################################################


sub d_signup {

  my $screen_html_file = $PAGE_DIR.'signup.html';
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
    log_error("d_signup1", $@);
    return (99, $internal_error);
  }

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
  my $USER_SPECIFIC_DIR  = $SRCH_USER_DIR.$user_id;
  my $USER_DATA_DIR      = $USER_SPECIFIC_DIR.'/data';
  my $USER_REPORTS_DIR   = $USER_SPECIFIC_DIR.'/reports';
  my $USER_TEMPL_DIR     = $USER_SPECIFIC_DIR.'/templates';
  my $USER_LOG_DIR       = $USER_SPECIFIC_DIR.'/log';
  my $u_userconf_file    = $USER_SPECIFIC_DIR.'/sub_userconf.pl';
  my $userconf_content;
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

    open (TSRCHPAGE, $COMN_SEARCH_TEMPLATE) or die "Cannot open COMN_SEARCH_TEMPLATE '$COMN_SEARCH_TEMPLATE' for reading: $!";
    while (<TSRCHPAGE>) {
      $$search_content .= $_;
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

  ($return_code, $return_msg) = p_creusrfle($user_id);
  if ($return_code > 0) {
    delete $user_pwd{$db_key};
    delete $user_profile{$user_id};
    untie %user_pwd;
    untie %user_profile;
    return (6, $return_msg);
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
http://www.grepin.com/login/
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
  # update the user_status_dbfile with last_search_use_date 
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


	
######################################################################################



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
  my $user_directory = $SRCH_USER_DIR.$user_id.'/';
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

  push(@line, 'lstscr     ',
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


# d_??? display subprogram
# p_??? process subprogram
# e_??? error display subprogram



sub d_list {

  my %prod_prof_dbfile;
  my $db_key;
  my ($prod_id, $title, $theme, $num_of_keywords);
  my $screen_html_file = $PAGE_DIR.'prlist.html';
  my $screen_html;
  my $prod_count = 0;
  my @list_array = ();
  my @row_array  = ();
  my ($row_html_before, $row_html_after, $row_html_temp);
  my $arrow = "->";

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    foreach $db_key (sort keys %prod_prof_dbfile) {
      ($title, $d1, $d2, $d3, $theme, $num_of_keywords, $d4, $d5, $d6, $d7, $d8) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
      push @list_array, $theme.':::'.$db_key.':::'.$title.':::'.$num_of_keywords;
      $prod_count++;
    }
    untie %prod_prof_dbfile;
  };
  if ($@){
    log_error("d_list1", $@);
    return (99, $internal_error);
  }

  # create match report rows
  $screen_html   =~ /:::grepin-start-row:::.*:::grepin-end-row:::/s;
  $row_html_before = $&;

  $row_html_after = undef;
  if ($prod_count > 0) {
    $i = 0;
    while ($list_array[$i]) {
      @row_array = ();
      @row_array = split /:::/, $list_array[$i];
      $row_html_temp  = $row_html_before;
      $row_html_temp  =~ s/:::grepin-ip000:::/$row_array[1]/g; # product name
      $row_html_temp  =~ s/:::grepin-ip001:::/$row_array[2]/g; # title
      $row_html_temp  =~ s/:::grepin-ip002:::/$row_array[2]/g; # number of keywords
      if ($row_array[0] == 1) {
        $row_html_temp  =~ s/:::grepin-ip009:::/$arrow/g; # theme product indicator
      }
      $row_html_after .= $row_html_temp;
      $i++;
    }
  }

  # substitute values in the page
  $screen_html =~ s/:::grepin-fp001:::/$prod_count/gs;
  $screen_html =~ s/:::grepin-start-row:::.*:::grepin-end-row:::/$row_html_after/gs;
  $screen_html =~ s/(:::grepin-start-row:::)|(:::grepin-end-row:::)//gs;

  return (0, $screen_html);

}



sub e_list {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $prod_id    = $query->param('prd');
  my $e_return_code;

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $prod_id  =~ tr/a-z/A-Z/;
  $prod_id  =~ s/\s+/ /g;
  $prod_id  =~ s/(^\s+)|(\s+$)//;

  ($e_return_code, $screen_html) = d_list();

  if ($e_return_code == 0) {
    $error_msg = "Error:".$error_id." ".$error_msg;
    $screen_html =~ s/:::grepin-fp090:::/$error_msg/g; # give the error message
    $screen_html =~ s/:::grepin-fp000:::/$prod_id/gs;
    return (0, $screen_html);
  } else {
    return ($e_return_code, $screen_html);
  }

}



######################################################################################


sub d_model {

  my $prod_id   = $query->param('prd');
  my %prod_prof_dbfile;
  my $db_key;
  my ($title, $desc, $image_url, $dest_url, $theme, $num_of_keywords);
  my $screen_html_file = $PAGE_DIR.'pradd.html';
  my $screen_html;
  my $checked   = "CHECKED";

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $prod_id  =~ tr/a-z/A-Z/;
  $prod_id  =~ s/\s+/ /g;
  $prod_id  =~ s/(^\s+)|(\s+$)//;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    $db_key = $prod_id;
    if (!$prod_prof_dbfile{$db_key}) {
      untie %prod_prof_dbfile;
      return (1, "Model product - $prod_id - is not found.");
    } else {
      ($title, $desc, $image_url, $dest_url, $theme, $num_of_keywords, $d4, $d5, $d6, $d7, $d8) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
      untie %prod_prof_dbfile;
    }
  };
  if ($@){
    log_error("d_model1", $@);
    return (99, $internal_error);
  }

  $screen_html =~ s/:::grepin-fp101:::/$title/g;
  $screen_html =~ s/:::grepin-fp102:::/$desc/g;
  $screen_html =~ s/:::grepin-fp103:::/$image_url/g;
  $screen_html =~ s/:::grepin-fp104:::/$dest_url/g;
  if ($theme == 1) {
    $screen_html =~ s/:::grepin-fp105a:::/$checked/g; # select the yes 
  } else {
    $screen_html =~ s/:::grepin-fp105:::/$checked/g;  # select the no (default)
  }

  return (0, $screen_html);

}



sub p_add {
# add a new product
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $prod_id   = $query->param('fp100');
  my $title     = $query->param('fp101');
  my $desc      = $query->param('fp102');
  my $image_url = $query->param('fp103');
  my $dest_url  = $query->param('fp104');
  my $theme     = $query->param('fp105');
  my $keywords  = $query->param('fp106');
  my $comments  = $query->param('fp107');
  my $num_of_keywords = 0;
  my $db_key;
  my %prod_prof_dbfile;
  my %theme_dbfile;
  my %prod_keyword_dbfile;
  my %keyword_dbfile;
  my @products = ();

  use Fcntl;

  # convert case
  $prod_id  =~ tr/a-z/A-Z/;
  $keywords =~ tr/A-Z/a-z/;

  # replace any white space to a single space
  $prod_id   =~ s/\s+/ /g;
  $title     =~ s/\s+/ /g;
  $desc      =~ s/\s+/ /g;
  $image_url =~ s/\s+/ /g;
  $dest_url  =~ s/\s+/ /g;
  $keywords  =~ s/\s+/ /g;
  $comments  =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $prod_id   =~ s/(^\s+)|(\s+$)//;
  $title     =~ s/(^\s+)|(\s+$)//;
  $desc      =~ s/(^\s+)|(\s+$)//;
  $image_url =~ s/(^\s+)|(\s+$)//;
  $dest_url  =~ s/(^\s+)|(\s+$)//;
  $keywords  =~ s/(^\s+)|(\s+$)//;
  $comments  =~ s/(^\s+)|(\s+$)//;

  if (!$prod_id) {
    return (1, "Product Name cannot be empty.");
  }

  if ($prod_id !~ /[\dA-Z_]/) {
    return (1, "Product Name has invalid characters. A to Z, numbers and '_' are only allowed.");
  }

  if (!$title) {
    return (1, "Title cannot be empty.");
  }

  if (!$desc) {
    return (1, "Product description cannot be empty.");
  }
  if (length($desc) > 255) {
    return (1, "Product description cannot be more than 255 characters.");
  }

  eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    if ($prod_prof_dbfile{$prod_id}) {
      return (2, "Product already exists with the same name. Please give a different name.");
    }
    untie %prod_prof_dbfile;
  };
  if ($@){
    log_error("p_add1",$@);
    return (99, $internal_error);
  }

  if (!$dest_url) {
    return (1, "Destination URL cannot be empty.");
  }

  @keywords_array = split /','/, $keywords;
  $num_of_keywords = @keywords_array;

  if ($num_of_keywords == 0) {
    return (1, "At least one Keyword should be supplied.");
  }

  foreach (@keywords_array) {
    if ($_ !~ /[\dA-Z_]/) {
      return (1, "Keyword - $_ - has invalid characters. A to Z, numbers and '_' are the only valid characters for a keyword.");
    }
    if (length($_) > 255) {
      return (1, "Keyword - $_ - is too long. Keywords cannot be more than 255 characters.");
    }
  }

  if ($image_url) { 
    if (($image_url !~ m%^http://.*/$%) && ($image_url !~ m%^https://.*/$%)) {
      return (2, "Image URL should start with 'http://' or 'https://' and end with '/'.");
    }
  }

  if (($dest_url !~ m%^http://.*/$%) && ($dest_url !~ m%^https://.*/$%)) {
    return (2, "Destination URL should start with 'http://' or 'https://' and end with '/'.");
  }

  if (($theme != 1) && ($theme != 0)) {
    return (3, "Theme Product indicator should be either 0 or 1.");
  }

  if (length($comments) > 255) {
    return (1, "Comments cannot be more than 255 characters.");
  }

  eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    tie %theme_dbfile, "DB_File", $PROD_THEME_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_THEME_DB_FILE: $!";
    tie %prod_keyword_dbfile, "DB_File", $PROD_KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_KEYWORD_DB_FILE: $!";
    tie %keyword_dbfile, "DB_File", $KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $KEYWORD_DB_FILE: $!";

    $db_key = $prod_id;
    $prod_prof_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $title, $desc, $image_url, $dest_url, $theme, $num_of_keywords, $comments, $d1, $d2, $d3, $d4);
    if ($theme == 1) {
      $theme_dbfile{$db_key} = 1;
    }
    $prod_keyword_dbfile{$db_key} = $keywords;
    $i = 0;

    while ($keywords_array[$i]) {
      @products = ();
      if ($keyword_dbfile{$keywords_array[$i]}) {
        @products = $keyword_dbfile{$keywords_array[$i]};
      }
      push @products, $prod_id;
      $keyword_dbfile{$keywords_array[$i]} = @products;
      $i++;
    }
    untie %prod_prof_dbfile;
    untie %prod_keyword_dbfile;
    untie %theme_dbfile;
    untie %keyword_dbfile;
  };
  if ($@){
    log_error("p_add2",$@);
    return (99, $internal_error);
  }

  return (0, "success");

}


sub e_add {
# add a new product - error
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $error_id   = shift;
  my $error_msg  = shift;

  my $prod_id   = $query->param('fp100');
  my $title     = $query->param('fp101');
  my $desc      = $query->param('fp102');
  my $image_url = $query->param('fp103');
  my $dest_url  = $query->param('fp104');
  my $theme     = $query->param('fp105');
  my $keywords  = $query->param('fp106');
  my $comments  = $query->param('fp107');
  my $checked   = "CHECKED";

  my $screen_html_file = $PAGE_DIR.'pradd.html';
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
    log_error("e_add1", $@);
    return (99, $internal_error);
  }

  #convert product_id to upper case
  $prod_id   =~ tr/a-z/A-Z/;

  #convert keywords to lower case
  $keywords  =~ tr/A-Z/a-z/;

  # replace any white space to a single space
  $prod_id   =~ s/\s+/ /g;
  $title     =~ s/\s+/ /g;
  $desc      =~ s/\s+/ /g;
  $image_url =~ s/\s+/ /g;
  $dest_url  =~ s/\s+/ /g;
  $keywords  =~ s/\s+/ /g;
  $comments  =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $prod_id   =~ s/(^\s+)|(\s+$)//;
  $title     =~ s/(^\s+)|(\s+$)//;
  $desc      =~ s/(^\s+)|(\s+$)//;
  $image_url =~ s/(^\s+)|(\s+$)//;
  $dest_url  =~ s/(^\s+)|(\s+$)//;
  $keywords  =~ s/(^\s+)|(\s+$)//;
  $comments  =~ s/(^\s+)|(\s+$)//;

  if ($error_msg eq "success") {
    $error_msg = "The product - $prod_id - has been successfully added.";
    $prod_id = undef;
    $comments = undef;
  } elsif ($error_msg eq "not found") {
    $prod_id = $query->param('prd');
    $prod_id =~ tr/a-z/A-Z/;
    $error_msg = "The product - $prod_id - is not found. You can use this form to add a new product.";
  } else {
    $error_msg = "Error:".$error_id." ".$error_msg;
  }

  $screen_html =~ s/:::grepin-fp190:::/$error_msg/g; # give the error message
  $screen_html =~ s/:::grepin-fp100:::/$prod_id/g;
  $screen_html =~ s/:::grepin-fp101:::/$title/g;
  $screen_html =~ s/:::grepin-fp102:::/$desc/g;
  $screen_html =~ s/:::grepin-fp103:::/$image_url/g;
  $screen_html =~ s/:::grepin-fp104:::/$dest_url/g;
  if ($theme == 1) {
    $screen_html =~ s/:::grepin-fp105a:::/$checked/g; # select the yes 
  } else {
    $screen_html =~ s/:::grepin-fp105:::/$checked/g;  # select the no (default)
  }
  $screen_html =~ s/:::grepin-fp106:::/$keywords/g;
  $screen_html =~ s/:::grepin-fp107:::/$comments/g;

  return (0, $screen_html);

}



sub d_disp {

  my $prod_id   = $query->param('prd');
  my %prod_prof_dbfile;
  my $db_key;
  my ($title, $desc, $image_url, $dest_url, $theme, $num_of_keywords, $comments);
  my $screen_html_file = $PAGE_DIR.'prdisp.html';
  my $screen_html;
  my $checked   = "CHECKED";

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $prod_id  =~ tr/a-z/A-Z/;
  $prod_id  =~ s/\s+/ /g;
  $prod_id  =~ s/(^\s+)|(\s+$)//;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    $db_key = $prod_id;
    ($title, $desc, $image_url, $dest_url, $theme, $num_of_keywords, $comments, $d5, $d6, $d7, $d8) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
    untie %prod_prof_dbfile;
  };
  if ($@){
    log_error("d_disp1", $@);
    return (99, $internal_error);
  }

  $screen_html =~ s/:::grepin-fp200:::/$prod_id/g;
  $screen_html =~ s/:::grepin-fp201:::/$title/g;
  $screen_html =~ s/:::grepin-fp202:::/$desc/g;
  $screen_html =~ s/:::grepin-fp203:::/$image_url/g;
  $screen_html =~ s/:::grepin-fp204:::/$dest_url/g;
  if ($theme == 1) {
    $screen_html =~ s/:::grepin-fp205a:::/$checked/g; # select the yes 
  } else {
    $screen_html =~ s/:::grepin-fp205:::/$checked/g;  # select the no (default)
  }
  $screen_html =~ s/:::grepin-fp206:::/$num_of_keywords/g;
  $screen_html =~ s/:::grepin-fp207:::/$comments/g;
  return (0, $screen_html);

}


sub e_disp {
# display a product - error
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $error_id   = shift;
  my $error_msg  = shift;

  my $screen_html_file = $PAGE_DIR.'prdisp.html';
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
    log_error("e_disp1", $@);
    return (99, $internal_error);
  }

  $error_msg = "Error:".$error_id." ".$error_msg;

  $screen_html =~ s/:::grepin-fp290:::/$error_msg/g; # give the error message

  return (0, $screen_html);

}



sub d_edit {

  my $prod_id   = $query->param('prd');
  my %prod_prof_dbfile;
  my $db_key;
  my ($title, $desc, $image_url, $dest_url, $theme, $num_of_keywords, $comments);
  my $screen_html_file = $PAGE_DIR.'predit.html';
  my $screen_html;
  my $checked   = "CHECKED";

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $prod_id  =~ tr/a-z/A-Z/;
  $prod_id  =~ s/\s+/ /g;
  $prod_id  =~ s/(^\s+)|(\s+$)//;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    $db_key = $prod_id;
    if (!$prod_prof_dbfile{$db_key}) {
      untie %prod_prof_dbfile;
      return (1, "not found");
    } else {
      ($title, $desc, $image_url, $dest_url, $theme, $num_of_keywords, $comments, $d5, $d6, $d7, $d8) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
      untie %prod_prof_dbfile;
    }
  };
  if ($@){
    log_error("d_edit1", $@);
    return (99, $internal_error);
  }

  $screen_html =~ s/:::grepin-fp300:::/$prod_id/g;
  $screen_html =~ s/:::grepin-fp301:::/$title/g;
  $screen_html =~ s/:::grepin-fp302:::/$desc/g;
  $screen_html =~ s/:::grepin-fp303:::/$image_url/g;
  $screen_html =~ s/:::grepin-fp304:::/$dest_url/g;
  if ($theme == 1) {
    $screen_html =~ s/:::grepin-fp305a:::/$checked/g; # select the yes 
  } else {
    $screen_html =~ s/:::grepin-fp305:::/$checked/g;  # select the no (default)
  }
  $screen_html =~ s/:::grepin-fp306:::/$comments/g;

  return (0, $screen_html);

}



sub p_edit_update {
# edit-update a product
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $prod_id   = $query->param('prd');
  my $title     = $query->param('fp301');
  my $desc      = $query->param('fp302');
  my $image_url = $query->param('fp303');
  my $dest_url  = $query->param('fp304');
  my $theme     = $query->param('fp305');
  my $comments  = $query->param('fp306');
  my $num_of_keywords;
  my $db_key;
  my %prod_prof_dbfile;
  my %theme_dbfile;

  use Fcntl;

  # convert case
  $prod_id   =~ tr/a-z/A-Z/;

  # replace any white space to a single space
  $prod_id   =~ s/\s+/ /g;
  $title     =~ s/\s+/ /g;
  $desc      =~ s/\s+/ /g;
  $image_url =~ s/\s+/ /g;
  $dest_url  =~ s/\s+/ /g;
  $comments  =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $prod_id   =~ s/(^\s+)|(\s+$)//;
  $title     =~ s/(^\s+)|(\s+$)//;
  $desc      =~ s/(^\s+)|(\s+$)//;
  $image_url =~ s/(^\s+)|(\s+$)//;
  $dest_url  =~ s/(^\s+)|(\s+$)//;
  $comments  =~ s/(^\s+)|(\s+$)//;

  if (!$title) {
    return (1, "Title cannot be empty.");
  }

  if (!$desc) {
    return (1, "Product description cannot be empty.");
  }
  if (length($desc) > 255) {
    return (1, "Product description cannot be more than 255 characters.");
  }

  if (!$dest_url) {
    return (1, "Destination URL cannot be empty.");
  }

  if ($image_url) { 
    if (($image_url !~ m%^http://.*/$%) && ($image_url !~ m%^https://.*/$%)) {
      return (2, "Image URL should start with 'http://' or 'https://' and end with '/'.");
    }
  }

  if (($dest_url !~ m%^http://.*/$%) && ($dest_url !~ m%^https://.*/$%)) {
    return (2, "Destination URL should start with 'http://' or 'https://' and end with '/'.");
  }

  if (($theme != 1) && ($theme != 0)) {
    return (3, "Theme Product indicator should be either 0 or 1.");
  }

  if (length($comments) > 255) {
    return (1, "Comments cannot be more than 255 characters.");
  }

  eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    tie %theme_dbfile, "DB_File", $PROD_THEME_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_THEME_DB_FILE: $!";
    $db_key = $prod_id;
    ($d1, $d2, $d3, $d4, $d5, $num_of_keywords, $d6, $d7, $d8, $d9, $d10) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
    $prod_prof_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $title, $desc, $image_url, $dest_url, $theme, $num_of_keywords, $comments, $d7, $d8, $d9, $d10);
    if ($theme == 1) {
      $theme_dbfile{$db_key} = 1;
    } else {
      delete $theme_dbfile{$db_key};
    }
    untie %prod_prof_dbfile;
    untie %theme_dbfile;
  };
  if ($@){
    log_error("p_edit_update",$@);
    return (99, $internal_error);
  }

  return (0, "success");

}


sub e_edit {
# edit a product - error
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $error_id   = shift;
  my $error_msg  = shift;

  my $prod_id   = $query->param('prd');
  my $title     = $query->param('fp301');
  my $desc      = $query->param('fp302');
  my $image_url = $query->param('fp303');
  my $dest_url  = $query->param('fp304');
  my $theme     = $query->param('fp305');
  my $comments  = $query->param('fp306');
  my $checked   = "CHECKED";

  my $screen_html_file = $PAGE_DIR.'predit.html';
  my $screen_html;

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $prod_id  =~ tr/a-z/A-Z/;
  $prod_id  =~ s/\s+/ /g;
  $prod_id  =~ s/(^\s+)|(\s+$)//;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);
  };
  if ($@){
    log_error("e_edit1", $@);
    return (99, $internal_error);
  }

  # replace any white space to a single space
  $title     =~ s/\s+/ /g;
  $desc      =~ s/\s+/ /g;
  $image_url =~ s/\s+/ /g;
  $dest_url  =~ s/\s+/ /g;
  $comments  =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $title     =~ s/(^\s+)|(\s+$)//;
  $desc      =~ s/(^\s+)|(\s+$)//;
  $image_url =~ s/(^\s+)|(\s+$)//;
  $dest_url  =~ s/(^\s+)|(\s+$)//;
  $comments  =~ s/(^\s+)|(\s+$)//;

  $error_msg = "Error:".$error_id." ".$error_msg;

  $screen_html =~ s/:::grepin-fp390:::/$error_msg/g; # give the error message
  $screen_html =~ s/:::grepin-fp300:::/$prod_id/g;
  $screen_html =~ s/:::grepin-fp301:::/$title/g;
  $screen_html =~ s/:::grepin-fp302:::/$desc/g;
  $screen_html =~ s/:::grepin-fp303:::/$image_url/g;
  $screen_html =~ s/:::grepin-fp304:::/$dest_url/g;
  if ($theme == 1) {
    $screen_html =~ s/:::grepin-fp305a:::/$checked/g; # select the yes 
  } else {
    $screen_html =~ s/:::grepin-fp305:::/$checked/g;  # select the no (default)
  }
  $screen_html =~ s/:::grepin-fp306:::/$comments/g;

  return (0, $screen_html);

}


sub d_del {

  my $prod_id   = $query->param('prd');
  my %prod_prof_dbfile;
  my $db_key;
  my $title;
  my $screen_html_file = $PAGE_DIR.'prdel.html';
  my $screen_html;

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $prod_id  =~ tr/a-z/A-Z/;
  $prod_id  =~ s/\s+/ /g;
  $prod_id  =~ s/(^\s+)|(\s+$)//;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    $db_key = $prod_id;
    ($title, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
    untie %prod_prof_dbfile;
  };
  if ($@){
    log_error("d_del1", $@);
    return (99, $internal_error);
  }

  $screen_html =~ s/:::grepin-fp400:::/$prod_id/g;
  $screen_html =~ s/:::grepin-fp401:::/$title/g;

  return (0, $screen_html);

}



sub e_del {
# delete a product - error
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $error_id   = shift;
  my $error_msg  = shift;

  my $prod_id   = $query->param('prd');
  my %prod_prof_dbfile;
  my $db_key;
  my $title;

  my $screen_html_file = $PAGE_DIR.'prdel.html';
  my $screen_html;

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $prod_id  =~ tr/a-z/A-Z/;
  $prod_id  =~ s/\s+/ /g;
  $prod_id  =~ s/(^\s+)|(\s+$)//;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    $db_key = $prod_id;
    ($title, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
    untie %prod_prof_dbfile;
  };
  if ($@){
    log_error("e_del", $@);
    return (99, $internal_error);
  }

  $error_msg = "Error:".$error_id." ".$error_msg;

  $screen_html =~ s/:::grepin-fp490:::/$error_msg/g; # give the error message
  $screen_html =~ s/:::grepin-fp400:::/$prod_id/g;
  $screen_html =~ s/:::grepin-fp401:::/$title/g;

  return (0, $screen_html);

}



sub p_del_del {
# delete a product
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $prod_id   = $query->param('prd');
  my $keywords;
  my @keywords_array;
  my @products = ();
  my @temp_array = ();
  my $db_key;
  my %prod_prof_dbfile;
  my %theme_dbfile;
  my %prod_keyword_dbfile;
  my %keyword_dbfile;

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $prod_id  =~ tr/a-z/A-Z/;
  $prod_id  =~ s/\s+/ /g;
  $prod_id  =~ s/(^\s+)|(\s+$)//;

  eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    tie %theme_dbfile, "DB_File", $PROD_THEME_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_THEME_DB_FILE: $!";
    tie %prod_keyword_dbfile, "DB_File", $PROD_KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_KEYWORD_DB_FILE: $!";
    tie %keyword_dbfile, "DB_File", $KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $KEYWORD_DB_FILE: $!";

    $db_key = $prod_id;
    $keywords = $prod_keyword_dbfile{$db_key};
    @keywords_array = split /','/, $keywords;
    delete $prod_prof_dbfile{$db_key};
    delete $theme_dbfile{$db_key};
    delete $prod_keyword_dbfile{$db_key};
    $i = 0;
    while ($keywords_array[$i]) {
      @products = ();
      @temp_array = ();
      if ($keyword_dbfile{$keywords_array[$i]}) {
        @products = $keyword_dbfile{$keywords_array[$i]};
        foreach (@products) {
          if ($_ ne $prod_id) {
            push @temp_array, $_;
          }
        }
        $keyword_dbfile{$keywords_array[$i]} = @temp_array;
      }
      $i++;
    }
    untie %prod_prof_dbfile;
    untie %prod_keyword_dbfile;
    untie %theme_dbfile;
    untie %keyword_dbfile;
  };
  if ($@){
    log_error("p_del_del1",$@);
    return (99, $internal_error);
  }

  return (0, "success");

}



sub d_keyword {

  my $prod_id   = $query->param('prd');
  my %prod_prof_dbfile;
  my %prod_keyword_dbfile;
  my $db_key;
  my ($title, $theme, $num_of_keywords, $keywords);
  my $screen_html_file = $PAGE_DIR.'prkeyword.html';
  my $screen_html;
  my @keywords_array = ();
  my ($row_html_before, $row_html_after, $row_html_temp);

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $prod_id  =~ tr/a-z/A-Z/;
  $prod_id  =~ s/\s+/ /g;
  $prod_id  =~ s/(^\s+)|(\s+$)//;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    $db_key = $prod_id;
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    tie %prod_keyword_dbfile, "DB_File", $PROD_KEYWORD_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_KEYWORD_DB_FILE: $!";
    ($title, $d1, $d2, $d3, $d4, $num_of_keywords, $d5, $d6, $d7, $d8, $d9) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
    $keywords = $prod_keyword_dbfile{$db_key};
    untie %prod_prof_dbfile;
    untie %prod_keyword_dbfile;
  };
  if ($@){
    log_error("d_keyword1", $@);
    return (99, $internal_error);
  }

  @keywords_array = split /','/, $keywords;

  # create keyword rows
  $screen_html   =~ /:::grepin-start-row:::.*:::grepin-end-row:::/s;
  $row_html_before = $&;

  $row_html_after = undef;
  $i = 1;
  foreach (@keywords_array) {
    $row_html_temp  = $row_html_before;
    $row_html_temp  =~ s/:::grepin-ip500:::/$_/g; # keyword
    $row_html_temp  =~ s/:::grepin-ip502:::/$i/g; # remove check box
    $row_html_after .= $row_html_temp;
    $i++;
  }

  # substitute values in the page
  $screen_html =~ s/:::grepin-fp500:::/$prod_id/gs;
  $screen_html =~ s/:::grepin-fp501:::/$title/gs;
  $screen_html =~ s/:::grepin-fp502:::/$num_of_keywords/gs;
  $screen_html =~ s/:::grepin-start-row:::.*:::grepin-end-row:::/$row_html_after/gs;
  $screen_html =~ s/(:::grepin-start-row:::)|(:::grepin-end-row:::)//gs;

  return (0, $screen_html);

}



sub d_keyword_del {

  my $prod_id   = $query->param('prd');
  my $keyword_count = $query->param('fp502');
  my %prod_prof_dbfile;
  my $db_key;
  my $title;
  my $screen_html_file = $PAGE_DIR.'prkeydel.html';
  my $screen_html;
  my @delkey_array = ();
  my $in_keyword;
  my ($row_html_before, $row_html_after, $row_html_temp);

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $prod_id  =~ tr/a-z/A-Z/;
  $prod_id  =~ s/\s+/ /g;
  $prod_id  =~ s/(^\s+)|(\s+$)//;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    $db_key = $prod_id;
    ($title, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
    untie %prod_prof_dbfile;
  };
  if ($@){
    log_error("d_keyword_del1", $@);
    return (99, $internal_error);
  }

  # create keyword rows
  $screen_html   =~ /:::grepin-start-row:::.*:::grepin-end-row:::/s;
  $row_html_before = $&;

  $row_html_after = undef;
  if ($keyword_count > 0) {
    $i = 0;
    for (1..$keyword_count) {
      if ($query->param('ip501_{$_}') {
        $in_keyword = $query->param('ip501_{$_}');
        $in_keyword =~ tr/A-Z/a-z/;
        $in_keyword =~ s/\s+/ /g;
        $in_keyword =~ s/(^\s+)|(\s+$)//;
        push @delkey_array, $in_keyword;
        $row_html_temp  = $row_html_before;
        $row_html_temp  =~ s/:::grepin-ip600:::/$in_keyword/g; # keyword
        $row_html_after .= $row_html_temp;
        $i++;
      }
    }
  }

  if ($i >= $keyword_count) {
    return (1, "You cannot delete all the keywords for a product.");
  }

  $screen_html =~ s/:::grepin-fp600:::/$prod_id/g;
  $screen_html =~ s/:::grepin-fp601:::/$title/g;
  $screen_html =~ s/:::grepin-fp602:::/@delkey_array/g;
  $screen_html =~ s/:::grepin-start-row:::.*:::grepin-end-row:::/$row_html_after/gs;
  $screen_html =~ s/(:::grepin-start-row:::)|(:::grepin-end-row:::)//gs;

  return (0, $screen_html);

}



sub p_keyword_del_del {
# delete keywords for a product
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $prod_id   = $query->param('prd');
  my @delkey_array = $query->param('kwd');
  my ($keywords, $num_of_keywords);
  my @keywords_array;
  my @products = ();
  my @temp_array = ();
  my $db_key;
  my %prod_prof_dbfile;
  my %theme_dbfile;
  my %prod_keyword_dbfile;
  my %keyword_dbfile;

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $prod_id  =~ tr/a-z/A-Z/;
  $prod_id  =~ s/\s+/ /g;
  $prod_id  =~ s/(^\s+)|(\s+$)//;

  eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    tie %prod_keyword_dbfile, "DB_File", $PROD_KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_KEYWORD_DB_FILE: $!";
    tie %keyword_dbfile, "DB_File", $KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $KEYWORD_DB_FILE: $!";

    $db_key = $prod_id;
    ($d1, $d2, $d3, $d4, $d5, $num_of_keywords, $d6, $d7, $d8, $d9, $d10) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});

    $keywords = $prod_keyword_dbfile{$db_key};
    @keywords_array = split /','/, $keywords;
    @keywords_array = minus(\@keywords_array, \@delkey_array); # delete the keywords

    $num_of_keywords = @keywords_array;
    $prod_prof_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $num_of_keywords, $d6, $d7, $d8, $d9, $d10);

    $keywords = join(", ", @keywords_array);
    $prod_keyword_dbfile{$db_key} = $keywords;

    foreach $del_keyword (@delkey_array) {
      @products = ();
      @temp_array = ();
      if ($keyword_dbfile{$del_keyword}) {
        @products = $keyword_dbfile{$del_keyword};
        foreach (@products) {
          if ($_ ne $prod_id) {
            push @temp_array, $_;
          }
        }
        $keyword_dbfile{$del_keyword} = @temp_array;
      }
    }
    untie %prod_prof_dbfile;
    untie %prod_keyword_dbfile;
    untie %keyword_dbfile;
  };
  if ($@){
    log_error("p_keyword_del_del1",$@);
    return (99, $internal_error);
  }

  return (0, "success");

}



sub e_keyword_del_del {
# delete a product - error
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $error_id   = shift;
  my $error_msg  = shift;

  my $prod_id      = $query->param('prd');
  my @delkey_array = $query->param('kwd');
  my $db_key;
  my %prod_prof_dbfile;
  my $title;
  my ($row_html_before, $row_html_after, $row_html_temp);

  my $screen_html_file = $PAGE_DIR.'prkeydel.html';
  my $screen_html;

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $prod_id  =~ tr/a-z/A-Z/;
  $prod_id  =~ s/\s+/ /g;
  $prod_id  =~ s/(^\s+)|(\s+$)//;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    $db_key = $prod_id;
    ($title, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
    untie %prod_prof_dbfile;
  };
  if ($@){
    log_error("e_keyword_del_del", $@);
    return (99, $internal_error);
  }

  # create keyword rows
  $screen_html   =~ /:::grepin-start-row:::.*:::grepin-end-row:::/s;
  $row_html_before = $&;

  $row_html_after = undef;
  foreach (@delkey_array) {
    $row_html_temp  = $row_html_before;
    $row_html_temp  =~ s/:::grepin-ip600:::/$_/g; # keyword
    $row_html_after .= $row_html_temp;
  }

  $error_msg = "Error:".$error_id." ".$error_msg;

  $screen_html =~ s/:::grepin-fp690:::/$error_msg/g; # give the error message
  $screen_html =~ s/:::grepin-fp600:::/$prod_id/g;
  $screen_html =~ s/:::grepin-fp601:::/$title/g;
  $screen_html =~ s/:::grepin-start-row:::.*:::grepin-end-row:::/$row_html_after/gs;
  $screen_html =~ s/(:::grepin-start-row:::)|(:::grepin-end-row:::)//gs;

  return (0, $screen_html);

}



sub p_keyword_add {
# add keywords to product
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $prod_id   = $query->param('fp500');
  my $keywords  = $query->param('fp503');
  my $num_of_keywords = 0;
  my $db_key;
  my %prod_prof_dbfile;
  my %prod_keyword_dbfile;
  my %keyword_dbfile;
  my @products = ();
  my @keywords_array = ();
  my @input_array = ();
  my @remaining_array = ();
  my $input_count = 0;

  use Fcntl;

  # convert case
  $prod_id  =~ tr/a-z/A-Z/;
  $keywords =~ tr/A-Z/a-z/;

  # replace any white space to a single space
  $prod_id  =~ s/\s+/ /g;
  $keywords =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $prod_id  =~ s/(^\s+)|(\s+$)//;
  $keywords =~ s/(^\s+)|(\s+$)//;

  @input_array = split /','/, $keywords;

  $input_count = @input_array;
  if ($input_count == 0) {
    return (1, "At least one Keyword should be supplied.");
  }

  foreach (@input_array) {
    if ($_ !~ /[\dA-Z_]/) {
      return (1, "Keyword - $_ - has invalid characters. A to Z, numbers and '_' are the only valid characters for a keyword.");
    }
    if (length($_) > 255) {
      return (1, "Keyword - $_ - is too long. Keywords cannot be more than 255 characters.");
    }
  }

  eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    tie %prod_keyword_dbfile, "DB_File", $PROD_KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_KEYWORD_DB_FILE: $!";
    tie %keyword_dbfile, "DB_File", $KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $KEYWORD_DB_FILE: $!";

    $db_key = $prod_id;
    ($d1, $d2, $d3, $d4, $d5, $num_of_keywords, $d6, $d7, $d8, $d9, $d10) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
    $keywords = $prod_keyword_dbfile{$db_key};
    @old_array = split /','/, $keywords;

    @new_array = @old_array;
    @diff_array = ();

    foreach $element($input_array) {
      $match = 'n';
      foreach $item($old_array) {
        if ($item eq $element) {
          $match = 'y';
        }
      }
      if ($match = 'n') {
        push @new_array, $element;
      } else {
        push @diff_array, $element;
      }
    }

    $keywords = join(", ", @new_array);
    $prod_keyword_dbfile{$db_key} = $keywords;

    $num_of_keywords = @new_array;
    $prod_prof_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $num_of_keywords, $d6, $d7, $d8, $d9, $d10);

   
    $i = 0;
    foreach ($diff_array) {
      @products = ();
      if ($keyword_dbfile{$_}) {
        @products = $keyword_dbfile{$_};
      }
      push @products, $prod_id;
      $keyword_dbfile{$_} = @products;
    }
    untie %prod_prof_dbfile;
    untie %prod_keyword_dbfile;
    untie %keyword_dbfile;
  };
  if ($@){
    log_error("p_keyword_add",$@);
    return (99, $internal_error);
  }

  return (0, "success");

}



sub e_keyword {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $keywords   = $query->param('fp503');
  my $e_return_code;

  use Fcntl;

  ($e_return_code, $screen_html) = d_keyword();

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $keywords =~ tr/A-Z/a-z/;
  $keywords =~ s/\s+/ /g;
  $keywords =~ s/(^\s+)|(\s+$)//;

  if ($e_return_code == 0) {
    $error_msg = "Error:".$error_id." ".$error_msg;
    $screen_html =~ s/:::grepin-fp590:::/$error_msg/g; # give the error message
    $screen_html =~ s/:::grepin-fp503:::/$keywords/gs;
    return (0, $screen_html);
  } else {
    return ($e_return_code, $screen_html);
  }

}



sub d_prdlist {

  my %prod_prof_dbfile;
  my $db_key;
  my ($prod_id, $title, $theme, $num_of_keywords);
  my $screen_html_file = $PAGE_DIR.'prfullist.html';
  my $screen_html;
  my $prod_count = 0;
  my @list_array = ();
  my @row_array  = ();
  my ($row_html_before, $row_html_after, $row_html_temp);
  my $arrow = "->";

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    foreach $db_key (sort keys %prod_prof_dbfile) {
      ($title, $d1, $d2, $d3, $theme, $d4, $d5, $d6, $d7, $d8, $d9) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
      push @list_array, $theme.':::'.$db_key.':::'.$title;
      $prod_count++;
    }
    untie %prod_prof_dbfile;
  };
  if ($@){
    log_error("d_prdlist1", $@);
    return (99, $internal_error);
  }

  # create match report rows
  $screen_html   =~ /:::grepin-start-row:::.*:::grepin-end-row:::/s;
  $row_html_before = $&;

  $row_html_after = undef;
  if ($prod_count > 0) {
    foreach (@list_array) {
      @row_array = ();
      @row_array = split /:::/, $_;
      $row_html_temp  = $row_html_before;
      $row_html_temp  =~ s/:::grepin-ip700:::/$row_array[1]/g; # product name
      $row_html_temp  =~ s/:::grepin-ip701:::/$row_array[2]/g; # title
      if ($row_array[0] == 1) {
        $row_html_temp  =~ s/:::grepin-ip709:::/$arrow/g; # theme product indicator
      }
      $row_html_after .= $row_html_temp;
    }
  } else {
    return (1, "There are no products found for this account.");
  }

  # substitute values in the page
  $screen_html =~ s/:::grepin-fp700:::/$prod_count/gs;
  $screen_html =~ s/:::grepin-start-row:::.*:::grepin-end-row:::/$row_html_after/gs;
  $screen_html =~ s/(:::grepin-start-row:::)|(:::grepin-end-row:::)//gs;

  return (0, $screen_html);

}




sub e_prdlist {
# display a product list - error
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $error_id   = shift;
  my $error_msg  = shift;

  my $screen_html_file = $PAGE_DIR.'prfullist.html';
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
    log_error("e_prdlist1", $@);
    return (99, $internal_error);
  }

  $error_msg = "Error:".$error_id." ".$error_msg;

  $screen_html =~ s/:::grepin-fp790:::/$error_msg/g; # give the error message

  return (0, $screen_html);

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


sub p_memberchk {
# check if this member is a power list subscriber
# return codes
#  0 - member is valid
#  1 - member is invalid
#  99 - database error

  my $user_id    = $query->param('uid');
  my %pwrlst_db;     # user_id -> 1

  use Fcntl;

  eval {
    tie %pwrlst_db,    "DB_File", $PWRLST_DB_FILE, O_RDONLY, 0755      or die "Cannot open $PWRLST_DB_FILE: $!";
    if (!$pwrlst_db{$user_id}) || ($pwrlst_db{$user_id} != 1)) {
      untie %session_db;
      return (1, "Power List is not subscribed for this account. Please subscribe for Power List to access the requested page.");
    }
    untie %pwrlst_db;
  };
  if ($@){
    log_error("p_memberchk1", $@);
    return (99, $internal_error);
  }

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


# Returns an array with elements that are in both @{$ra} and @{$rb}.
sub intersection {
  my ($ra, $rb) = @_;
  my @i;
  # use a hash (instead of grep) for much better speed:
  my %check = ();
  foreach my $element (@{$rb}) {
    $check{$element} = 1;
  }
  foreach my $element (@{$ra}) {
    push @i, $element if( $check{$element} );
  }
  return @i;
}

# Returns an array with the elements of @{$ra} minus those of @{$rb}.
sub minus {
  my ($ra, $rb) = @_;
  my @i;
  # use a hash (instead of grep) for much better speed:
  my %check = ();
  foreach my $element (@{$rb}) {
    $check{$element} = 1;
  }
  foreach my $element (@{$ra}) {
    push @i, $element if( ! defined($check{$element}) );
  }
  return @i;
}

# Returns an array with elements that are in either @{$ra}, @{$rb}, or both.
sub union {
  my ($ra, $rb) = @_;
  my @i = @{$ra};
  # use a hash (instead of grep) for much better speed:
  my %check = ();
  foreach my $element (@{$rb}) {
    $check{$element} = 1;
  }
  foreach my $element (@{$ra}) {
    push @i, $element if( ! defined($check{$element}) );
  }
  return @i;
}
