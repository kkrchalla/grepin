#!/usr/bin/perl -w

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
#   use CGI::Carp qw(carpout);
#   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/affscrerr.txt")
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
  my $LOG_FILE   = $LOG_DIR.'affscrlog.txt';

  my $LATEST_IDS_DB_FILE  = $USER_DIR.'latestids';
  my $AFF_PWD_DB_FILE     = $USER_DIR.'affpwd';
  my $AFF_PROFILE_DB_FILE = $USER_DIR.'affprof';
  my $AFF_USER_DB_FILE    = $USER_DIR.'affuser';
  my $USER_AFF_DB_FILE    = $USER_DIR.'useraff';

  ########################################

  my $cmd         = $query->param('cmd');
  my $session_id  = $query->param('sid');
  my $user_id     = $query->param('uid');
  my $referral_id = $query->param('rid');

  my $return_code;
  my $return_msg;
  my $internal_error = "An internal error occurred. Sorry for the inconvenience.<br /> Please inform the webmaster about the error at contact\@grepin.com.";
  my $addr = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};

  print "Content-Type: text/html\n\n";

  if ($query->param('source')) {
    my @line = ();
    my $addr = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};
    use Fcntl;
    push(@line, 'affscr ------------- ',
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
    log_error("affscr1", "The DB_File module was not found.");
    print "$internal_error \n\n";
    exit;
  }

####  DO NOT CALL ANY SUB-PROGRAM UNTIL THIS POINT ########


  if (!$cmd) {
    $cmd = "affhome";
  }

  if ($cmd eq "affhome") {
      ($return_code, $return_msg) = d_static ("affhome");
  } elsif ($cmd eq "add") {
    ($return_code, $return_msg) = m_add();
  } elsif ($cmd eq "edit") {
    ($return_code, $return_msg) = m_edit();
  } else {
    $return_code = 99;
    $return_msg = "Invalid request. Please check the URL and try again.";
  }

  #
  # if return_code == 90, the html is already sent to the screen. This happens in reports.
  #

  if ($return_code != 90) {
    ($return_code, $return_msg) = m_disp_screen ($return_msg);
    print $return_msg;
  }

  exit;


sub m_add {

  my $fn      = $query->param('fn');
  my $m_return_code;
  my $m_return_msg;

  if (($fn) && ($fn eq "add")) {
    ($m_return_code, $m_return_msg) = p_add();
    if ($m_return_code == 0) {
      ($m_return_code, $m_return_msg) = d_static("affadd2");
    } else {
      ($m_return_code, $m_return_msg) = e_add(6090, $m_return_msg);
    }
  } else {
    ($m_return_code, $m_return_msg) = d_static("affadd");
  }
  return ($m_return_code, $m_return_msg);
}


sub m_edit {

  my $fn      = $query->param('fn');
  my $m_return_code;
  my $m_return_msg;

  if (!$fn) {
    ($m_return_code, $m_return_msg) = d_static("affedit");
  } elsif ($fn eq "get") {
    ($m_return_code, $m_return_msg) = d_edit();
    if ($m_return_code == 1) {
      ($m_return_code, $m_return_msg) = e_add(6090, $m_return_msg);
    } elsif ($m_return_code != 0) {
      ($m_return_code, $m_return_msg) = e_edit(6190, $m_return_msg);
    }
  } elsif ($fn eq "sendpass") {
    ($m_return_code, $m_return_msg) = p_sendpass();
    ($m_return_code, $m_return_msg) = e_edit(6190, $m_return_msg);
  } elsif ($fn eq "chgpass") {
    ($m_return_code, $m_return_msg) = p_chgpass();
    ($m_return_code, $m_return_msg) = e_edit(6190, $m_return_msg);
  } elsif ($fn eq "sendaff") {
    ($m_return_code, $m_return_msg) = p_sendaff();
    ($m_return_code, $m_return_msg) = e_edit(6190, $m_return_msg);
  } elsif ($fn eq "update") {
    ($m_return_code, $m_return_msg) = p_update();
    ($m_return_code, $m_return_msg) = e_edit(6190, $m_return_msg);
  } else {
    ($m_return_code, $m_return_msg) = d_static("affedit");
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
    log_error("affscr2", $@);
    return (99, $internal_error);
  }

  $menu_html =~ s/:::grepin-inner-html:::/$inner_html/g;                 # put the inner screen
  $menu_html =~ s/:::grepin-fld00:::/$user_id/g;                           # user_id
  $menu_html =~ s/:::grepin-fld01:::/$session_id/g;                        # session_id
  $menu_html =~ s/:::grepin-fld10:::/$referral_id/g;                       # referral_id
  $menu_html =~ s/:::grepin-.*::://g;                                      # space out all the other fields

  return (0, $menu_html);

}



######################################################################################


# d_??? display subprogram
# p_??? process subprogram
# e_??? error display subprogram
# $PAGE_DIR
# $AFF_PROFILE_DB_FILE, $AFF_PWD_DB_FILE



sub d_edit {

  my $email_id = $query->param('f7100');
  my $pwd      = $query->param('f7101');
  my %aff_prof;
  my %aff_pwd;
  my %aff_user;
  my $db_key;
  my ($aff_id, $amzn_us, $amzn_uk, $pwd1, $pwd2, $ntfy_ind);
  my $screen_html_file = $PAGE_DIR.'affedit.html';
  my $screen_html;
  my $error_msg;
  my @users_array;
  my $total_users;
  my $checked = "CHECKED";

  use Fcntl;

  if (!$email_id) {
    $error_msg = "You must enter the email address.";
    return (2, $error_msg);
  }

  if (!$pwd) {
    $error_msg = "You must enter the password.";
    return (2, $error_msg);
  }

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %aff_prof, "DB_File", $AFF_PROFILE_DB_FILE, O_RDONLY, 0755 or die "Cannot open $AFF_PROFILE_DB_FILE: $!";
    tie %aff_pwd, "DB_File", $AFF_PWD_DB_FILE, O_RDONLY, 0755 or die "Cannot open $AFF_PWD_DB_FILE: $!";
    tie %aff_user, "DB_File", $AFF_USER_DB_FILE, O_RDONLY, 0755 or die "Cannot open $AFF_USER_DB_FILE: $!";

  };
  if ($@){
    log_error("d_edit1", $@);
    return (99, $internal_error);
  }

  $db_key = $email_id;

  if (!$aff_pwd{$db_key}) {
    $error_msg = "Affiliate is not found in our database. Please report this problem (including this message and the error number) to the webmaster for further assistance.";
    return (1, $error_msg);
  } else {
    ($pwd_on_file, $aff_id) = unpack("C/A* C/A*",$aff_pwd{$email_id});
    if (crypt($pwd, $pwd_on_file) ne $pwd_on_file) {
      return (2, "The password is invalid. Please try again.");
    }

    ($email_id, $amzn_us, $amzn_uk, $ntfy_ind, $add_date) = unpack("C/A* C/A* C/A* C/A* C/A*", $aff_prof{$aff_id});

    if ($aff_user{$aff_id}) {
      @users_array = split /-/, $aff_user{$aff_id};
      $total_users = @users_array;
    } else {
      $total_users = 0;
    }

    $screen_html =~ s/:::grepin-f7102:::/$aff_id/g;
    $screen_html =~ s/:::grepin-f7103:::/$aff_id/g;
    $screen_html =~ s/:::grepin-f7104:::/$total_users/g;
    $screen_html =~ s/:::grepin-f7105:::/$email_id/g;
    $screen_html =~ s/:::grepin-f7106:::/$amzn_us/g;
    $screen_html =~ s/:::grepin-f7107:::/$amzn_uk/g;
    if ($ntfy_ind eq 'Y') {
      $screen_html =~ s/:::grepin-f7108:::/$checked/g; #
    }

  }

  untie %aff_prof;
  untie %aff_pwd;

  return (0, $screen_html);

}

sub e_edit {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $screen_html_file = $PAGE_DIR.'affedit.html';
  my $screen_html;
  my $e_return_code;
  my $checked = "CHECKED";

  my $f7100 = $query->param('f7100');
  my $f7102 = $query->param('aid');
  my $f7103 = $query->param('aid');
  my $f7104 = $query->param('f7104');
  my $f7105 = $query->param('f7105');
  my $f7106 = $query->param('f7106');
  my $f7107 = $query->param('f7107');
  my $f7108 = $query->param('f7108');
  my $f7110 = $query->param('f7110');
  my $f7114 = $query->param('f7114');
  my $f7115 = $query->param('f7115');

  use Fcntl;

  $error_msg = $error_id." ".$error_msg;


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

    $screen_html =~ s/:::grepin-f7190:::/$error_msg/g; # give the error message in main section
    $screen_html =~ s/:::grepin-f7100:::/$f7100/g;
    $screen_html =~ s/:::grepin-f7102:::/$f7102/g;
    $screen_html =~ s/:::grepin-f7103:::/$f7103/g;
    $screen_html =~ s/:::grepin-f7104:::/$f7104/g;
    $screen_html =~ s/:::grepin-f7105:::/$f7105/g;
    $screen_html =~ s/:::grepin-f7106:::/$f7106/g;
    $screen_html =~ s/:::grepin-f7107:::/$f7107/g;
    if ($f7108 eq 'Y') {
      $screen_html =~ s/:::grepin-f7108:::/$checked/g; # select the 'notify me'
    }
    $screen_html =~ s/:::grepin-f7110:::/$f7110/g;
    $screen_html =~ s/:::grepin-f7114:::/$f7114/g;
    $screen_html =~ s/:::grepin-f7115:::/$f7115/g;

  return (0, $screen_html);
}

sub p_chgpass {
# change user's password
# return codes
#  0 = success
#  1 = email is not entered
#  2 = user does not exist
#  3 = old password does not match the one on the database
#  4 = new password 1 and 2 does not match
# 99 = database error

  my $email_id  = $query->param('f7110');
  my $old_pass  = $query->param('f7111');
  my $new_pass1 = $query->param('f7112');
  my $new_pass2 = $query->param('f7113');
  my $db_key;
  my %aff_pwd;
  my $aff_id;
  my $pwd_on_file;

  use Fcntl;

  #convert everything to lower case
  $old_pass  =~ tr/A-Z/a-z/;
  $new_pass1 =~ tr/A-Z/a-z/;
  $new_pass2 =~ tr/A-Z/a-z/;

  eval {
    tie %aff_pwd, "DB_File", $AFF_PWD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $AFF_PWD_DB_FILE: $!";
  };
  if ($@){
    log_error("p_chgpass1", $@);
    return (99, $internal_error);
  }

  $db_key = $email_id;
  if (!$aff_pwd{$db_key}) {
    return (1, "Affiliate does not exist in our system.");
  }

  ($pwd_on_file, $aff_id) = unpack("C/A* C/A*", $aff_pwd{$db_key});

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

  $aff_pwd{$db_key} = pack("C/A* C/A*", crypt($new_pass1, (length $email_id)), $aff_id);
  untie %aff_pwd;

  return (0, "Your password has been changed.");

}


sub p_update {
# change affiliate profile
# return codes
#  0 = success
#  1 = invalid email address
#  4 = user does not exist
#  5 = invalid password
# 99 = database error

  my $aff_id   = $query->param('aid'); # hidden
  my $email_id = $query->param('f7105');
  my $amzn_us  = $query->param('f7106');
  my $amzn_uk  = $query->param('f7107');
  my $ntfy_ind = $query->param('f7108');
  my $pwd      = $query->param('f7109');
  my $old_email_id;
  my %aff_pwd;
  my $pwd_on_file;
  my %aff_prof;
  my %aff_user;
  my @user_array = ();
  my $db_key;
  my $db_key2;
  my $db_key3;
  my $add_date;

  use Fcntl;

  #change to lower case
  $email_id =~ tr/A-Z/a-z/;
  $pwd      =~ tr/A-Z/a-z/;

  # replace any white space to a single space
  $email_id =~ s/\s+/ /g;
  $amzn_us  =~ s/\s+/ /g;
  $amzn_uk  =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $email_id =~ s/(^\s+)|(\s+$)//;
  $amzn_us  =~ s/(^\s+)|(\s+$)//;
  $amzn_uk  =~ s/(^\s+)|(\s+$)//;

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

  eval {
    tie %aff_prof, "DB_File", $AFF_PROFILE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $AFF_PROFILE_DB_FILE: $!";
    tie %aff_user, "DB_File", $AFF_USER_DB_FILE, O_RDONLY, 0755 or die "Cannot open $AFF_USER_DB_FILE: $!";
    tie %user_aff, "DB_File", $USER_AFF_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_AFF_DB_FILE: $!";
  };
  if ($@){
    log_error("p_update1",$@);
    return (99, $internal_error);
  }

  $db_key2 = $aff_id;
  ($old_email_id, $d1, $d2, $d3, $d4) = unpack("C/A* C/A* C/A* C/A* C/A*", $aff_prof{$db_key2});

  eval {
    tie %aff_pwd, "DB_File", $AFF_PWD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $AFF_PWD_DB_FILE: $!";
  };
  if ($@){
    log_error("p_update2",$@);
    untie %aff_prof;
    untie %aff_user;
    untie %user_aff;
    return (99, $internal_error);
  }

  $db_key = $old_email_id;
  if (!$aff_pwd{$db_key}) {
    untie %aff_pwd;
    untie %aff_prof;
    return (4, "Your email address does not exist in our system. Please correct and try again.");
  }

  ($pwd_on_file, $aff_id) = unpack("C/A* C/A*", $aff_pwd{$db_key});

  if (crypt($pwd, $pwd_on_file) ne $pwd_on_file) {
    return (5, "Invalid Password entered. Please try again.");
  }

  $aff_prof{$db_key2} = pack("C/A* C/A* C/A* C/A* C/A*", $email_id, $amzn_us, $amzn_uk, $ntfy_ind, $add_date);

  delete $aff_pwd{$db_key};
  $db_key = $email_id;
  $aff_pwd{$db_key} = pack("C/A* C/A*", crypt($pwd, (length ($email_id))), $aff_id);

  if ($aff_user{$aff_id}) {
    @users_array = split /-/, $aff_user{$aff_id};
  }

  foreach $db_key3(@user_array) {
    ($d1, $d2, $d3, $d4) = unpack("C/A* C/A* C/A* C/A*", $user_aff{$db_key3});
    $user_aff{$db_key3} = pack("C/A* C/A* C/A* C/A*", $aff_id, $amzn_us, $amzn_uk, $d4);
  }

  untie %aff_pwd;
  untie %aff_prof;
  untie %aff_user;
  untie %user_aff;

  return (0, "Your profile has been updated.");

}


###########################################################################################################



sub e_add {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $email_id = $query->param('f7000');
  my $amzn_us  = $query->param('f7003');
  my $amzn_uk  = $query->param('f7004');
  my $ntfy_ind = $query->param('f7005');
  my $checked  = "CHECKED";

  my $screen_html_file = $PAGE_DIR.'affadd.html';
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

  $error_msg = "Error:".$error_id." ".$error_msg;
  $screen_html =~ s/:::grepin-f7090:::/$error_msg/g; # give the error message
  $screen_html =~ s/:::grepin-f7000:::/$email_id/g;
  $screen_html =~ s/:::grepin-f7003:::/$amzn_us/g;
  $screen_html =~ s/:::grepin-f7004:::/$amzn_uk/g;
  if ($ntfy_ind eq 'Y') {
    $screen_html =~ s/:::grepin-f7005:::/$checked/g; #
  }

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


sub p_add {
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

  my $email_id = $query->param('f7000');
  my $pwd1     = $query->param('f7001');
  my $pwd2     = $query->param('f7002');
  my $amzn_us  = $query->param('f7003');
  my $amzn_uk  = $query->param('f7004');
  my $ntfy_ind = $query->param('f7005');
  my $accpterm = $query->param('f7006');
  my $unique_id;
  my $aff_id;
  my %aff_pwd;
  my %aff_profile;
  my $add_date;
  my $emaillength;

  my $subject;
  my $msgtxt;
  my $return_code;
  my $return_msg;
  my $createlog  = $LOG_DIR.'creafflog.txt';
  my $addr = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};

  use Fcntl;

  # change to lower case
  $email_id =~ tr/A-Z/a-z/;

  # replace any white space to a single space
  $email_id =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $email_id =~ s/(^\s+)|(\s+$)//;
  $amzn_us  =~ s/(^\s+)|(\s+$)//;
  $amzn_uk  =~ s/(^\s+)|(\s+$)//;

  if (!$email_id) {
    return (1, "You must enter your email address.")
  }

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

  if ($pwd1 ne $pwd2) {
    return (2, "Password does not match. Please enter again.");
  }

  if ($pwd1 =~ /\s/) {
    return (3, "Your password contains invalid characters. It should not have spaces or whitespace.")
  }

  if (length ($pwd1) < 7 ) {
    return (4, "Your password should be atleast 7 characters in length.")
  }

  if ((!$amzn_us) && (!$amzn_uk)) {
    return (5, "You must enter at least one Amazon associate id.")
  }

  if ($accpterm ne "Y") {
    return (6, "You have to check the 'I accept the Terms and Agreements' box to sign up as an affiliate.");
  }

  $emaillength = length $email_id;
  $add_date    = time;

  eval {
    tie %aff_pwd, "DB_File", $AFF_PWD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $AFF_PWD_DB_FILE: $!";
    tie %aff_profile, "DB_File", $AFF_PROFILE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $AFF_PROFILE_DB_FILE: $!";
  };
  if ($@){
    log_error("p_add1",$@);
    return (99, $internal_error);
  }

  if ($aff_pwd{$email_id}) {
    untie %aff_pwd;
    return (7, "Affiliate with the same email address already exists. Please use a different email address.");
  }
  ($return_code, $unique_id) = p_creunqid("r");
  if ($return_code == 99) {
    untie %aff_pwd;
    return (99, $unique_id);
  }
  $aff_id = "r" . $unique_id;
  $aff_pwd{$email_id} = pack("C/A* C/A*", crypt($pwd1, $emaillength), $aff_id);
  $aff_profile{$aff_id} = pack("C/A* C/A* C/A* C/A* C/A*", $email_id, $amzn_us, $amzn_uk, $ntfy_ind, $add_date);

  push(@line, 'affscr     ',
              $aff_id,
              ' - created on ',
              localtime time() || '-',
              $addr || '-',
              $email_id || '-');

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
    log_error("p_add2",$@);
  }

  $subject = "Grepin.com - Your Affiliate Signup";
  $msgtxt = <<__STOP_OF_MAIL__;
Dear Grepin Affiliate,

Welcome and thank you for becoming 'Grepin Search and Services' affiliate.

I am sure you will enjoy being partners with us.

Following is your login information:

  Email Address : $email_id
  Affiliate ID  : $aff_id

The affiliate ID is very important for you.
When you refer your visitors or customers to Grepin Site Search,
use the following url in order for you to get the credit.

http://www.grepin.com/cgi-bin/webscr.pl?rid=$aff_id

If you have any questions, please feel free to
contact us at affiliates\@grepin.com

Sincerely,
Grepin Search and Services.

__STOP_OF_MAIL__

  ($return_code, $return_msg) = p_sendemail("affiliates\@grepin.com","contact\@grepin.com",$email_id,$subject,$msgtxt,, );
  if ($return_code > 0){
    delete $aff_pwd{$email_id};
    delete $aff_profile{$aff_id};
    untie %aff_pwd;
    untie %aff_profile;
    log_error("p_add3", $return_msg);
    return (7, $return_msg);
  }

  untie %aff_pwd;
  untie %aff_profile;

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



###################################################################################################


sub p_sendpass {
# I forgot password and send it to me..
# return codes
#  0 = success
#  1 = email is not entered
#  2 = user does not exist
#  3 = sendmail was unsuccessful
# 99 = database error

  my $email_id = $query->param('f7114');
  my $password;
  my %aff_pwd;
  my $db_key;
  my $aff_id;
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
    tie %aff_pwd, "DB_File", $AFF_PWD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $AFF_PWD_DB_FILE: $!";
  };
  if ($@){
    log_error("p_sendpass1", $@);
    return (99, $internal_error);
  }

  $db_key = $email_id;
  if (!$aff_pwd{$db_key}) {
    return (2, "There is no affiliate with this email address in our system.");
  }

  ($password, $aff_id) = unpack("C/A* C/A*", $aff_pwd{$db_key});

  $password = substr($email_id, 0, 3) . substr(time(),-6);

  $aff_pwd{$db_key} = pack("C/A* C/A*", crypt($password, (length $email_id)), $aff_id);
  untie %aff_pwd;

  $msgtxt = <<__STOP_OF_MAIL__;
Dear Grepin.com Affiliate,

Following is your affiliate password that you requested:

  Email Address : $email_id
  Password      : $password

Please keep this information secured.
If you would like to change your password (recommended), 
you can do so at
http://www.grepin.com/cgi-bin/affscr.pl?cmd=edit

If you have any questions, please feel free to
contact us at affiliates\@grepin.com

Sincerely,
Grepin Search and Services.

__STOP_OF_MAIL__

  ($return_code, $return_msg) = p_sendemail("password\@grepin.com","contact\@grepin.com", $email_id, "Affiliate Password.",$msgtxt,, );

  if ($return_code > 0){
    log_error("p_sendpass2", $return_msg);
    return (3, $return_msg);
  }

  return (0, "Your affiliate password is sent to your email address.");

}


sub p_sendaff {
# I forgot affiliate id and send it to me..
# return codes
#  0 = success
#  1 = email is not entered
#  2 = user does not exist
#  3 = sendmail was unsuccessful
# 99 = database error

  my $email_id = $query->param('f7115');
  my %aff_pwd;
  my $db_key;
  my $aff_id;
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
    tie %aff_pwd, "DB_File", $AFF_PWD_DB_FILE, O_RDONLY, 0755 or die "Cannot open $AFF_PWD_DB_FILE: $!";
  };
  if ($@){
    log_error("p_sendref1", $@);
    return (99, $internal_error);
  }

  $db_key = $email_id;
  if (!$aff_pwd{$db_key}) {
    return (2, "There is no affiliate with this email address in our system.");
  }

  ($password, $aff_id) = unpack("C/A* C/A*", $aff_pwd{$db_key});


  $msgtxt = <<__STOP_OF_MAIL__;
Dear Grepin.com Affiliate,

Following is your affiliate ID that you requested:

  Email Address : $email_id
  Affiliate ID  : $aff_id

The affiliate ID is very important for you.
When you refer your visitors or customers to Grepin Site Search,
use the following url in order for you to get the credit.

http://www.grepin.com/cgi-bin/webscr.pl?rid=$aff_id

If you have any questions, please feel free to
contact us at affiliates\@grepin.com

Sincerely,
Grepin Search and Services.

__STOP_OF_MAIL__

  ($return_code, $return_msg) = p_sendemail("affiliates\@grepin.com","contact\@grepin.com", $email_id, "Your Affiliate ID",$msgtxt,, );

  if ($return_code > 0){
    log_error("p_sendpass2", $return_msg);
    return (3, $return_msg);
  }

  return (0, "Your affiliate id is sent to your email address.");

}
