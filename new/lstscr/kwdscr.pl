#!/usr/bin/perl -w

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
#   use CGI::Carp qw(carpout);
#   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/kwdscrerr.txt")
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
  my $LOG_FILE   = $LOG_DIR.'kwdscrlog.txt';
  my $LOG_SOURCE = $LOG_DIR.'sourcelog.txt';

  my $SESSION_DB_FILE   = $USER_DIR.'session';
  my $PWRLST_DB_FILE    = $USER_DIR.'pwrlst';

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
    push(@line, 'kwdscr ------------- ',
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
    log_error("kwdscr1", "The DB_File module was not found.");
    print "$internal_error \n\n";
    exit;
  }

####  DO NOT CALL ANY SUB-PROGRAM UNTIL THIS POINT ########


  if (!$cmd) {
    $cmd = "list";
  }

  if ($session_id) {
    ($return_code, $return_msg) = p_sessnchk();
    if ($return_code != 0) {
      $user_id    = undef;
      $session_id = undef;
      if (($cmd eq "list") || ($cmd eq "add") || ($cmd eq "disp") || ($cmd eq "edit") || ($cmd eq "del") || ($cmd eq "prdlist") || ($cmd eq "keyword")) {
        ($return_code, $return_msg) = e_login(5190, $return_msg);
        $valid_sid = 'F';
      }
    }
  } else {
    if (($cmd eq "list") || ($cmd eq "add") || ($cmd eq "disp") || ($cmd eq "edit") || ($cmd eq "del") || ($cmd eq "prdlist") || ($cmd eq "keyword")) {
      ($return_code, $return_msg) = e_login(5190, "You have to login as a member to access this page.");
      $user_id = undef;
      $valid_sid = 'F';
    }
  }

  if ($valid_sid eq 'T') {
    if (($cmd eq "list") || ($cmd eq "add") || ($cmd eq "disp") || ($cmd eq "edit") || ($cmd eq "del") || ($cmd eq "prdlist") || ($cmd eq "keyword")) {
      ($return_code, $return_msg) = p_memberchk();
      if ($return_code != 0) {
        $cmd = "home";
      }
    }
    if ($cmd eq "home") {
      ($return_code, $return_msg) = d_static ("lsthome");
    } elsif ($cmd eq "list") {
      ($return_code, $return_msg) = m_list();
    } elsif ($cmd eq "add") {
      ($return_code, $return_msg) = m_add();
    } elsif ($cmd eq "edit") {
      ($return_code, $return_msg) = m_edit();
    } elsif ($cmd eq "prd") {
      ($return_code, $return_msg) = m_prd();
    } elsif ($cmd eq "del") {
      ($return_code, $return_msg) = m_del();
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

  my $fn = $query->param('fn');
  my $m_return_code;
  my $m_return_msg;

  if (!$fn) {
    ($m_return_code, $m_return_msg) = d_static("pkadd");
  } elsif ($fn eq "add") {
    ($m_return_code, $m_return_msg) = p_add();
    if ($m_return_code == 0) {
      ($m_return_code, $m_return_msg) = m_list();
    } else {
      ($m_return_code, $m_return_msg) = e_add("k590", $m_return_msg);
    }
  } else {
    $m_return_code = 99;
    $m_return_msg  = "Invalid request. Please check the URL and try again.";
  }
  return ($m_return_code, $m_return_msg);
}


sub m_edit {

  my $fn      = $query->param('fn');
  my $arg     = $query->param('arg');
  my $m_return_code;
  my $m_return_msg;

  if (!$fn) {
    ($m_return_code, $m_return_msg) = d_edit();
    if ($m_return_code == 1) {
      ($m_return_code, $m_return_msg) = e_add("k590", $m_return_msg);
    }
  } elsif ($fn eq "del") {
    if (!$arg) {
      ($m_return_code, $m_return_msg) = d_edit_del();
    } elsif ($arg eq "del") {
      ($m_return_code, $m_return_msg) = p_edit_del();
      if ($m_return_code == 0) {
        ($m_return_code, $m_return_msg) = d_edit();
      } else {
        ($m_return_code, $m_return_msg) = e_edit_del("k390", $m_return_msg);
      }
    } else {
      ($m_return_code, $m_return_msg) = d_edit();
    }
  } elsif ($fn eq "add") {
    ($m_return_code, $m_return_msg) = p_edit_add();
    if ($m_return_code == 0) {
      ($m_return_code, $m_return_msg) = d_edit();
    } else {
      ($m_return_code, $m_return_msg) = e_edit("k190", $m_return_msg);
    }
  } else {
    $m_return_code = 99;
    $m_return_msg  = "Invalid request. Please check the URL and try again.";
  }
  return ($m_return_code, $m_return_msg);
}


sub m_prd {

  my $m_return_code;
  my $m_return_msg;

  ($m_return_code, $m_return_msg) = d_prd();
  if ($m_return_code != 0) {
    ($m_return_code, $m_return_msg) = e_prd("k290", $m_return_msg);
  }
  return ($m_return_code, $m_return_msg);
}


sub m_del {

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
    log_error("kwdscr2", $@);
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



sub d_list {

  my %keyword_dbfile;
  my $db_key;
  my $screen_html_file = $PAGE_DIR.'pklist.html';
  my $screen_html;
  my $key_count  = 0;
  my @list_array = ();
  my ($row_html_before, $row_html_after, $row_html_temp);

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %keyword_dbfile, "DB_File", $KEYWORD_DB_FILE, O_RDONLY, 0755 or die "Cannot open $KEYWORD_DB_FILE: $!";
    foreach $db_key (sort keys %keyword_dbfile) {
      push @list_array, $db_key;
      $key_count++;
    }
    untie %keyword_dbfile;
  };
  if ($@){
    log_error("d_list1", $@);
    return (99, $internal_error);
  }

  # create rows
  $screen_html   =~ /:::grepin-start-row:::.*:::grepin-end-row:::/s;
  $row_html_before = $&;

  $row_html_after = undef;
  if ($key_count > 0) {
    foreach (@list_array) {
      $row_html_temp  = $row_html_before;
      $row_html_temp  =~ s/:::grepin-ik000:::/$_/g; # keyword
      $row_html_after .= $row_html_temp;
    }
  }

  # substitute values in the page
  $screen_html =~ s/:::grepin-start-row:::.*:::grepin-end-row:::/$row_html_after/gs;
  $screen_html =~ s/(:::grepin-start-row:::)|(:::grepin-end-row:::)//gs;

  return (0, $screen_html);

}


sub e_list {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $key_word   = $query->param('kwd');
  my $e_return_code;

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $key_word  =~ tr/A-Z/a-z/;
  $key_word  =~ s/\s+/ /g;
  $key_word  =~ s/(^\s+)|(\s+$)//;

  ($e_return_code, $screen_html) = d_list();

  if ($e_return_code == 0) {
    $error_msg = "Error:".$error_id." ".$error_msg;
    $screen_html =~ s/:::grepin-fk090:::/$error_msg/g; # give the error message
    $screen_html =~ s/:::grepin-fk000:::/$key_word/gs;
    return (0, $screen_html);
  } else {
    return ($e_return_code, $screen_html);
  }

}



######################################################################################


sub p_add {
# add a new keyword
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $key_word  = $query->param('fk500');
  my $in_prods  = $query->param('fp501');
  my @in_array  = ();
  my $num_of_keywords = 0;
  my $db_key;
  my %prod_prof_dbfile;
  my %prod_keyword_dbfile;
  my %keyword_dbfile;
  my @add_array = ();
  my @products  = ();
  my $keywords;
  my @keyword_array = ();
  my $in_count = 0;

  use Fcntl;

  #change case
  $key_word   =~ tr/A-Z/a-z/;
  $in_prods   =~ tr/a-z/A-Z/;

  # replace any white space to a single space
  $key_word  =~ s/\s+/ /g;
  $in_prods  =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $key_word  =~ s/(^\s+)|(\s+$)//;
  $in_prods  =~ s/(^\s+)|(\s+$)//;

  if (!$key_word) {
    return (1, "Keyword cannot be empty.");
  }

  if ($key_word !~ /[\dA-Z_]/) {
    return (1, "Keyword - $key_word - has invalid characters. A to Z, numbers and '_' are the only valid characters for a keyword.");
  }
  if (length($key_word) > 255) {
    return (1, "Keyword - $key_word - is too long. Keywords cannot be more than 255 characters.");
  }


  @in_array = split /','/, $in_prods;

  $in_count = @in_array;
  if (@in_count == 0) {
    return (2, "At least one product name should be entered.");
  }

  foreach (@in_array) {
    if ($_ !~ /[\dA-Z_]/) {
      return (3, "Product Name - $_ - has invalid characters. A to Z, numbers and '_' are the only valid characters for a product name.");
    }
    if (length($_) > 10) {
      return (1, "Product Name - $_ - is too long. Product Names cannot be more than 10 characters.");
    }
  }

  eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    foreach (@in_array) {
      if (!$prod_prof_dbfile{$_}) {
        return (4, "Product - $_ - does not exist. Please give a different name.");
      }
    }
    untie %prod_prof_dbfile;
  };
  if ($@){
    log_error("p_add1",$@);
    return (99, $internal_error);
  }

  eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    tie %prod_keyword_dbfile, "DB_File", $PROD_KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_KEYWORD_DB_FILE: $!";
    tie %keyword_dbfile, "DB_File", $KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $KEYWORD_DB_FILE: $!";

    $db_key = $key_word;
    @products = $keyword_dbfile{$db_key};
    @add_array = minus(\@products, \@in_array); 
    @products = (@products, @add_array);
    $keyword_dbfile{$db_key} = @products;

    foreach (@add_array) {
      $keywords = $prod_keyword_dbfile{$_};
      $keywords .= ', '.$key_word;
      $prod_keyword_dbfile{$db_key} = $keywords;
      ($d1, $d2, $d3, $d4, $d5, $num_of_keywords, $d6, $d7, $d8, $d9, $d10) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
      $num_of_keywords++;
      $prod_prof_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $num_of_keywords, $d6, $d7, $d8, $d9, $d10);
    }

    untie %prod_prof_dbfile;
    untie %prod_keyword_dbfile;
    untie %keyword_dbfile;
  };
  if ($@){
    log_error("p_add2",$@);
    return (99, $internal_error);
  }

  return (0, "success");

}


sub e_add {
# add a new keyword - error
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $error_id   = shift;
  my $error_msg  = shift;

  my $key_word  = $query->param('fk500');
  my $in_prods  = $query->param('fp501');

  my $screen_html_file = $PAGE_DIR.'pkadd.html';
  my $screen_html;

  use Fcntl;

  # convert case
  $key_word  =~ tr/A-Z/a-z/;
  $in_prods   =~ tr/a-z/A-Z/;

  # replace any white space to a single space
  $key_word  =~ s/\s+/ /g;
  $in_prods  =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $key_word  =~ s/(^\s+)|(\s+$)//;
  $in_prods  =~ s/(^\s+)|(\s+$)//;

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

  #change case
  $key_word   =~ tr/A-Z/a-z/;
  $in_prods   =~ tr/a-z/A-Z/;

  # replace any white space to a single space
  $key_word  =~ s/\s+/ /g;
  $in_prods  =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $key_word  =~ s/(^\s+)|(\s+$)//;
  $in_prods  =~ s/(^\s+)|(\s+$)//;

  $error_msg = "Error:".$error_id." ".$error_msg;

  $screen_html =~ s/:::grepin-fk590:::/$error_msg/g; # give the error message
  $screen_html =~ s/:::grepin-fk500:::/$key_word/g;
  $screen_html =~ s/:::grepin-fp501:::/$in_prods/g;

  return (0, $screen_html);

}



sub d_edit {

  my $key_word = $query->param('kwd');
  my %keyword_dbfile;
  my %prod_prof_dbfile;
  my @prod_array = ();
  my $prod_count = 0;
  my $db_key;
  my ($title, $theme);
  my $screen_html_file = $PAGE_DIR.'pkedit.html';
  my $screen_html;
  my ($row_html_before, $row_html_after, $row_html_temp);

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $key_word  =~ tr/A-Z/a-z/;
  $key_word  =~ s/\s+/ /g;
  $key_word  =~ s/(^\s+)|(\s+$)//;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %keyword_dbfile, "DB_File", $KEYWORD_DB_FILE, O_RDONLY, 0755 or die "Cannot open $KEYWORD_DB_FILE: $!";
    @prod_array = $keyword_dbfile{$key_word};

    $prod_count = @prod_array;
    if ($prod_count > 0) {
      tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
      foreach $db_key (@prod_array) {
        ($title, $d1, $d2, $d3, $theme, $d4, $d5, $d6, $d7, $d8, $d9) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
        push @list_array, $theme.':::'.$db_key.':::'.$title;
      }
      untie %prod_prof_dbfile;
    }
  };
  if ($@){
    log_error("d_edit1", $@);
    return (99, $internal_error);
  }

  # create product rows
  $screen_html   =~ /:::grepin-start-row:::.*:::grepin-end-row:::/s;
  $row_html_before = $&;

  $row_html_after = undef;
  $i = 1;
  foreach (@list_array) {
    @row_array = ();
    @row_array = split /:::/, $_;
    $row_html_temp  = $row_html_before;
    $row_html_temp  =~ s/:::grepin-ik100:::/$row_array[1]/g; # product name
    $row_html_temp  =~ s/:::grepin-ik101:::/$row_array[2]/g; # title
    if ($row_array[0] == 1) {
      $row_html_temp  =~ s/:::grepin-ik109:::/$arrow/g;      # theme product indicator
    }
    $row_html_temp  =~ s/:::grepin-ik103:::/$i/g;            # remove check box
    $row_html_after .= $row_html_temp;
    $i++;
  }

  # substitute values in the page
  $screen_html =~ s/:::grepin-fk100:::/$key_word/gs;
  $screen_html =~ s/:::grepin-fk101:::/$prod_count/gs;
  $screen_html =~ s/:::grepin-start-row:::.*:::grepin-end-row:::/$row_html_after/gs;
  $screen_html =~ s/(:::grepin-start-row:::)|(:::grepin-end-row:::)//gs;

  return (0, $screen_html);

}



sub d_edit_del {

  my $key_word   = $query->param('kwd');
  my $prod_count = $query->param('fk101');
  my %prod_prof_dbfile;
  my $db_key;
  my ($title, $theme);
  my $screen_html_file = $PAGE_DIR.'pkeditdel.html';
  my $screen_html;
  my @delprod_array = ();
  my ($row_html_before, $row_html_after, $row_html_temp);

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $key_word  =~ tr/A-Z/a-z/;
  $key_word  =~ s/\s+/ /g;
  $key_word  =~ s/(^\s+)|(\s+$)//;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);
  };
  if ($@){
    log_error("d_edit_del1", $@);
    return (99, $internal_error);
  }

  # create keyword rows
  $screen_html   =~ /:::grepin-start-row:::.*:::grepin-end-row:::/s;
  $row_html_before = $&;

  $row_html_after = undef;
  $i = 0;
  if ($prod_count > 0) {
    eval {
      tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
      for (1..$prod_count) {
        if ($query->param('ik102_{$_}')) {
          $db_key = $query->param('ik102_{$_}');
          ($title, $d1, $d2, $d3, $theme, $d4, $d5, $d6, $d7, $d8, $d9) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
          push @delprod_array, $db_key;
          $row_html_temp  = $row_html_before;
          $row_html_temp  =~ s/:::grepin-ik300:::/$db_key/g; # product name
          $row_html_temp  =~ s/:::grepin-ik301:::/$title/g; 
          if ($theme == 1) {
            $row_html_temp  =~ s/:::grepin-ik309:::/$arrow/g;      # theme product indicator
          }
          $row_html_after .= $row_html_temp;
          $i++;
        }
      }
      untie %prod_prof_dbfile;
    };
    if ($@){
      log_error("d_edit_del2", $@);
      return (99, $internal_error);
    }
  }

  if ($i >= $prod_count) {
    return (1, "You cannot remove all the products for a keyword.");
  }

  $screen_html =~ s/:::grepin-fk300:::/$key_word/g;
  $screen_html =~ s/:::grepin-fk301:::/@delprod_array/g;
  $screen_html =~ s/:::grepin-start-row:::.*:::grepin-end-row:::/$row_html_after/gs;
  $screen_html =~ s/(:::grepin-start-row:::)|(:::grepin-end-row:::)//gs;

  return (0, $screen_html);

}



sub p_edit_del {
# remove products for a keyword
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $key_word      = $query->param('kwd');
  my @delprod_array = $query->param('prd');
  my ($title, $num_of_keywords);
  my @prod_array = ();
  my @new_array = ();
  my @keywords_array = ();
  my $db_key;
  my %prod_prof_dbfile;
  my %prod_keyword_dbfile;
  my %keyword_dbfile;

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $key_word  =~ tr/A-Z/a-z/;
  $key_word  =~ s/\s+/ /g;
  $key_word  =~ s/(^\s+)|(\s+$)//;

  eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    tie %prod_keyword_dbfile, "DB_File", $PROD_KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_KEYWORD_DB_FILE: $!";
    tie %keyword_dbfile, "DB_File", $KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $KEYWORD_DB_FILE: $!";

    foreach $db_key (@delprod_array) {
      ($d1, $d2, $d3, $d4, $d5, $num_of_keywords, $d6, $d7, $d8, $d9, $d10) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});

      $keywords = $prod_keyword_dbfile{$db_key};
      @keywords_array = split /','/, $keywords;
      @new_array = ();
      foreach (@keywords_array) {
        if ($_ ne $key_word) {
          push @new_array, $_;
        }
      }

      $num_of_keywords = @new_array;
      $prod_prof_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $num_of_keywords, $d6, $d7, $d8, $d9, $d10);

      $keywords = join(", ", @new_array);
      $prod_keyword_dbfile{$db_key} = $keywords;
    }

    @prod_array = $keyword_dbfile{$key_word};
    $keyword_dbfile{$key_word} = minus (\@prod_array, \@delprod_array);

    untie %prod_prof_dbfile;
    untie %prod_keyword_dbfile;
    untie %keyword_dbfile;
  };
  if ($@){
    log_error("p_edit_del1",$@);
    return (99, $internal_error);
  }

  return (0, "success");

}



sub e_edit_del {
# remove a product for a keyword - error
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $error_id   = shift;
  my $error_msg  = shift;

  my $key_word      = $query->param('kwd');
  my @delprod_array = $query->param('prd');
  my $db_key;
  my %prod_prof_dbfile;
  my ($title, $theme);
  my ($row_html_before, $row_html_after, $row_html_temp);

  my $screen_html_file = $PAGE_DIR.'pkeditdel.html';
  my $screen_html;

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $key_word  =~ tr/A-Z/a-z/;
  $key_word  =~ s/\s+/ /g;
  $key_word  =~ s/(^\s+)|(\s+$)//;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);
  };
  if ($@){
    log_error("e_edit_del1", $@);
    return (99, $internal_error);
  }

  # create product rows
  $screen_html   =~ /:::grepin-start-row:::.*:::grepin-end-row:::/s;
  $row_html_before = $&;

  $row_html_after = undef;
  eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    foreach $db_key (@delprod_array) {
      $db_key =~ tr/a-z/A-Z/;
      ($title, $d1, $d2, $d3, $theme, $d4, $d5, $d6, $d7, $d8, $d9) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
      $row_html_temp  = $row_html_before;
      $row_html_temp  =~ s/:::grepin-ik300:::/$db_key/g; # product name
      $row_html_temp  =~ s/:::grepin-ik301:::/$title/g; 
      if ($theme == 1) {
        $row_html_temp  =~ s/:::grepin-ik309:::/$arrow/g;      # theme product indicator
      }
      $row_html_after .= $row_html_temp;
    }
    untie %prod_prof_dbfile;
  };
  if ($@){
    log_error("e_edit_del2", $@);
    return (99, $internal_error);
  }

  $error_msg = "Error:".$error_id." ".$error_msg;

  $screen_html =~ s/:::grepin-fk390:::/$error_msg/g; # give the error message
  $screen_html =~ s/:::grepin-fk300:::/$key_word/g;
  $screen_html =~ s/:::grepin-fk301:::/@delprod_array/g;
  $screen_html =~ s/:::grepin-start-row:::.*:::grepin-end-row:::/$row_html_after/gs;
  $screen_html =~ s/(:::grepin-start-row:::)|(:::grepin-end-row:::)//gs;

  return (0, $screen_html);

}



sub p_edit_add {
# add products to keyword
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $key_word  = $query->param('kwd');
  my $in_prods  = $query->param('fk102');
  my @in_array  = ();
  my $in_count = 0;
  my $num_of_keywords = 0;
  my $db_key;
  my %prod_prof_dbfile;
  my %prod_keyword_dbfile;
  my %keyword_dbfile;
  my @products = ();
  my $keywords;
  my @keyword_array = ();
  my @add_array = ();

  use Fcntl;

  # convert case
  $key_word  =~ tr/A-Z/a-z/;
  $in_prods  =~ tr/a-z/A-Z/;

  # replace any white space to a single space
  $key_word  =~ s/\s+/ /g;
  $in_prods  =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $key_word  =~ s/(^\s+)|(\s+$)//;
  $in_prods  =~ s/(^\s+)|(\s+$)//;

  @in_array = split /','/, $in_prods;
  $in_count = @in_array;

  if ($in_count == 0) {
    return (1, "At least one product name should be entered.");
  }

  foreach (@in_array) {
    if ($_ !~ /[\dA-Z_]/) {
      return (2, "Product Name - $_ - has invalid characters. A to Z, numbers and '_' are the only valid characters for a product name.");
    }
    if (length($_) > 10) {
      return (1, "Product Name - $_ - is too long. Product Name cannot be more than 10 characters.");
    }
  }

  eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    foreach (@in_array) {
      if (!$prod_prof_dbfile{$_}) {
        return (4, "Product - $_ - does not exist. Please give a different name.");
      }
    }
    untie %prod_prof_dbfile;
  };
  if ($@){
    log_error("p_edit_add1",$@);
    return (99, $internal_error);
  }

  eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    tie %prod_keyword_dbfile, "DB_File", $PROD_KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_KEYWORD_DB_FILE: $!";
    tie %keyword_dbfile, "DB_File", $KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $KEYWORD_DB_FILE: $!";

    $db_key = $key_word;
    @products = $keyword_dbfile{$db_key};
    @add_array = minus(\@in_array, \@products); 
    @products = (@products, @add_array);
    $keyword_dbfile{$db_key} = @products;

    foreach (@add_array) {
      $keywords = $prod_keyword_dbfile{$_};
      $keywords .= ', '.$key_word;
      $prod_keyword_dbfile{$db_key} = $keywords;
      ($d1, $d2, $d3, $d4, $d5, $num_of_keywords, $d6, $d7, $d8, $d9, $d10) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
      $num_of_keywords++;
      $prod_prof_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $num_of_keywords, $d6, $d7, $d8, $d9, $d10);
    }

    untie %prod_prof_dbfile;
    untie %prod_keyword_dbfile;
    untie %keyword_dbfile;
  };
  if ($@){
    log_error("p_edit_add2",$@);
    return (99, $internal_error);
  }

  return (0, "success");

}



sub e_edit {

  my $error_id   = shift;
  my $error_msg  = shift;

  my $in_prods   = $query->param('fk102');
  my $e_return_code;

  use Fcntl;

  # change case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $in_prods  =~ tr/a-z/A-Z/;
  $in_prods  =~ s/\s+/ /g;
  $in_prods  =~ s/(^\s+)|(\s+$)//;

  ($e_return_code, $screen_html) = d_edit();

  if ($e_return_code == 0) {
    $error_msg = "Error:".$error_id." ".$error_msg;
    $screen_html =~ s/:::grepin-fk190:::/$error_msg/g; # give the error message
    $screen_html =~ s/:::grepin-fk102:::/$in_prods/gs;
    return (0, $screen_html);
  } else {
    return ($e_return_code, $screen_html);
  }

}



sub d_del {

  my $key_word = $query->param('kwd');
  my $products;
  my %keyword_dbfile;
  my %prod_prof_dbfile;
  my $db_key;
  my $title;
  my $screen_html_file = $PAGE_DIR.'pkdel.html';
  my $screen_html;

  use Fcntl;

  eval {
    open (HTMLFILE, $screen_html_file) or die "Cannot open screenhtmlfile '$screen_html_file' for reading: $!";

    while (<HTMLFILE>) {
      $screen_html .= $_;
    }
    close(HTMLFILE);

    tie %keyword_dbfile, "DB_File", $KEYWORD_DB_FILE, O_RDONLY, 0755 or die "Cannot open $KEYWORD_DB_FILE: $!";
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";

    $db_key = $key_word;
    @products = $keyword_dbfile{$db_key};

    # create product rows
    $screen_html   =~ /:::grepin-start-row:::.*:::grepin-end-row:::/s;
    $row_html_before = $&;

    $row_html_after = undef;

    foreach $db_key (@products) {
      ($title, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
      $row_html_temp  = $row_html_before;
      $row_html_temp  =~ s/:::grepin-ik400:::/$db_key/g; # product name
      $row_html_temp  =~ s/:::grepin-ik401:::/$title/g; 
      if ($theme == 1) {
        $row_html_temp  =~ s/:::grepin-ik409:::/$arrow/g;      # theme product indicator
      }
      $row_html_after .= $row_html_temp;
    }
    untie %keyword_dbfile;
    untie %prod_prof_dbfile;
  };
  if ($@){
    log_error("d_del1", $@);
    return (99, $internal_error);
  }

  return (0, $screen_html);

}



sub e_del {
# delete a keyword - error
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $error_id   = shift;
  my $error_msg  = shift;

  my $key_word  = $query->param('kwd');
  my $e_return_code;

  use Fcntl;

  ($e_return_code, $screen_html) = d_edit();

  if ($e_return_code == 0) {
    $error_msg = "Error:".$error_id." ".$error_msg;
    $screen_html =~ s/:::grepin-fk490:::/$error_msg/g; # give the error message
    return (0, $screen_html);
  } else {
    return ($e_return_code, $screen_html);
  }

}



sub p_del {
# delete a keyword
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $key_word = $query->param('kwd');
  my $num_of_keywords;
  my @prod_array = ();
  my @new_array = ();
  my @keywords_array = ();
  my $db_key;
  my %prod_prof_dbfile;
  my %prod_keyword_dbfile;
  my %keyword_dbfile;

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $key_word  =~ tr/A-Z/a-z/;
  $key_word  =~ s/\s+/ /g;
  $key_word  =~ s/(^\s+)|(\s+$)//;

  eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    tie %prod_keyword_dbfile, "DB_File", $PROD_KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_KEYWORD_DB_FILE: $!";
    tie %keyword_dbfile, "DB_File", $KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $KEYWORD_DB_FILE: $!";

    @prod_array = $keyword_dbfile{$key_word};
    foreach $db_key (@prod_array) {
      ($d1, $d2, $d3, $d4, $d5, $num_of_keywords, $d6, $d7, $d8, $d9, $d10) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});

      $keywords = $prod_keyword_dbfile{$db_key};
      @keywords_array = split /','/, $keywords;
      @new_array = ();
      foreach (@keywords_array) {
        if ($_ ne $key_word) {
          push @new_array, $_;
        }
      }

      $num_of_keywords = @new_array;
      $prod_prof_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $num_of_keywords, $d6, $d7, $d8, $d9, $d10);

      $keywords = join(", ", @new_array);
      $prod_keyword_dbfile{$db_key} = $keywords;
    }

    delete $keyword_dbfile{$key_word};

    untie %prod_prof_dbfile;
    untie %prod_keyword_dbfile;
    untie %keyword_dbfile;
  };
  if ($@){
    log_error("p_edit_del1",$@);
    return (99, $internal_error);
  }

  return (0, "success");

}



sub d_prd {

  my %prod_prof_dbfile;
  my %keyword_dbfile;
  my $key_word  = $query->param('kwd');
  my $db_key;
  my @prod_array = ();
  my ($prod_id, $title, $theme);
  my $screen_html_file = $PAGE_DIR.'pkprd.html';
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

    tie %keyword_dbfile, "DB_File", $KEYWORD_DB_FILE, O_RDONLY, 0755 or die "Cannot open $KEYWORD_DB_FILE: $!";
    @prod_array = $keyword_dbfile{$key_word};

    $prod_count = @prod_array;
    if ($prod_count > 0) {
      tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
      foreach $db_key (@prod_array) {
        ($title, $d1, $d2, $d3, $theme, $d4, $d5, $d6, $d7, $d8, $d9) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$db_key});
        push @list_array, $theme.':::'.$db_key.':::'.$title;
      }
      untie %prod_prof_dbfile;
    }
  };
  if ($@){
    log_error("d_prd1", $@);
    return (99, $internal_error);
  }

  # create rows
  $screen_html   =~ /:::grepin-start-row:::.*:::grepin-end-row:::/s;
  $row_html_before = $&;

  $row_html_after = undef;
  foreach (@list_array) {
    @row_array = ();
    @row_array = split /:::/, $_;
    $row_html_temp  = $row_html_before;
    $row_html_temp  =~ s/:::grepin-ik200:::/$row_array[1]/g; # product name
    $row_html_temp  =~ s/:::grepin-ik201:::/$row_array[2]/g; # title
    if ($row_array[0] == 1) {
      $row_html_temp  =~ s/:::grepin-ik209:::/$arrow/g; # theme product indicator
    }
    $row_html_after .= $row_html_temp;
  }

  # substitute values in the page
  $screen_html =~ s/:::grepin-fk200:::/$key_word/gs;
  $screen_html =~ s/:::grepin-fk201:::/$prod_count/gs;
  $screen_html =~ s/:::grepin-start-row:::.*:::grepin-end-row:::/$row_html_after/gs;
  $screen_html =~ s/(:::grepin-start-row:::)|(:::grepin-end-row:::)//gs;

  return (0, $screen_html);

}



sub e_prd {
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

  my $key_word  = $query->param('kwd');
  my $screen_html_file = $PAGE_DIR.'pkprd.html';
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

  $screen_html =~ s/:::grepin-fk200:::/$key_word/gs;
  $screen_html =~ s/:::grepin-fk290:::/$error_msg/g; # give the error message

  return (0, $screen_html);

}



#####################################################################################################



sub d_static {
  # return codes
  #  0 = success
  # 99 = error in accessing files and database

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
              $query->param('prd') || '-',
              $query->param('kwd') || '-',
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
    if ((!$pwrlst_db{$user_id}) || ($pwrlst_db{$user_id} != 1)) {
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
