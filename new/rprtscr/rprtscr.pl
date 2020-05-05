#!/usr/bin/perl

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
#   use CGI::Carp qw(carpout);
#   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/rprtscrerr.txt")
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
  my $LOG_FILE   = $LOG_DIR.'rprtscrlog.txt';
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

  ########################################

  my $cmd        = $query->param('cmd');
  my $session_id = $query->param('sid');
  my $user_id    = $query->param('uid');

  my $USER_LOCAL_DIR = $MAIN_DIR.$user_id.'/';
  my $SRCH_USER_DIR  = $USER_LOCAL_DIR.'search/';
  my $SRCH_LOG_DIR   = $SRCH_USER_DIR.'log/';

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
    push(@line, 'rprtscr ------------- ',
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
    log_error("rprtscr1", "The DB_File module was not found.");
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
        if (($cmd eq "acctmgmt") || ($cmd eq "cnfgindx") || ($cmd eq "cnfgrslt") || ($cmd eq "members") || ($cmd eq "reports") || ($cmd eq "terminate")) {
          ($return_code, $return_msg) = e_login(5190, $return_msg);
          $valid_sid = 'F';
        }
      }
    }
  } else {
    if (($cmd eq "acctmgmt") || ($cmd eq "cnfgindx") || ($cmd eq "cnfgrslt") || ($cmd eq "members") || ($cmd eq "reports") || ($cmd eq "terminate")) {
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
    } elsif ($cmd eq "cnfgrslt") {
      ($return_code, $return_msg) = m_cnfgrslt();
    } elsif ($cmd eq "contctme") {
      ($return_code, $return_msg) = m_contctme();
    } elsif ($cmd eq "members") {
      ($return_code, $return_msg) = m_members();
    } elsif ($cmd eq "reports") {
      ($return_code, $return_msg) = m_reports();
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


sub m_cnfgrslt {

  my $fn      = $query->param('fn');
  my $arg     = $query->param('arg');
  my $user_id = $query->param('uid');
  my $m_return_code;
  my $m_return_msg;

  if (!$fn) {
    ($m_return_code, $m_return_msg) = d_static("cnfgrslt");
  } elsif ($fn eq "basic") {
    if (!$arg) {
      ($m_return_code, $m_return_msg) = d_cnfgrsltb($user_id);
    } elsif ($arg eq "preview") {
      ($m_return_code, $m_return_msg) = p_cnfgrsltb();	# will return 90, undef if success
      if ($m_return_code == 1) {
        ($m_return_code, $m_return_msg) = e_cnfgrsltb(5590, $m_return_msg);
      } elsif ($m_return_code == 2) {
        ($m_return_code, $m_return_msg) = e_cnfgrsltb(5591, $m_return_msg);
      } elsif ($m_return_code == 3) {
        ($m_return_code, $m_return_msg) = e_cnfgrsltb(5592, $m_return_msg);
      } elsif ($m_return_code == 4) {
        ($m_return_code, $m_return_msg) = e_cnfgrsltb(5593, $m_return_msg);
      }
    } elsif ($arg eq "confirm") {
      ($m_return_code, $m_return_msg) = p_cnfgrsltb2();
      if ($m_return_code == 0) {
        ($m_return_code, $m_return_msg) = d_static("cnfgrslt2");
#-->   change the referrer url to fn=success, arg=undef
      } elsif ($m_return_code == 1) {
        ($m_return_code, $m_return_msg) = e_cnfgrsltb(5590, $m_return_msg);
      }
    } else {
      $m_return_code = 99;
      $m_return_msg  = "Invalid request. Please check the URL and try again.";
    }
  } elsif ($fn eq "advance") {
    if (!$arg) {
      ($m_return_code, $m_return_msg) = d_cnfgrslta($user_id);
    } elsif ($arg eq "preview") {
      ($m_return_code, $m_return_msg) = p_cnfgrslta();	# will return 90, undef if success
      if ($m_return_code != 90) {
        ($m_return_code, $m_return_msg) = e_cnfgrslta(5594, $m_return_msg);
      }
    } elsif ($arg eq "confirm") {
      ($m_return_code, $m_return_msg) = p_cnfgrslta2();
      if ($m_return_code == 0) {
        ($m_return_code, $m_return_msg) = d_static("cnfgrslt2");
#-->   change the referrer url to fn=success, arg=undef
      } elsif ($m_return_code == 1) {
        ($m_return_code, $m_return_msg) = e_cnfgrslta(5594, $m_return_msg);
      }
    } else {
      $m_return_code = 99;
      $m_return_msg  = "Invalid request. Please check the URL and try again.";
    }
  } elsif ($fn eq "success") {
    ($m_return_code, $m_return_msg) = d_static("cnfgrslt2");
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


sub m_reports {

  my $fn      = $query->param('fn');
  my $arg     = $query->param('arg');
  my $user_id = $query->param('uid');
  my $m_return_code;
  my $m_return_msg;

  if (!$fn) {
    ($m_return_code, $m_return_msg) = d_static("reports");
  } elsif ($fn eq "detail") {
    if ($arg eq "sendrprt") {
      ($m_return_code, $m_return_msg) = p_addrprtq($user_id, $fn);	# will return 90, undef
    } else {
      ($m_return_code, $m_return_msg) = p_rprtdtl();	# will return 90, undef
    }
  } elsif ($fn eq "monthly") {
    if ($arg eq "sendrprt") {
      ($m_return_code, $m_return_msg) = p_addrprtq($user_id, $fn);	# will return 90, undef
    } else {
      ($m_return_code, $m_return_msg) = p_rprtmth();	# will return 90, undef
    }
  } elsif ($fn eq "tilldate") {
    if ($arg eq "sendrprt") {
      ($m_return_code, $m_return_msg) = p_addrprtq($user_id, $fn);	# will return 90, undef
    } else {
      ($m_return_code, $m_return_msg) = p_rprttldt();	# will return 90, undef
    }
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
    log_error("rprtscr2", $@);
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



#####################################################################################################



sub p_addrprtq {
# add to report queue
# return codes
# 0  = success
# 99 = database error

  my $user_id = shift;
  my $report_type = shift;
  my %queue_dbfile;
  my $db_key;
  my $last_used_queue;
  my $last_processed_queue;
  my %report_queue_dbfile;
  my $queue_time;
  my $pid;

  use Fcntl;

  if ($query->param('mth')) {
    $report_type = $query->param('mth');
  }

  $db_key = "report";
  eval {
    tie %queue_dbfile, "DB_File", $QUEUE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $QUEUE_DB_FILE: $!";
  };
  if ($@){
    log_error("p_addrprtq1", $@);
    return (99, $internal_error);
  }

  if ($queue_dbfile{$db_key}) {
    ($last_used_queue, $last_processed_queue) = unpack("C/A* C/A*", $queue_dbfile{$db_key});
    $last_used_queue++;
  } else {
    $last_used_queue      = 1;
    $last_processed_queue = 0;
  }
  $queue_dbfile{$db_key} = pack("C/A* C/A*",$last_used_queue, $last_processed_queue);
  untie %queue_dbfile;

  $db_key = $last_used_queue;
  eval {
    tie %report_queue_dbfile, "DB_File", $REPORT_QUEUE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $REPORT_QUEUE_DB_FILE: $!";
  };
  if ($@){
    log_error("p_addrprtq2", $@);
    return (99, $internal_error);
  }

  $queue_time = time();
  $d1 = undef;
  $d2 = undef;
  $d3 = undef;
  $report_queue_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A*", $user_id, $report_type, $queue_time, $d1, $d2, $d3);
  untie %report_queue_dbfile;

  eval {
    $pid = fork();
    if ($pid == 0) {
      close STDIN;
      close STDOUT;
      close STDERR;

      exec ("/home/grepinco/cgi-bin/bsendrprt");
    } elsif (!defined $pid) {
      die "fork failed during bsendrprt submitting in rprtscr";
    }
  };
  if ($@){
    log_error("p_addrprtq3", $@);
  }

  return (0,"success");

}


sub p_rprtdtl {
# show the detailed (last 7 days) search report
# return codes
# 0 - success
# 99 = database error

  my $user_id          = $query->param('uid');
  my $now = time();
  my $yday;
  my $report_page_html = $PAGE_DIR.'rprtdtl.html';
  my $web_page_html;
  my $searchlogfile_base = $SRCH_LOG_DIR.'searchlog';
  my $searchlogfile;
  my @report_array = ();
  my @row_array;
  my $day_count = 0;
  my $row_count = 0;
  my $row_html_before;
  my $row_html_temp;
  my $row_html_after;
  my $search_time;
  my $i = 0;


  use Fcntl;

  $yday = (localtime $now)[7];

  $searchlogfile = $searchlogfile_base.$yday;
  while ($daycount < 7) {
    $daycount++;
    if (-e $searchlogfile) {
      eval {
        open (SEARCHLOG, $searchlogfile) or die "Cannot open searchlogfile '$searchlogfile' for reading: $!";
        @report_array = (@report_array, (reverse <SEARCHLOG>));
        close(SEARCHLOG);
      };
      if ($@){
        log_error("p_rprtdtl1", $@);
        return (99, $internal_error);
      }
    }

    $yday--;
    if ($yday > 0) {
      $searchlogfile = $searchlogfile_base.$yday;
    } else {
      $yday = 365;
      $searchlogfile = $searchlogfile_base.$yday;
      if (!(-e $searchlogfile)) {
        $yday = 364;
        $searchlogfile = $searchlogfile_base.'$yday';
      }
    }
  }

  $row_count = $#report_array + 1;

  eval {
    open (REPORTFILE, $report_page_html) or die "Cannot open reportpagehtml '$report_page_html' for reading: $!";
    while (<REPORTFILE>) {
      $web_page_html .= $_;
    }
    close(REPORTFILE);
  };
  if ($@){
    log_error("p_rprtdtl2", $@);
    return (99, $internal_error);
  }

  # substitute general values in the report page
  $web_page_html =~ s/:::grepin-fld00:::/$user_id/g;
  $web_page_html =~ s/:::grepin-fld01:::/$session_id/g;
  $web_page_html =~ s/:::grepin-f5610:::/$row_count/g;

  # create report rows
  $web_page_html   =~ /:::grepin-start-row:::.*:::grepin-end-row:::/s;
  $row_html_before = $&;

  if ($row_count == 0) {
    $row_html_temp   = $row_html_before;
    $row_html_temp =~ s/:::grepin-i5610:::/-N\/A-/g; # search terms
    $row_html_temp =~ s/:::grepin-i5611:::/-N\/A-/g; # search time
    $row_html_temp =~ s/:::grepin-i5612:::/-N\/A-/g; # search duration
    $row_html_temp =~ s/:::grepin-i5613:::/-N\/A-/g; # number of results
    $row_html_temp =~ s/:::grepin-i5614:::/-N\/A-/g; # next or prev
    $row_html_temp =~ s/:::grepin-i5615:::/-N\/A-/g; # search source
    $row_html_after .= $row_html_temp;
  } else {
    while ($report_array[$i]) {
      @row_array = ();
      @row_array = split /:::/, $report_array[$i];
      $row_html_temp   = $row_html_before;
      $row_html_temp =~ s/:::grepin-i5610:::/$row_array[0]/g; # search terms
      ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9) = localtime($row_array[1]);
      $d6 = $d6 + 1900;
      $d5++;
      $search_time = $d6.'/'.$d5.'/'.$d4.' '.$d3.':'.$d2.':'.$d1;
      $row_html_temp =~ s/:::grepin-i5611:::/$search_time/g; # search time
      $row_html_temp =~ s/:::grepin-i5612:::/$row_array[2]/g; # search duration
      $row_html_temp =~ s/:::grepin-i5613:::/$row_array[3]/g; # number of results
      if ($row_array[4] == 0) {
        $row_array[4] = 'No';
      } else {
        $row_array[4] = 'Yes';
      }
      $row_html_temp =~ s/:::grepin-i5614:::/$row_array[4]/g; # next or prev
      $row_html_temp =~ s/:::grepin-i5615:::/$row_array[5]/g; # search source
      $row_html_after .= $row_html_temp;
      $i++;
    }
  }

  $web_page_html =~ s/:::grepin-start-row:::.*:::grepin-end-row:::/$row_html_after/gs;
  $web_page_html =~ s/(:::grepin-start-row:::)|(:::grepin-end-row:::)//gs;
  $web_page_html =~ s/:::grepin-.*::://gs;         # space out all the other fields

  print $web_page_html;

  return (90, undef);
}


sub p_rprtmth {
# display the monthly report on the screen
# return codes
# 0 - success
# 1 - no match-data
# 2 - no nomatch-data
# 99 = database error

  my $user_id          = $query->param('uid');
  my $session_id       = $query->param('sid');
  my $report_month     = $query->param('mth');
  my $report_page_html = $PAGE_DIR.'rprtmth.html';
  my $web_page_html;
  my %searchlog_dbfile;
  my %nomatchlog_dbfile;
  my %user_status_dbfile;
  my $db_key;
  my @match_report_array = ();
  my @nomatch_report_array = ();
  my @row_array;
  my $match_count = 0;
  my $nomatch_count = 0;
  my $match_row_count = 0;
  my $nomatch_row_count = 0;
  my $row_html_before;
  my $row_html_temp;
  my $row_html_after;
  my $i = 0;
  my @month_names = qw<January February March April May June July August September October November December>;
  my $last_update_date;
  my $temp_time;

  my $USERSEARCHLOG_MONTH_DB_FILE  = $SRCH_LOG_DIR.'srchlogmth';
  my $USERNOMATCHLOG_MONTH_DB_FILE = $SRCH_LOG_DIR.'nomatchmth';

  use Fcntl;

  if ($query->param('mth')) {
    $report_month = $query->param('mth');
    if (($report_month < 1) || ($report_month > 12)) {
      return (1, "Invalid month entered. Please enter a value between 1 and 12 for month and try again.");
    }
  } else {
    $report_month = (localtime time())[4] + 1;
  }
  my $searchlog = $USERSEARCHLOG_MONTH_DB_FILE.$report_month;
  my $nomatchlog = $USERNOMATCHLOG_MONTH_DB_FILE.$report_month;

  if (-e $searchlog) {
    eval {
      tie %searchlog_dbfile, "DB_File", $searchlog, O_RDONLY, 0755 or die "Cannot open $searchlog: $!";
      foreach $db_key (sort keys %searchlog_dbfile) {
        ($num_of_times, $next_prev) = unpack("C/A* C/A*", $searchlog_dbfile{$db_key});
        push @match_report_array, join(':::', $db_key, $num_of_times, $next_prev);
        $match_row_count++;
      }
      untie %searchlog_dbfile;
    };
    if ($@){
      log_error("p_rprtmth1", $@);
      return (1, $internal_error);
    }
  }

  if (-e $nomatchlog) {
    eval {
      tie %nomatchlog_dbfile, "DB_File", $nomatchlog, O_RDONLY, 0755 or die "Cannot open $nomatchlog: $!";
      foreach $db_key (sort keys %nomatchlog_dbfile) {
        $num_of_times = $nomatchlog_dbfile{$db_key};
        push @nomatch_report_array, $db_key.':::'.$num_of_times;
        $nomatch_row_count++;
      }
      untie %nomatchlog_dbfile;
    };
    if ($@){
      log_error("p_rprtmth2", $@);
      return (2, $internal_error);
    }
  }

  eval {
    open (REPORTFILE, $report_page_html) or die "Cannot open reportpagehtml '$report_page_html' for reading: $!";
    while (<REPORTFILE>) {
      $web_page_html .= $_;
    }
    close(REPORTFILE);
  };
  if ($@){
    log_error("p_rprtmth3", $@);
    return (99, $internal_error);
  }


  #
  # Read the user status file to get last_report_update_date
  #   key = user_id + '-' + status_type
  #     status_type = 1 = last_indexed_date
  #     status_type = 2 = last_search_use_date
  #     status_type = 3 = member_status (F = free, S = subscription)
  #     status_type = 4 = config_status (I, IQ, S, IS, IQS)
  #     status_type = 5 = last montly/summary report update date
  #
  eval {
    use Fcntl;
    tie %user_status_dbfile, $db_package, $USER_STATUS_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_STATUS_DB_FILE: $!";
    $db_key = $user_id.'-5';
    if ($user_status_dbfile{$db_key}) {
      $temp_time = $user_status_dbfile{$db_key};
      $last_update_date = localtime $temp_time;
    } else {
      $last_update_date = "- Not yet updated";
    }
    untie %user_status_dbfile;
  };
  if ($@) {
    log_error("p_rprtmth4", $@);
    return (99, $internal_error);
  }


  # substitute general values in the report page
  $web_page_html =~ s/:::grepin-fld00:::/$user_id/g;
  $web_page_html =~ s/:::grepin-fld01:::/$session_id/g;
  $web_page_html =~ s/:::grepin-f5620:::/$month_names[$report_month - 1]/g;
  $web_page_html =~ s/:::grepin-f5621:::/$last_update_date/g;

  # create match report rows
  $web_page_html   =~ /:::grepin-start-match-row:::.*:::grepin-end-match-row:::/s;
  $row_html_before = $&;

  $row_html_after = undef;
  if ($match_row_count == 0) {
    $row_html_temp  = $row_html_before;
    $row_html_temp  =~ s/:::grepin-i5620:::/-N\/A-/g; # search terms
    $row_html_temp  =~ s/:::grepin-i5621:::/-N\/A-/g; # num of times
    $row_html_temp  =~ s/:::grepin-i5622:::/-N\/A-/g; # next prev
    $row_html_after .= $row_html_temp;
  } else {
    $i = 0;
    while ($match_report_array[$i]) {
      @row_array = ();
      @row_array = split /:::/, $match_report_array[$i];
      $row_html_temp  = $row_html_before;
      $row_html_temp  =~ s/:::grepin-i5620:::/$row_array[0]/g; # search terms
      $row_html_temp  =~ s/:::grepin-i5621:::/$row_array[1]/g; # num of times
      $row_html_temp  =~ s/:::grepin-i5622:::/$row_array[2]/g; # next prev
      $row_html_after .= $row_html_temp;
      $i++;
      $match_count += $row_array[1];
    }
  }

  $web_page_html =~ s/:::grepin-start-match-row:::.*:::grepin-end-match-row:::/$row_html_after/gs;
  $web_page_html =~ s/(:::grepin-start-match-row:::)|(:::grepin-end-match-row:::)//gs;

  # create nomatch report rows
  $web_page_html   =~ /:::grepin-start-nomatch-row:::.*:::grepin-end-nomatch-row:::/s;
  $row_html_before = $&;

  $row_html_after = undef;
  if ($nomatch_row_count == 0) {
    $row_html_temp  = $row_html_before;
    $row_html_temp  =~ s/:::grepin-i5623:::/-N\/A-/g; # search terms
    $row_html_temp  =~ s/:::grepin-i5624:::/-N\/A-/g; # num of times
    $row_html_after .= $row_html_temp;
  } else {
    $i = 0;
    while ($nomatch_report_array[$i]) {
      @row_array = split /:::/, $nomatch_report_array[$i];
      $row_html_temp  = $row_html_before;
      $row_html_temp  =~ s/:::grepin-i5623:::/$row_array[0]/g; # search terms
      $row_html_temp  =~ s/:::grepin-i5624:::/$row_array[1]/g; # num of times
      $row_html_after .= $row_html_temp;
      $i++;
      $nomatch_count += $row_array[1];
    }
  }

  $web_page_html =~ s/:::grepin-f5622:::/$match_count/g;
  $web_page_html =~ s/:::grepin-f5623:::/$nomatch_count/g;
  $web_page_html =~ s/:::grepin-start-nomatch-row:::.*:::grepin-end-nomatch-row:::/$row_html_after/gs;
  $web_page_html =~ s/(:::grepin-start-nomatch-row:::)|(:::grepin-end-nomatch-row:::)//gs;
  $web_page_html =~ s/:::grepin-.*::://g;         # space out all the other fields

  print $web_page_html;

  return (90, undef);
}


sub p_rprttldt {
# display till date report on the screen
# return codes
# 0 - success
# 1 - no match-data
# 2 - no nomatch-data
# 99 = database error

  my $user_id          = $query->param('uid');
  my $report_page_html = $PAGE_DIR.'rprttldt.html';
  my $web_page_html;
  my %searchlog_dbfile;
  my %nomatchlog_dbfile;
  my %user_status_dbfile;
  my $db_key;
  my @match_report_array = ();
  my @nomatch_report_array = ();
  my @row_array;
  my $match_count = 0;
  my $nomatch_count = 0;
  my $match_row_count = 0;
  my $nomatch_row_count = 0;
  my $row_html_before;
  my $row_html_temp;
  my $row_html_after;
  my $i = 0;
  my $last_update_date;
  my $temp_time;

  my $USERSEARCHLOG_DB_FILE  = $SRCH_LOG_DIR.'srchlog';
  my $USERNOMATCHLOG_DB_FILE = $SRCH_LOG_DIR.'nomatchlog';

  use Fcntl;

  if (-e $USERSEARCHLOG_DB_FILE) {
    eval {
      tie %searchlog_dbfile, "DB_File", $USERSEARCHLOG_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USERSEARCHLOG_DB_FILE: $!";
      foreach $db_key (sort keys %searchlog_dbfile) {
        ($num_of_times, $next_prev) = unpack("C/A* C/A*", $searchlog_dbfile{$db_key});
        push @match_report_array, join(':::', $db_key, $num_of_times, $next_prev);
        $match_row_count++;
      }
      untie %searchlog_dbfile;
    };
    if ($@){
      log_error("p_rprttldt1", $@);
      return (1, $internal_error);
    }
  }

  if (-e $USERNOMATCHLOG_DB_FILE) {
    eval {
      tie %nomatchlog_dbfile, "DB_File", $USERNOMATCHLOG_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USERNOMATCHLOG_DB_FILE: $!";
      foreach $db_key (sort keys %nomatchlog_dbfile) {
        $num_of_times = $nomatchlog_dbfile{$db_key};
        push @nomatch_report_array, $db_key.':::'.$num_of_times;
        $nomatch_row_count++;
      }
      untie %nomatchlog_dbfile;
    };
    if ($@){
      log_error("p_rprttldt2", $@);
      return (2, $internal_error);
    }
  }

  eval {
    open (REPORTFILE, $report_page_html) or die "Cannot open reportpagehtml '$report_page_html' for reading: $!";
    while (<REPORTFILE>) {
      $web_page_html .= $_;
    }
    close(REPORTFILE);
  };
  if ($@){
    log_error("p_rprttldt3", $@);
    return (99, $internal_error);
  }

  #
  # Read the user status file to get last_report_update_date
  #   key = user_id + '-' + status_type
  #     status_type = 1 = last_indexed_date
  #     status_type = 2 = last_search_use_date
  #     status_type = 3 = member_status (F = free, S = subscription)
  #     status_type = 4 = config_status (I, IQ, S, IS, IQS)
  #     status_type = 5 = last montly/summary report update date
  #
  eval {
    use Fcntl;
    tie %user_status_dbfile, $db_package, $USER_STATUS_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_STATUS_DB_FILE: $!";
    $db_key = $user_id.'-5';
    if ($user_status_dbfile{$db_key}) {
      $temp_time = $user_status_dbfile{$db_key};
      $last_update_date = localtime $temp_time;
    } else {
      $last_update_date = "- Not yet updated";
    }
    untie %user_status_dbfile;
  };
  if ($@) {
    log_error("p_rprttldt4", $@);
    return (99, $internal_error);
  }


  # substitute general values in the report page
  $web_page_html =~ s/:::grepin-fld00:::/$user_id/g;
  $web_page_html =~ s/:::grepin-fld01:::/$session_id/g;
  $web_page_html =~ s/:::grepin-f5632:::/$last_update_date/g;

  # create match report rows
  $web_page_html   =~ /:::grepin-start-match-row:::.*:::grepin-end-match-row:::/s;
  $row_html_before = $&;

  $row_html_after = undef;
  if ($match_row_count == 0) {
    $row_html_temp  = $row_html_before;
    $row_html_temp  =~ s/:::grepin-i5630:::/-N\/A-/g; # search terms
    $row_html_temp  =~ s/:::grepin-i5631:::/-N\/A-/g; # num of times
    $row_html_temp  =~ s/:::grepin-i5632:::/-N\/A-/g; # next prev
    $row_html_after .= $row_html_temp;
  } else {
    $i = 0;
    while ($match_report_array[$i]) {
      @row_array = split /:::/, $match_report_array[$i];
      $row_html_temp   = $row_html_before;
      $row_html_temp =~ s/:::grepin-i5630:::/$row_array[0]/g; # search terms
      $row_html_temp =~ s/:::grepin-i5631:::/$row_array[1]/g; # num of times
      $row_html_temp =~ s/:::grepin-i5632:::/$row_array[2]/g; # next prev
      $row_html_after .= $row_html_temp;
      $i++;
      $match_count += $row_array[1];
    }
  }

  $web_page_html =~ s/:::grepin-start-match-row:::.*:::grepin-end-match-row:::/$row_html_after/gs;
  $web_page_html =~ s/(:::grepin-start-match-row:::)|(:::grepin-end-match-row:::)//gs;

  # create nomatch report rows
  $web_page_html   =~ /:::grepin-start-nomatch-row:::.*:::grepin-end-nomatch-row:::/s;
  $row_html_before = $&;

  $row_html_after = undef;
  if ($nomatch_row_count == 0) {
    $row_html_temp   = $row_html_before;
    $row_html_temp =~ s/:::grepin-i5633:::/-N\/A-/g; # search terms
    $row_html_temp =~ s/:::grepin-i5634:::/-N\/A-/g; # num of times
    $row_html_after .= $row_html_temp;
  } else {
    $i = 0;
    while ($nomatch_report_array[$i]) {
      @row_array = split /:::/, $nomatch_report_array[$i];
      $row_html_temp  = $row_html_before;
      $row_html_temp  =~ s/:::grepin-i5633:::/$row_array[0]/g; # search terms
      $row_html_temp  =~ s/:::grepin-i5634:::/$row_array[1]/g; # num of times
      $row_html_after .= $row_html_temp;
      $i++;
      $nomatch_count += $row_array[1];
    }
  }

  $web_page_html =~ s/:::grepin-f5630:::/$match_count/g;
  $web_page_html =~ s/:::grepin-f5631:::/$nomatch_count/g;
  $web_page_html =~ s/:::grepin-start-nomatch-row:::.*:::grepin-end-nomatch-row:::/$row_html_after/gs;
  $web_page_html =~ s/(:::grepin-start-nomatch-row:::)|(:::grepin-end-nomatch-row:::)//gs;
  $web_page_html =~ s/:::grepin-.*::://g;         # space out all the other fields

  print $web_page_html;

  return (90, undef);
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



