#!/usr/bin/perl -w
#$rcs = ' $Id: grepinbot.pl,v 1.0 2004/03/30 00:00:00 Exp $ ' ;

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
#   use CGI::Carp qw(carpout);
#   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/errorlog.txt")
#       or die "Unable to append to errorlog: $!\n";
#   carpout(*ERRORLOG);
}

print "Content-Type: text/html\n\n";
print "at the beginning\n";

# Grepin Search and Services
# Copyright (C) 2004 Grepin Search and Services <contact@grepin.com>

use Fcntl;
use MIME::Lite;

#use Compress::Zlib;
#my $to_be_compressed;
use CGI;

# If grepinbot.pl uses too much CPU, comment in the next two lines. "nice" takes
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

#my $password = $query->param('pwd');
#if ($password ne 'mzlapqnxksowbcjdie'){
#  print "You are not authorized to invoke this program.\n";
#  exit;
#}

my $MAIN_DIR     = '/home/grepinco/public_html/cgi-bin/';
my $USER_DIR     = $MAIN_DIR.'users/';
my $USER_DIR_DIR = $USER_DIR.'users/';
my $LOG_DIR      = $MAIN_DIR.'log/';

my $SRCH_DIR      = $MAIN_DIR.'search/';
my $SRCH_USER_DIR = $SRCH_DIR.'users/';

my $LOG_FILE      = $LOG_DIR.'joblog.txt';
my $LOG_USER_FILE = $LOG_DIR.'userstatlog.txt';

my $USER_PROFILE_DB_FILE       = $USER_DIR.'userprof';
my $USER_INDEX_DATA_DB_FILE    = $USER_DIR.'userindxdata';
my $JOB_STATUS_DB_FILE         = $USER_DIR.'jobstatus';
my $QUEUE_DB_FILE              = $USER_DIR.'queue';
my $INDEX_QUEUE_DB_FILE        = $USER_DIR.'indxqueue';
my $USER_STATUS_DB_FILE        = $USER_DIR.'userstatus';

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
  log_error("grepinbot1", "The DB_File module was not found.");
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
  my %index_queue_dbfile;
  my $queue_time;
  my $page_url;
  my ($index_return_code, $total_pages, $total_terms, $total_exclude_pages, $no_index_robot_pages);
  my ($base_url, $start_url, $max_pages, $limit_urls, $exclude_pages, $stop_words);
  my %user_prof;
  my ($email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4);
  my ($complete_time, $msgtxt, $mail_rtrn_code, $mail_rtrn_msg);
  my ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15);

  #
  # Check to see if there is another grepinbot running. If yes, then exist.
  #
  eval {
    use Fcntl;
    tie %job_status_dbfile, $db_package, $JOB_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $JOB_STATUS_DB_FILE: $!";
    $db_key = "grepinbot";
    if (!defined $job_status_dbfile{$db_key}) {
      $job_status_dbfile{$db_key} = time();
      $job_id = "grepinbot".time();
      # logging that the job has started
      log_error ($job_id, "----------- started -----------");
print "<br>error2 - success job-status-dbfile - $db_key - $job_status_dbfile{$db_key}\n";
    } elsif (time() - $job_status_dbfile{$db_key} < 86399) {
      log_error ("grepinbot2", "Exiting as another grepinbot is running");
print "<br>error2 exiting as another grepinbot is running\n";
      untie %job_status_dbfile;
      exit;
    } else {
      $job_status_dbfile{$db_key} = time();
      $job_id = "grepinbot".time();
      # logging again that the job has started
      log_error ($job_id, "----------- started -----------");
    }
print "<br>error1 - success\n";
  };
  if ($@) {
    log_error ("grepinbot3", $@);
print "<br>error1 $@\n";
    exit;
  }

  #
  # Read the queue file to get the next queue number to be processed.
  #
  eval {
    use Fcntl;
    tie %queue_dbfile, $db_package, $QUEUE_DB_FILE, O_RDONLY, 0755 or die "Cannot open $QUEUE_DB_FILE: $!";
    $db_key = "index";
    if (defined $queue_dbfile{$db_key}) {
      ($last_used_queue, $last_processed_queue) = unpack("C/A* C/A*", $queue_dbfile{$db_key});

print "<br>error4 - success queue-dbfile - $db_key, $queue_dbfile{$db_key}, $last_used_queue, $last_processed_queue - $QUEUE_DB_FILE\n";
      untie %queue_dbfile;
    } else {
      log_error ("grepinbot4", "Exiting as the queue_db_file has no indexing queue present.");
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
    log_error ("grepinbot5", $@);
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
      tie %index_queue_dbfile, $db_package, $INDEX_QUEUE_DB_FILE, O_RDONLY, 0755 or die "Cannot open $INDEX_QUEUE_DB_FILE: $!";   
      $db_key = $last_processed_queue;
      if (defined $index_queue_dbfile{$db_key}) {
print "<br>index-queue-dbfile - last-processed-queue is present \n";
        ($user_id, $d1, $d2, $d3, $d4, $d5, $d6) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $index_queue_dbfile{$db_key});
      }
      untie %index_queue_dbfile;
print "<br>error5 - success\n";
    };
    if ($@) {
      log_error ("grepinbot6", $@);
print "<br>error5 $@\n";
      exit;
    }

    $sch_start_time = time();

    if (defined $user_id) {

      #
      # Submit indexer
      #

      require 'sub_indexer.pl';

print "<br> before indexer - userid = $user_id\n";
      p_loguser($job_id, $user_id, $total_pages, $total_terms, $total_exclude_pages, $no_index_robot_pages, ' ');
      ($index_return_code, $total_pages, $total_terms, $total_exclude_pages, $no_index_robot_pages) = p_indexer($user_id, $USER_DIR_DIR);
      p_loguser($job_id, $user_id, $total_pages, $total_terms, $total_exclude_pages, $no_index_robot_pages, $index_return_code);

print " index_return_code = $index_return_code \n";
      if ($index_return_code == 0) {

        $sch_end_time   = time();

        #
        # Update user_index dbfile with index results.
        #
        eval {
          use Fcntl;
          tie %user_index_data, $db_package, $USER_INDEX_DATA_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_INDEX_DATA_DB_FILE: $!";   
          $db_key = $user_id;
          ($base_url, $start_url, $max_pages, $limit_urls, $exclude_pages, $stop_words, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_index_data{$db_key});
          $d1 = undef;
          $d2 = undef;
          $d3 = undef;
          $user_index_data{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $base_url, $start_url, $max_pages, $limit_urls, $exclude_pages, $stop_words, $sch_end_time, $total_pages, $total_terms, ($sch_end_time - $sch_start_time),$total_exclude_pages,$no_index_robot_pages, $d1, $d2, $d3);
          untie %user_index_data;
print "<br>error6 - success - $user_id\n";
        };
        if ($@){
          log_error ("grepinbot7", $@);
print "<br>error6 $@ \n";
        }

        #
        # Update the user_profile dbfile with the status to 'indexed'.
        #
        eval {
          use Fcntl;
          tie %user_prof, $db_package, $USER_PROFILE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";   
          $db_key = $user_id;
          ($email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_prof{$db_key});
          if ($config_status eq ("IQS" || "S" || "IS")) {
            $config_status = "IS"
          } else {
            $config_status = "I"
          }
          $user_prof{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4);
          untie %user_prof;
print "<br>error7 - success user-id and config-status - $user_id, $config_status\n";
        };
        if ($@){
          log_error("grepinbot8", $@);
print "<br>error7 $@ \n";
        }

        #
        # update the user_status_dbfile with last_indexed_date and config_status
        #   key = user_id + '-' + status_type
        #     status_type = 1 = last_indexed_date
        #     status_type = 2 = last_search_use_date
        #     status_type = 3 = member_status (F = free, S = subscription)
        #     status_type = 4 = config_status (I, IQ, S, IS, IQS)
        #
        eval {
          use Fcntl;
          tie %user_status_dbfile, $db_package, $USER_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_STATUS_DB_FILE: $!";
          $db_key = $user_id.'-1';
          $user_status_dbfile{$db_key} = $sch_end_time;
print "<br>error12 - userstatusdbfile - $db_key, $user_status_dbfile{$db_key}\n";
          $db_key = $user_id.'-4';
          $user_status_dbfile{$db_key} = $config_status;
print "<br>error12 - userstatusdbfile - $db_key, $user_status_dbfile{$db_key}\n";
          untie %user_status_dbfile;
        };

        if ($@) {
          log_error ("grepinbot9", $@);
print "<br>error12 $@ \n";
        }

        #
        # Send an email to the user.
        #
        $complete_time = localtime time();
        $msgtxt = <<__STOP_OF_MAIL__;
Dear Grepin member,

Your Web Site '$base_url' has been indexed. 
Following are the results of the indexing:

  Crawler started at       : $start_url
  Number of pages indexed  : $total_pages
  Number of terms indexed  : $total_terms
  Number of pages excluded : $total_exclude_pages
  Indexing finished at     : $complete_time


If you haven't configured your search results page,
please do so by logging into members section at
http://www.grepin.com/members.html 
and click on 'Configure Search Results Page'.

If you have configured your search results page,
you can start using the search on your Web Site.
For more instructions about the search box html, 
log in at http://www.grepin.com/login.html
and click on 'copy html' on the left nav bar.

If you have any questions, please feel free to 
contact us at questions\@grepin.com

Sincerely,
Grepin Search and Services.

__STOP_OF_MAIL__

        ($mail_rtrn_code, $mail_rtrn_msg) = p_sendemail("info\@grepin.com","contact\@grepin.com",$email_id,"Your Site has been Indexed.",$msgtxt,, );
        if ($mail_rtrn_code > 0) {
          log_error ("grepinbot10", $mail_rtrn_msg);
print "<br>error8 $mail_rtrn_msg \n";
        }
print "<br>error8 - success - $email_id\n";


################ end indexing and updating user index data #################################

      }

      #
      # Update the index_queue dbfile with the index results.
      #
      eval {
        use Fcntl;
        tie %index_queue_dbfile, $db_package, $INDEX_QUEUE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $INDEX_QUEUE_DB_FILE: $!";   

        $db_key = $last_processed_queue;
        ($user_id, $queue_time, $page_url, $d1, $d2, $d3, $d4) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $index_queue_dbfile{$db_key});
        $index_queue_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_id, $queue_time, $page_url, $index_return_code, $sch_start_time, $sch_end_time, $total_pages);
        untie %index_queue_dbfile;
print "<br>error9 - success index-queue-dbfile - $user_id, $last_processed_queue\n";
      };
      if ($@) {
        log_error ("grepinbot11", $@);
print "<br>error9 $@ \n";
        exit;
      }

      #
      # Update the queue dbfile with the queue number that was processed.
      #
      eval {
        use Fcntl;
        tie %queue_dbfile, $db_package, $QUEUE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $QUEUE_DB_FILE: $!";

        $db_key = "index";
        ($last_used_queue, $d1) = unpack("C/A* C/A*", $queue_dbfile{$db_key});
        $queue_dbfile{$db_key} = pack("C/A* C/A*", $last_used_queue, $last_processed_queue);
print "<br>error10 - success queue-dbfile dbkey lastused lastprocessed - $db_key, $queue_dbfile{$db_key}, $last_used_queue, $last_processed_queue - $QUEUE_DB_FILE\n";
        untie %queue_dbfile;
      };

      if ($@) {
        log_error ("grepinbot12", $@);
print "<br>error10 $@ \n";
        exit;
      }

    } else {
      log_error("grepinbot13", "The last processed queue is not found in indexer queue database. Last processed queue = $last_processed_queue");
print "<br>error11 last processed queue not found - queue = $last_processed_queue \n";
    }

    $last_processed_queue++;
  }

  #
  # At closing this grepinbot, update the job_status dbfile to indicate that it is not running any more.
  #
  eval {
    use Fcntl;
    tie %job_status_dbfile, $db_package, $JOB_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $JOB_STATUS_DB_FILE: $!";
    $db_key = "grepinbot";
print "<br>error12 - before jobstatusdbfile - $db_key, $job_status_dbfile{$db_key}\n";
    delete $job_status_dbfile{$db_key};
    untie %job_status_dbfile;
print "<br>error12 - success jobstatusdbfile - $db_key, $job_status_dbfile{$db_key}\n";
  };

  if ($@) {
    log_error ("grepinbot14", $@);
print "<br>error12 $@ \n";
  }

  # logging that the job has ended
  log_error ($job_id, "------------ ended ------------");

  exit;






##########  SUBROUTINES START HERE ########################


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
    log_error ("p_sendemail1 - grepinbot", $@);
    return (99, $internal_error);
  }
  return(0, "success");

}

sub p_loguser {
# log user in the log user file
# return codes
#  0 = success
# 99 = database error

  my $job_id               = shift;
  my $user_id              = shift;
  my $total_pages          = shift;
  my $total_terms          = shift;
  my $total_exclude_pages  = shift;
  my $no_index_robot_pages = shift;
  my $index_return_code    = shift;

  my @line = ();

  use Fcntl;

  push(@line, $job_id || '-',
              $user_id || '-',
              localtime time() || '-',
              $total_pages || '-',
              $total_terms || '-',
              $total_exclude_pages || '-',
              $no_index_robot_pages || '-',
              $index_return_code || '-');

  eval {
    use Fcntl ':flock';        # import LOCK_* constants
    open(LOGUSER, ">>$LOG_USER_FILE") or die "Cannot open logfile '$LOG_USER_FILE' for writing: $!";
    flock(LOGUSER, LOCK_EX);
    seek(LOGUSER, 0, 2);
    print LOGUSER join(':::', @line).":::\n";
    flock(LOGUSER, LOCK_UN);
    close(LOGUSER);
  };

  return (0, "success");

}


1;
