#!/usr/bin/perl 
#$rcs = ' $Id: bsendrprt.pl,v 1.0 2004/03/30 00:00:00 Exp $ ' ;

BEGIN {
   use CGI::Carp qw(carpout);
   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/errorlog.txt")
       or die "Unable to append to errorlog: $!\n";
   carpout(*ERRORLOG);
}

print "Content-Type: text/html\n\n";
print "at the beginning\n";

# Grepin Search and Services
# Copyright (C) 2004 Grepin Search and Services <contact@grepin.com>

use Fcntl;
use MIME::Lite;
use CGI;

# If bsendrprt.pl uses too much CPU, comment in the next two lines. "nice" takes
# a value between 0 (normal) and 19 (lowest priority). Tested on Linux only.
#use POSIX qw(nice);
#nice 19;
  
# added program path to @INC because it fails to find ./conf.pl if
# started from other directory
{ 
  # block is for $1 not mantaining its value
  $0 =~ /(.*)(\\|\/)/;
  push @INC, $1 if $1;
}

package main;

my $query = new CGI;

my $password = $query->param('pwd');
if ($password ne 'mzlapqnxksowbcjdie'){
  print "You are not authorized to invoke this program.\n";
  exit;
}

my $MAIN_DIR = '/home/grepinco/public_html/cgi-bin/';
my $USER_DIR = $MAIN_DIR.'users/';
my $LOG_DIR  = $MAIN_DIR.'log/';

my $SRCH_DIR      = $MAIN_DIR.'search/';
my $SRCH_USER_DIR = $SRCH_DIR.'users/';

my $LOG_FILE = $LOG_DIR.'joblog.txt';

my $USER_PROFILE_DB_FILE       = $USER_DIR.'userprof';
my $JOB_STATUS_DB_FILE         = $USER_DIR.'jobstatus';
my $QUEUE_DB_FILE              = $USER_DIR.'queue';
my $REPORT_QUEUE_DB_FILE       = $USER_DIR.'rprtqueue';

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
  log_error("bsendrprt1", "The DB_File module was not found.");
  exit;
}

print "<br>before scheduler\n";
################### ====== scheduler ======= #######################
  my %job_status_dbfile;
  my $job_id;
  my $sch_start_time;
  my $sch_end_time;
  my $db_key;
  my $user_id;
  my $total_pages;
  my %queue_dbfile;
  my $last_used_queue;
  my $last_processed_queue;
  my %report_queue_dbfile;
  my $queue_time;
  my $page_url;
  my ($pgm_return_code, $total_records);
  my %user_prof;
  my ($complete_time, $msgtxt, $mail_rtrn_code, $mail_rtrn_msg);
  my ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18);

  #
  # Check to see if there is another bsendrprt running. If yes, then exist.
  #
  eval {
    use Fcntl;
    tie %job_status_dbfile, $db_package, $JOB_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $JOB_STATUS_DB_FILE: $!";
    $db_key = "bsendrprt";
    if (!defined $job_status_dbfile{$db_key}) {
      $job_status_dbfile{$db_key} = time();
      $job_id = "bsendrprt".time();
      # logging that the job has started
      log_error ($job_id, "----------- started -----------");
print "<br>error2 - success job-status-dbfile - $db_key - $job_status_dbfile{$db_key}\n";
    } else {
      log_error ("bsendrprt2", "Exiting as another bsendrprt is running");
print "<br>error2 exiting as another bsendrprt is running\n";
      untie %job_status_dbfile;
      exit;
    }
print "<br>error1 - success\n";
  };
  if ($@) {
    log_error ("bsendrprt3", $@);
print "<br>error1 $@\n";
    exit;
  }

  #
  # Read the queue file to get the next queue number to be processed.
  #
  eval {
    use Fcntl;
    tie %queue_dbfile, $db_package, $QUEUE_DB_FILE, O_RDONLY, 0755 or die "Cannot open $QUEUE_DB_FILE: $!";
    $db_key = "report";
    if (defined $queue_dbfile{$db_key}) {
      ($last_used_queue, $last_processed_queue) = unpack("C/A* C/A*", $queue_dbfile{$db_key});

print "<br>error4 - success queue-dbfile - $db_key, $queue_dbfile{$db_key}, $last_used_queue, $last_processed_queue - $QUEUE_DB_FILE\n";
      untie %queue_dbfile;
    } else {
      log_error ("bsendrprt4", "Exiting as the queue_db_file has no indexing queue present.");
print "<br>error4 exiting as the queue_db_file is empty\n";
      delete $job_status_dbfile{$db_key};
      untie %job_status_dbfile;
      untie %queue_dbfile;
      exit;
    }

    untie %job_status_dbfile;

print "<br>error3 - success\n";
  };
  if ($@) {
    log_error ("bsendrprt5", $@);
print "<br>error3 $@\n";
    untie %job_status_dbfile;
    exit;
  }
  $last_processed_queue++;

  #
  # If the last processed queue number is less than the largest queue number, proceed. Else exit.
  #
  while ($last_processed_queue <= $last_used_queue) {

print "<br>last-processed-queue = $last_processed_queue \n";
print "<br>last_used_queue      = $last_used_queue \n";
    #
    # Get the next user to be processed.
    #
    $user_id = undef;
    eval {
      use Fcntl;
      tie %report_queue_dbfile, $db_package, $REPORT_QUEUE_DB_FILE, O_RDONLY, 0755 or die "Cannot open $REPORT_QUEUE_DB_FILE: $!";   
      $db_key = $last_processed_queue;
      if (defined $report_queue_dbfile{$db_key}) {
print "<br>report-queue-dbfile - last-processed-queue is present \n";
        ($user_id, $report_type, $d1, $d2, $d3, $d4, $d5) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $report_queue_dbfile{$db_key});
      }
      untie %report_queue_dbfile;
print "<br>error5 - success\n";
    };
    if ($@) {
      log_error ("bsendrprt6", $@);
print "<br>error5 $@\n";
      exit;
    }

    $sch_start_time = time();

    if (defined $user_id) {

      #
      # form and send the report
      #

print "<br> before p_sendrprt - userid = $user_id\n";
      ($pgm_return_code, $total_records) = p_sendrprt($user_id, $report_type);
print " pgm_return_code = $pgm_return_code \n";
      $sch_end_time   = time();

      #
      # Update the report_queue dbfile with the results.
      #
      eval {
        use Fcntl;
        tie %report_queue_dbfile, $db_package, $REPORT_QUEUE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $REPORT_QUEUE_DB_FILE: $!";   

        $db_key = $last_processed_queue;
        ($user_id, $report_type, $queue_time, $d1, $d2, $d3, $d4) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $report_queue_dbfile{$db_key});
        $report_queue_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_id, $report_type, $queue_time, $sch_start_time, $sch_end_time, $total_records);
        untie %report_queue_dbfile;
print "<br>error9 - success index-queue-dbfile - $user_id, $last_processed_queue\n";
      };
      if ($@) {
        log_error ("bsendrprt7", $@);
print "<br>error9 $@ \n";
        exit;
      }

      #
      # Update the queue dbfile with the queue number that was processed.
      #
      eval {
        use Fcntl;
        tie %queue_dbfile, $db_package, $QUEUE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $QUEUE_DB_FILE: $!";

        $db_key = "report";
        ($last_used_queue, $d1) = unpack("C/A* C/A*", $queue_dbfile{$db_key});
        $queue_dbfile{$db_key} = pack("C/A* C/A*", $last_used_queue, $last_processed_queue);
print "<br>error10 - success queue-dbfile dbkey lastused lastprocessed - $db_key, $queue_dbfile{$db_key}, $last_used_queue, $last_processed_queue - $QUEUE_DB_FILE\n";
        untie %queue_dbfile;
      };

      if ($@) {
        log_error ("bsendrprt8", $@);
print "<br>error10 $@ \n";
        exit;
      }

    } else {
      log_error("bsendrprt9", "The last processed queue is not found in indexer queue database. Last processed queue = $last_processed_queue");
print "<br>error11 last processed queue not found - queue = $last_processed_queue \n";
    }

    $last_processed_queue++;
  }

  #
  # At closing this bsendrprt, update the job_status dbfile to indicate that it is not running any more.
  #
  eval {
    use Fcntl;
    tie %job_status_dbfile, $db_package, $JOB_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $JOB_STATUS_DB_FILE: $!";
    $db_key = "bsendrprt";
print "<br>error12 - before jobstatusdbfile - $db_key, $job_status_dbfile{$db_key}\n";
    delete $job_status_dbfile{$db_key};
    untie %job_status_dbfile;
print "<br>error12 - success jobstatusdbfile - $db_key, $job_status_dbfile{$db_key}\n";
  };

  if ($@) {
    log_error ("bsendrprt10", $@);
print "<br>error12 $@ \n";
  }

  # logging that the job has ended
  log_error ($job_id, "------------ ended ------------");

  exit;






##########  SUBROUTINES START HERE ########################


sub p_sendrprt {
# send report to the user
# return codes
#  0 = success
# 99 = database error

  my $user_id     = shift;
  my $report_type = shift;
  my $email_id;
  my $month;
  my ($rprt_rtrn_code, $report_content);
  my ($mail_rtrn_code, $mail_rtrn_msg);
  my %user_prof;

  use Fcntl;

  if ($report_type == 'detail') {
    ($rprt_rtrn_code, $report_content) = p_detail($user_id);
  } elsif ($report_type == 'tilldate') {
    ($rprt_rtrn_code, $report_content) = p_tilldate($user_id);
  } else {
    if ($report_type == 'monthly') {
      $month = (localtime time())[4] + 1;
    } else {
      $month = $report_type;
    }
    ($rprt_rtrn_code, $report_content) = p_monthly($user_id, $month);
  }

  if ($rprt_rtrn_code != 0) {
    return (01, $report_content);
  }

  #
  # Get the email_id of the user
  #
  eval {
    tie %user_prof, $db_package, $USER_PROFILE_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";   
    $db_key = $user_id;
    ($email_id, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_prof{$db_key});
     untie %user_prof;
print "<br>error7 - success user-id and config-status - $user_id, $email_id\n";
  };
  if ($@){
    log_error("bsendrprt11", $@);
print "<br>error7 $@ \n";
    return (99, $@);
  }

  #
  # Send an email to the user.
  #
  ($mail_rtrn_code, $mail_rtrn_msg) = p_sendemail("reports\@grepin.com","contact\@grepin.com",$email_id,"Here is your search report...",$report_content,, );
  if ($mail_rtrn_code > 0) {
    log_error ("bsendrprt12", $mail_rtrn_msg);
print "<br>error8 $mail_rtrn_msg \n";
    return (99, $mail_rtrn_msg);
  }
print "<br>error8 - success - $email_id\n";

  return (0, "success");

}


###############################################################################


sub p_detail {
# format detail report
# return codes
#  0 = success
# 99 = database error

  my $user_id     = shift;
  my ($rprt_rtrn_code, $report_content);
  my ($mail_rtrn_code, $mail_rtrn_msg);
  my %user_prof;
  my $yday = (localtime time())[7];
  my $searchlogfile_base = $SRCH_USER_DIR.$user_id.'/log/searchlog';
  my $searchlogfile;
  my $max_length = 0;
  my ($search_count, $mail_record, $mail_report, $heading);
  my @report_array = ();
  my @record_array = ();
  my ($loop, $i);

  use Fcntl;

  @report_array = ();
  for ($loop = 1; $loop <= 3; $loop++) {
    $searchlogfile = $searchlogfile_base.$yday;
    if (-e $searchlogfile) {					# if this file exists
      eval {
        open (SEARCHLOG, $searchlogfile) or die "Cannot open searchlogfile '$searchlogfile' for reading: $!";
        @report_array = (@report_array, (reverse <SEARCHLOG>));
        close(SEARCHLOG);
      };
      if ($@){
        log_error("bsendrprt13", $@);
        return (99, $@);
      }
    }
    if ($yday == 0) {						# this is jan 1st
      $yday = 365;						# this is dec 31st of leap year
      $searchlogfile = $searchlogfile_base.$yday;
      if (!(-e $searchlogfile)) {				# if dec 31st of leap year does not exist
        $yday = 364;						# making it dec 31st of non leap year
      }
    } else {
      $yday--;
    }
  }

  $search_count = $#report_array + 1;

  foreach (@report_array) {
    @record_array = split /:::/, $_;
    if ($max_length < length $record_array[0]) {
      $max_length = length $record_array[0];
    }
  }

  foreach (@report_array) {
    @record_array = ();
    @record_array = split /:::/, $_;
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9) = localtime($record_array[1]);
    $d6 = $d6 + 1900;
    $record_array[1] = $d6.'/'.$d5.'/'.$d4.' '.$d3.':'.$d2.':'.$d1;
    if ($record_array[4] == 0) {
      $record_array[4] = 'No';
    } else {
      $record_array[4] = 'Yes';
    }
    $mail_record = pack("A4 A[$max_length] A2 A21 A10 A16 A11 A*", ' ', $record_array[0], ' ', $record_array[1], $record_array[2], $record_array[3], $record_array[4], $record_array[5]);
    $mail_report .= $mail_record . '\n';
  }
  @report_array = ();

  $heading  = pack("A4 A[$max_length]", ' ', 'Terms');
  $heading .= '  Search Time          Duration  Num of Results  Next/Prev  Source';

  $mail_report = <<__STOP_OF_MESSAGE__;
Dear Grepin member,

Here are the details of the search activity on your web site
in the last 3 days.

$heading

$mail_report

     Total number of searches performed = $search_count

__STOP_OF_MESSAGE__

  return (0, $mail_report);

}



###############################################################################


sub p_monthly {
# format montly report
# return codes
#  0 = success
# 99 = database error

  my $user_id = shift;
  my $month   = shift;
  my $USERSEARCHLOG_MONTH_DB_FILE  = $SRCH_USER_DIR.$user_id.'/log/srchlogmth'.$month;
  my $USERNOMATCHLOG_MONTH_DB_FILE = $SRCH_USER_DIR.$user_id.'/log/nomatchmth'.$month;
  my %usersearchlogmth_dbfile;
  my %usernomatchlogmth_dbfile;
  my $search_max_length = 0;
  my $nomatch_max_length = 0;
  my ($search_count, $mail_record, $search_mail_report, $nomatch_count, $nomatch_mail_report, $search_heading, $nomatch_heading);
  my @report_array = ();
  my @record_array = ();
  my @month_names = qw<January February March April May June July August September October November December>;

  use Fcntl;

  eval {
    use Fcntl;
    tie %usersearchlogmth_dbfile, $db_package, $USERSEARCHLOG_MONTH_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USERSEARCHLOG_MONTH_DB_FILE: $!";
    tie %usernomatchlogmth_dbfile, $db_package, $USERNOMATCHLOG_MONTH_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USERNOMATCHLOG_MONTH_DB_FILE: $!";
  };
  if ($@) {
    log_error ("bsendrprt14", $@);
print "<br>error4 $@\n";
    return (99, $@);
  }

  foreach $term (keys %usersearchlogmth_dbfile) {
    if ($search_max_length < length $term) {
      $search_max_length = length $term;
    }
  }

  foreach $term (keys %usernomatchlogmth_dbfile) {
    if ($nomatch_max_length < length $term) {
      $nomatch_max_length = length $term;
    }
  }

  foreach $term (keys %usersearchlogmth_dbfile) {
    ($num_of_times, $nextprev) = unpack("C/A* C/A*", $usersearchlogmth_dbfile{$term});
    $mail_record = pack("A4 A[$search_max_length] A2 A14 A*", ' ', $term, ' ', $num_of_times, $nextprev);
    $search_mail_report .= $mail_record . '\n';
    $search_count++;
  }

  foreach $term (keys %usernomatchlogmth_dbfile) {
    $num_of_times = $usersearchlogmth_dbfile{$term};
    $mail_record = pack("A4 A[$nomatch_max_length] A2 A*", ' ', $term, ' ', $num_of_times);
    $nomatch_mail_report .= $mail_record . '\n';
    $nomatch_count++;
  }

  $search_heading  = pack("A4 A[$search_max_length]", ' ', 'Terms');
  $search_heading  .= '  Num of Times  Next/Prev';
  $nomatch_heading  = pack("A4 A[$nomatch_max_length]", ' ', 'Terms');
  $nomatch_heading .= '  Num of Times';

  $mail_report = <<__STOP_OF_MESSAGE__;
Dear Grepin member,

Here are the details of the search activity on your web site
during $month_names[$month].

$search_heading

$search_mail_report

     Total number of successful searches performed = $search_count


$nomatch_heading

$nomatch_mail_report

     Total number of failed searches performed = $nomatch_count

__STOP_OF_MESSAGE__

  return (0, $mail_report);

}



###############################################################################


sub p_tilldate {
# format tilldate report
# return codes
#  0 = success
# 99 = database error

  my $user_id = shift;
  my $USERSEARCHLOG_DB_FILE  = $SRCH_USER_DIR.$user_id.'/log/srchlog';
  my $USERNOMATCHLOG_DB_FILE = $SRCH_USER_DIR.$user_id.'/log/nomatchlog';
  my %usersearchlog_dbfile;
  my %usernomatchlog_dbfile;
  my $search_max_length = 0;
  my $nomatch_max_length = 0;
  my ($search_count, $mail_record, $search_mail_report, $nomatch_count, $nomatch_mail_report, $search_heading, $nomatch_heading);
  my @report_array = ();
  my @record_array = ();

  use Fcntl;

  eval {
    use Fcntl;
    tie %usersearchlog_dbfile, $db_package, $USERSEARCHLOG_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USERSEARCHLOG_DB_FILE: $!";
    tie %usernomatchlog_dbfile, $db_package, $USERNOMATCHLOG_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USERNOMATCHLOG_DB_FILE: $!";
  };
  if ($@) {
    log_error ("bsendrprt15", $@);
print "<br>error4 $@\n";
    return (99, $@);
  }

  foreach $term (keys %usersearchlog_dbfile) {
    if ($search_max_length < length $term) {
      $search_max_length = length $term;
    }
  }

  foreach $term (keys %usernomatchlog_dbfile) {
    if ($nomatch_max_length < length $term) {
      $nomatch_max_length = length $term;
    }
  }

  foreach $term (keys %usersearchlog_dbfile) {
    ($num_of_times, $nextprev) = unpack("C/A* C/A*", $usersearchlog_dbfile{$term});
    $mail_record = pack("A4 A[$search_max_length] A2 A14 A*", ' ', $term, ' ', $num_of_times, $nextprev);
    $search_mail_report .= $mail_record . '\n';
    $search_count++;
  }

  foreach $term (keys %usernomatchlog_dbfile) {
    $num_of_times = $usersearchlog_dbfile{$term};
    $mail_record = pack("A4 A[$nomatch_max_length] A2 A*", ' ', $term, ' ', $num_of_times);
    $nomatch_mail_report .= $mail_record . '\n';
    $nomatch_count++;
  }

  $search_heading  = pack("A4 A[$search_max_length]", ' ', 'Terms');
  $search_heading  .= '  Num of Times  Next/Prev';
  $nomatch_heading  = pack("A4 A[$nomatch_max_length]", ' ', 'Terms');
  $nomatch_heading .= '  Num of Times';

  $mail_report = <<__STOP_OF_MESSAGE__;
Dear Grepin member,

Here are the details of the search activity on your web site 
since you have become member of Grepin Search and services.

$search_heading

$search_mail_report

     Total number of successful searches performed = $search_count


$nomatch_heading

$nomatch_mail_report

     Total number of failed searches performed = $nomatch_count

__STOP_OF_MESSAGE__

  return (0, $mail_report);

}



###############################################################################


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

###############################################################################

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
  my $internal_error = "An internal error occurred. Sorry for the inconvenience.<br /> Please inform the webmaster about the error at contact\@grepin.com.";

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
    log_error ("p_sendemail1 - bsendrprt", $@);
    return (99, $internal_error);
  }
  return(0, "success");

}


1;