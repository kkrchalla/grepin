#!/usr/bin/perl 

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
#   use CGI::Carp qw(carpout);
#   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/amznhtmlerr.txt")
#       or die "Unable to append to errorlog: $!\n";
#   carpout(*ERRORLOG);
}

# Grepin Search and Services
# Copyright (C) 2004 Grepin Search and Services <contact@grepin.com>

$|=1;    # autoflush


  use Fcntl;
  use CGI;
  package main;

  my $query = new CGI;
  my $cmd         = $query->param('cmd');	# command
  my $session_id  = $query->param('sid');
  my $user_id     = $query->param('uid');
  my $referral_id = $query->param('rid');
  my $search      = $query->param('query');	# search keyword
  my $mode        = $query->param('category');	# books, music, ....
  my $locale      = $query->param('locale');	# us or uk, default = us
  my $user_aid    = $query->param('aid');	# user amazon associate id
  my $type        = $query->param('type');	# 'bar'= bar, 'tower'= tower, default='bar'
  my $seq         = $query->param('seq');    	# number of the similar bar in the same page
  my $border_color= $query->param('bcolor');    # color of the border of the bar and tower
  my $footer_color= $query->param('fcolor');    # color of the footer text
  my $disp_num    = $query->param('disp');      # how many products to display? min=1, max=4
  my $source      = $query->param('source');    # source where it generated


  my ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20);

  ######################################

  my $MAIN_DIR = '/home/grepinco/public_html/cgi-bin/';
  my $PAGE_DIR = $MAIN_DIR.'pages/';
  my $USER_DIR = $MAIN_DIR.'users/';

  my $LOG_DIR    = $MAIN_DIR.'log/';
  my $LOG_FILE   = $LOG_DIR.'amznhtmllog.txt';

  ########################################

  my $return_code;
  my $return_msg;
  my $internal_error = "An internal error occurred. Sorry for the inconvenience.<br /> Please inform the webmaster about the error at contact\@grepin.com.";
  my $addr = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};

  print "Content-Type: text/html\n\n";

####  DO NOT CALL ANY SUB-PROGRAM UNTIL THIS POINT ########


  if (!$cmd) {
    $cmd = "amznhtml";
  }

  if (($cmd eq "amznhtml") || ($cmd eq "build")) {
    ($return_code, $return_msg) = m_build();
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


sub m_build {

  my $m_return_code;
  my $m_return_msg;

  ($m_return_code, $m_return_msg) = d_build();
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
    log_error("amznhtml1", $@);
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
# $USER_PROFILE_DB_FILE, $USER_PWD_DB_FILE



sub d_build {

  my $screen_html_file = $PAGE_DIR.'amznhtml.html';
  my $screen_html;
  my $error_msg;
  my $selected = "selected";

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);
  };
  if ($@){
    log_error("d_build1", $@);
    return (99, $internal_error);
  }

  my $copy_code    = qq[
<script src="http://www.grepin.com/cgi-bin/amznbar.pl?uid=$user_id&query=$search&category=$mode&locale=$locale&aid=$user_aid&type=$type&seq=$seq&bcolor=$border_color&fcolor=$footer_color&disp=$disp_num&out=javascript&source=$source"></script>
	];

  my $display_code    = qq[
<script src="http://www.grepin.com/cgi-bin/amznbar.pl?uid=$user_id&query=$search&category=$mode&locale=$locale&aid=$user_aid
&type=$type&seq=$seq&bcolor=$border_color&fcolor=$footer_color&disp=$disp_num&out=javascript&source=$source&log=no"></script>
	];

  $screen_html =~ s/:::grepin-f6200:::/$search/g;
  $screen_html =~ s/:::grepin-f6201:::/$mode/g;
  if ($locale eq 'uk') {
    $screen_html =~ s/:::grepin-f6202a:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-f6202:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-f6203:::/$user_aid/g;
  if ($type eq 'tower') {
    $screen_html =~ s/:::grepin-f6204a:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-f6204:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-f6205:::/$seq/g;
  $screen_html =~ s/:::grepin-f6206:::/$border_color/g;
  $screen_html =~ s/:::grepin-f6207:::/$footer_color/g;
  if ($disp_num == 1) {
    $screen_html =~ s/:::grepin-f6208a:::/$selected/g;
  } elsif ($disp_num == 2) {
    $screen_html =~ s/:::grepin-f6208b:::/$selected/g;
  } elsif ($disp_num == 3) {
    $screen_html =~ s/:::grepin-f6208c:::/$selected/g;
  } else {
    $screen_html =~ s/:::grepin-f6208:::/$selected/g;
  }
  $screen_html =~ s/:::grepin-f6209:::/$source/g;

  if ($cmd eq 'build') {
    $screen_html =~ s/:::grepin-f6210:::/$copy_code/g;
    $screen_html =~ s/:::grepin-f6211:::/$display_code/g;
  }

  return (0, $screen_html);

}


#####################################################################################################


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


