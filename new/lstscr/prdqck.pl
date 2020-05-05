#!/usr/bin/perl -w

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
#   use CGI::Carp qw(carpout);
#   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/prdqckerr.txt")
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
  my @data_array = ();

  ######################################

  my $MAIN_DIR = '/home/grepinco/public_html/cgi-bin/';
  my $PAGE_DIR = $MAIN_DIR.'pages/';
  my $USER_DIR = $MAIN_DIR.'users/';

  my $LOG_DIR    = $MAIN_DIR.'log/';
  my $LOG_FILE   = $LOG_DIR.'prdqcklog.txt';
  my $LOG_SOURCE = $LOG_DIR.'sourcelog.txt';

  my $SESSION_DB_FILE  = $USER_DIR.'session';
  my $PWRLST_DB_FILE   = $USER_DIR.'pwrlst';

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
    push(@line, 'prdqck ------------- ',
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
    log_error("prdqck1", "The DB_File module was not found.");
    print "$internal_error \n\n";
    exit;
  }

####  DO NOT CALL ANY SUB-PROGRAM UNTIL THIS POINT ########


  if (!$cmd) {
    $cmd = "new";
  }

  if ($session_id) {
    ($return_code, $return_msg) = p_sessnchk();
    if ($return_code != 0) {
      $user_id    = undef;
      $session_id = undef;
      if (($cmd eq "new") || ($cmd eq "add") || ($cmd eq "model")) {
        ($return_code, $return_msg) = e_login(5190, $return_msg);
        $valid_sid = 'F';
      }
    }
  } else {
    if (($cmd eq "new") || ($cmd eq "add") || ($cmd eq "model")) {
      ($return_code, $return_msg) = e_login(5190, "You have to login as a member to access this page.");
      $user_id = undef;
      $valid_sid = 'F';
    }
  }

  if ($valid_sid eq 'T') {
    if (($cmd eq "new") || ($cmd eq "add") || ($cmd eq "model")) {
      ($return_code, $return_msg) = p_memberchk();
      if ($return_code != 0) {
        kishore
      }
    }
    if ($cmd eq "new") {
      ($return_code, $return_msg) = d_static ("prqck");
    } elsif ($cmd eq "add") {
      ($return_code, $return_msg) = m_add();
    } elsif ($cmd eq "model") {
      ($return_code, $return_msg) = m_model();
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


sub m_add {

  my $m_return_code;
  my $m_return_msg;

  ($m_return_code, $m_return_msg) = p_add();
  if ($m_return_code == 10) {
    ($m_return_code, $m_return_msg) = e_add("pq90", $m_return_msg);
  } elsif ($m_return_code == 11) {
    ($m_return_code, $m_return_msg) = e_add("pq91", $m_return_msg);
  } elsif ($m_return_code == 12) {
    ($m_return_code, $m_return_msg) = e_add("pq92", $m_return_msg);
  } elsif ($m_return_code == 13) {
    ($m_return_code, $m_return_msg) = e_add("pq93", $m_return_msg);
  } elsif ($m_return_code == 14) {
    ($m_return_code, $m_return_msg) = e_add("pq94", $m_return_msg);
  } else {
    ($m_return_code, $m_return_msg) = e_add("pq90", $m_return_msg);
  } 
  return ($m_return_code, $m_return_msg);
}


sub m_model {

  my $m_return_code;
  my $m_return_msg;

  ($m_return_code, $m_return_msg) = d_model();
  if ($m_return_code != 0) {
    ($m_return_code, $m_return_msg) = e_add("pq90", $m_return_msg);
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
    log_error("prdqck2", $@);
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



sub p_add {
# add a new product
# return codes
#  0 = success
#  1 = invalid input
#  2 = 
#  3 = 
#  4 = 
# 99 = database error

  my $keywords   = $query->param('fpq50');

  my $prod_id0   = $query->param('fpq00');
  my $title0     = $query->param('fpq01');
  my $desc0      = $query->param('fpq02');
  my $image_url0 = $query->param('fpq03');
  my $dest_url0  = $query->param('fpq04');
  my $theme0     = $query->param('fpq05');
  my $comments0  = $query->param('fpq06');

  my $prod_id1   = $query->param('fpq10');
  my $title1     = $query->param('fpq11');
  my $desc1      = $query->param('fpq12');
  my $image_url1 = $query->param('fpq13');
  my $dest_url1  = $query->param('fpq14');
  my $theme1     = $query->param('fpq15');
  my $comments1  = $query->param('fpq16');

  my $prod_id2   = $query->param('fpq20');
  my $title2     = $query->param('fpq21');
  my $desc2      = $query->param('fpq22');
  my $image_url2 = $query->param('fpq23');
  my $dest_url2  = $query->param('fpq24');
  my $theme2     = $query->param('fpq25');
  my $comments2  = $query->param('fpq26');

  my $prod_id3   = $query->param('fpq30');
  my $title3     = $query->param('fpq31');
  my $desc3      = $query->param('fpq32');
  my $image_url3 = $query->param('fpq33');
  my $dest_url3  = $query->param('fpq34');
  my $theme3     = $query->param('fpq35');
  my $comments3  = $query->param('fpq36');

  my $prod_id4   = $query->param('fpq40');
  my $title4     = $query->param('fpq41');
  my $desc4      = $query->param('fpq42');
  my $image_url4 = $query->param('fpq43');
  my $dest_url4  = $query->param('fpq44');
  my $theme4     = $query->param('fpq45');
  my $comments4  = $query->param('fpq46');

  my $num_of_keywords = 0;
  my $db_key;
  my %prod_prof_dbfile;
  my %theme_dbfile;
  my %prod_keyword_dbfile;
  my %keyword_dbfile;
  my @products = ();
  my @new_prod_array = ();

  use Fcntl;

  # convert case
  $keywords =~ tr/A-Z/a-z/;
  $prod_id0 =~ tr/a-z/A-Z/;
  $prod_id1 =~ tr/a-z/A-Z/;
  $prod_id2 =~ tr/a-z/A-Z/;
  $prod_id3 =~ tr/a-z/A-Z/;
  $prod_id4 =~ tr/a-z/A-Z/;

  # replace any white space to a single space
  $keywords   =~ s/\s+/ /g;
  $prod_id0   =~ s/\s+/ /g;
  $prod_id1   =~ s/\s+/ /g;
  $prod_id2   =~ s/\s+/ /g;
  $prod_id3   =~ s/\s+/ /g;
  $prod_id4   =~ s/\s+/ /g;
  $title0     =~ s/\s+/ /g;
  $title1     =~ s/\s+/ /g;
  $title2     =~ s/\s+/ /g;
  $title3     =~ s/\s+/ /g;
  $title4     =~ s/\s+/ /g;
  $desc0      =~ s/\s+/ /g;
  $desc1      =~ s/\s+/ /g;
  $desc2      =~ s/\s+/ /g;
  $desc3      =~ s/\s+/ /g;
  $desc4      =~ s/\s+/ /g;
  $image_url0 =~ s/\s+/ /g;
  $image_url1 =~ s/\s+/ /g;
  $image_url2 =~ s/\s+/ /g;
  $image_url3 =~ s/\s+/ /g;
  $image_url4 =~ s/\s+/ /g;
  $dest_url0  =~ s/\s+/ /g;
  $dest_url1  =~ s/\s+/ /g;
  $dest_url2  =~ s/\s+/ /g;
  $dest_url3  =~ s/\s+/ /g;
  $dest_url4  =~ s/\s+/ /g;
  $comments0  =~ s/\s+/ /g;
  $comments1  =~ s/\s+/ /g;
  $comments2  =~ s/\s+/ /g;
  $comments3  =~ s/\s+/ /g;
  $comments4  =~ s/\s+/ /g;

  # remove leading and trailing whitespace
  $keywords   =~ s/(^\s+)|(\s+$)//;
  $prod_id0   =~ s/(^\s+)|(\s+$)//;
  $prod_id1   =~ s/(^\s+)|(\s+$)//;
  $prod_id2   =~ s/(^\s+)|(\s+$)//;
  $prod_id3   =~ s/(^\s+)|(\s+$)//;
  $prod_id4   =~ s/(^\s+)|(\s+$)//;
  $title0     =~ s/(^\s+)|(\s+$)//;
  $title1     =~ s/(^\s+)|(\s+$)//;
  $title2     =~ s/(^\s+)|(\s+$)//;
  $title3     =~ s/(^\s+)|(\s+$)//;
  $title4     =~ s/(^\s+)|(\s+$)//;
  $desc0      =~ s/(^\s+)|(\s+$)//;
  $desc1      =~ s/(^\s+)|(\s+$)//;
  $desc2      =~ s/(^\s+)|(\s+$)//;
  $desc3      =~ s/(^\s+)|(\s+$)//;
  $desc4      =~ s/(^\s+)|(\s+$)//;
  $image_url0 =~ s/(^\s+)|(\s+$)//;
  $image_url1 =~ s/(^\s+)|(\s+$)//;
  $image_url2 =~ s/(^\s+)|(\s+$)//;
  $image_url3 =~ s/(^\s+)|(\s+$)//;
  $image_url4 =~ s/(^\s+)|(\s+$)//;
  $dest_url0  =~ s/(^\s+)|(\s+$)//;
  $dest_url1  =~ s/(^\s+)|(\s+$)//;
  $dest_url2  =~ s/(^\s+)|(\s+$)//;
  $dest_url3  =~ s/(^\s+)|(\s+$)//;
  $dest_url4  =~ s/(^\s+)|(\s+$)//;
  $comments0  =~ s/(^\s+)|(\s+$)//;
  $comments1  =~ s/(^\s+)|(\s+$)//;
  $comments2  =~ s/(^\s+)|(\s+$)//;
  $comments3  =~ s/(^\s+)|(\s+$)//;
  $comments4  =~ s/(^\s+)|(\s+$)//;

  @keywords_array = split /','/, $keywords;
  $num_of_keywords = @keywords_array;

  if ($prod_id0 || $title0 || $desc0 || image_url0 || $dest_url0 || $comments0) {
    $product0 = 1;
    @data_array = (@data_array, $prod_id0, $title0, $desc0, $image_url0, $dest_url0, $theme0, $comments0);
  }
  if ($prod_id1 || $title1 || $desc1 || image_url1 || $dest_url1 || $comments1) {
    $product1 = 1;
    @data_array = (@data_array, $prod_id1, $title1, $desc1, $image_url1, $dest_url1, $theme1, $comments1);
  }
  if ($prod_id2 || $title2 || $desc2 || image_url2 || $dest_url2 || $comments2) {
    $product2 = 1;
    @data_array = (@data_array, $prod_id2, $title2, $desc2, $image_url2, $dest_url2, $theme2, $comments2);
  }
  if ($prod_id3 || $title3 || $desc3 || image_url3 || $dest_url3 || $comments3) {
    $product3 = 1;
    @data_array = (@data_array, $prod_id3, $title3, $desc3, $image_url3, $dest_url3, $theme3, $comments3);
  }
  if ($prod_id4 || $title4 || $desc4 || image_url4 || $dest_url4 || $comments4) {
    $product4 = 1;
    @data_array = (@data_array, $prod_id4, $title4, $desc4, $image_url4, $dest_url4, $theme4, $comments4);
  }

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

  eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
  };
  if ($@){
    log_error("p_add1",$@);
    return (99, $internal_error);
  }

  if ($product0 == 1) {
    if (!$prod_id0) {
      return (10, "Product Name cannot be empty.");
    }
    if ($prod_id0 !~ /[\dA-Z_]/) {
      return (10, "Product Name has invalid characters. A to Z, numbers and '_' are only allowed.");
    }
    if ($prod_prof_dbfile{$prod_id0}) {
      return (10, "Product already exists with the same name. Please give a different name.");
    }
    if (!$title0) {
      return (10, "Title cannot be empty.");
    }
    if (!$desc0) {
      return (10, "Product description cannot be empty.");
    }
    if (length($desc0) > 255) {
      return (10, "Product description cannot be more than 255 characters.");
    }
    if (!$dest_url0) {
      return (10, "Destination URL cannot be empty.");
    }
    if ($image_url0) { 
      if (($image_url0 !~ m%^http://.*/$%) && ($image_url0 !~ m%^https://.*/$%)) {
        return (10, "Image URL should start with 'http://' or 'https://' and end with '/'.");
      }
    }
    if (($dest_url0 !~ m%^http://.*/$%) && ($dest_url0 !~ m%^https://.*/$%)) {
      return (10, "Destination URL should start with 'http://' or 'https://' and end with '/'.");
    }
    if (($theme0 != 1) && ($theme0 != 0)) {
      return (10, "Theme Product indicator should be either 0 or 1.");
    }
    if (length($comments0) > 255) {
      return (10, "Comments cannot be more than 255 characters.");
    }
  }

  if ($product1 == 1) {
    if (!$prod_id1) {
      return (11, "Product Name cannot be empty.");
    }
    if ($prod_id1 !~ /[\dA-Z_]/) {
      return (11, "Product Name has invalid characters. A to Z, numbers and '_' are only allowed.");
    }
    if ($prod_prof_dbfile{$prod_id1}) {
      return (11, "Product already exists with the same name. Please give a different name.");
    }
    if (!$title1) {
      return (11, "Title cannot be empty.");
    }
    if (!$desc1) {
      return (11, "Product description cannot be empty.");
    }
    if (length($desc1) > 255) {
      return (10, "Product description cannot be more than 255 characters.");
    }
    if (!$dest_url1) {
      return (11, "Destination URL cannot be empty.");
    }
    if ($image_url1) { 
      if (($image_url1 !~ m%^http://.*/$%) && ($image_url1 !~ m%^https://.*/$%)) {
        return (11, "Image URL should start with 'http://' or 'https://' and end with '/'.");
      }
    }
    if (($dest_url1 !~ m%^http://.*/$%) && ($dest_url1 !~ m%^https://.*/$%)) {
      return (11, "Destination URL should start with 'http://' or 'https://' and end with '/'.");
    }
    if (($theme1 != 1) && ($theme1 != 0)) {
      return (11, "Theme Product indicator should be either 0 or 1.");
    }
    if (length($comments1) > 255) {
      return (10, "Comments cannot be more than 255 characters.");
    }
  }

  if ($product2 == 1) {
    if (!$prod_id2) {
      return (12, "Product Name cannot be empty.");
    }
    if ($prod_id2 !~ /[\dA-Z_]/) {
      return (12, "Product Name has invalid characters. A to Z, numbers and '_' are only allowed.");
    }
    if ($prod_prof_dbfile{$prod_id2}) {
      return (12, "Product already exists with the same name. Please give a different name.");
    }
    if (!$title2) {
      return (12, "Title cannot be empty.");
    }
    if (!$desc2) {
      return (12, "Product description cannot be empty.");
    }
    if (length($desc2) > 255) {
      return (10, "Product description cannot be more than 255 characters.");
    }
    if (!$dest_url2) {
      return (12, "Destination URL cannot be empty.");
    }
    if ($image_url2) { 
      if (($image_url2 !~ m%^http://.*/$%) && ($image_url2 !~ m%^https://.*/$%)) {
        return (12, "Image URL should start with 'http://' or 'https://' and end with '/'.");
      }
    }
    if (($dest_url2 !~ m%^http://.*/$%) && ($dest_url2 !~ m%^https://.*/$%)) {
      return (12, "Destination URL should start with 'http://' or 'https://' and end with '/'.");
    }
    if (($theme2 != 1) && ($theme2 != 0)) {
      return (12, "Theme Product indicator should be either 0 or 1.");
    }
    if (length($comments2) > 255) {
      return (10, "Comments cannot be more than 255 characters.");
    }
  }

  if ($product3 == 1) {
    if (!$prod_id3) {
      return (13, "Product Name cannot be empty.");
    }
    if ($prod_id3 !~ /[\dA-Z_]/) {
      return (13, "Product Name has invalid characters. A to Z, numbers and '_' are only allowed.");
    }
    if ($prod_prof_dbfile{$prod_id3}) {
      return (13, "Product already exists with the same name. Please give a different name.");
    }
    if (!$title3) {
      return (13, "Title cannot be empty.");
    }
    if (!$desc3) {
      return (13, "Product description cannot be empty.");
    }
    if (length($desc3) > 255) {
      return (10, "Product description cannot be more than 255 characters.");
    }
    if (!$dest_url3) {
      return (13, "Destination URL cannot be empty.");
    }
    if ($image_url3) { 
      if (($image_url3 !~ m%^http://.*/$%) && ($image_url3 !~ m%^https://.*/$%)) {
        return (13, "Image URL should start with 'http://' or 'https://' and end with '/'.");
      }
    }
    if (($dest_url3 !~ m%^http://.*/$%) && ($dest_url3 !~ m%^https://.*/$%)) {
      return (13, "Destination URL should start with 'http://' or 'https://' and end with '/'.");
    }
    if (($theme3 != 1) && ($theme3 != 0)) {
      return (13, "Theme Product indicator should be either 0 or 1.");
    }
    if (length($comments3) > 255) {
      return (10, "Comments cannot be more than 255 characters.");
    }
  }

  if ($product4 == 1) {
    if (!$prod_id4) {
      return (14, "Product Name cannot be empty.");
    }
    if ($prod_id4 !~ /[\dA-Z_]/) {
      return (14, "Product Name has invalid characters. A to Z, numbers and '_' are only allowed.");
    }
    if ($prod_prof_dbfile{$prod_id4}) {
      return (14, "Product already exists with the same name. Please give a different name.");
    }
    if (!$title4) {
      return (14, "Title cannot be empty.");
    }
    if (!$desc4) {
      return (14, "Product description cannot be empty.");
    }
    if (length($desc4) > 255) {
      return (10, "Product description cannot be more than 255 characters.");
    }
    if (!$dest_url4) {
      return (14, "Destination URL cannot be empty.");
    }
    if ($image_url4) { 
      if (($image_url4 !~ m%^http://.*/$%) && ($image_url4 !~ m%^https://.*/$%)) {
        return (14, "Image URL should start with 'http://' or 'https://' and end with '/'.");
      }
    }
    if (($dest_url4 !~ m%^http://.*/$%) && ($dest_url4 !~ m%^https://.*/$%)) {
      return (14, "Destination URL should start with 'http://' or 'https://' and end with '/'.");
    }
    if (($theme4 != 1) && ($theme4 != 0)) {
      return (14, "Theme Product indicator should be either 0 or 1.");
    }
    if (length($comments4) > 255) {
      return (10, "Comments cannot be more than 255 characters.");
    }
  }

  untie %prod_prof_dbfile;

  eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    tie %theme_dbfile, "DB_File", $PROD_THEME_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_THEME_DB_FILE: $!";
    tie %prod_keyword_dbfile, "DB_File", $PROD_KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $PROD_KEYWORD_DB_FILE: $!";
    tie %keyword_dbfile, "DB_File", $KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $KEYWORD_DB_FILE: $!";
  };
  if ($@){
    log_error("p_add2",$@);
    return (99, $internal_error);
  }

  @new_prod_array = ();

  if ($product0 == 1) {
    $db_key = $prod_id0;
    $prod_prof_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $title0, $desc0, $image_url0, $dest_url0, $theme0, $num_of_keywords, $comments0, $d2, $d3, $d4, $d5);
    if ($theme0 == 1) {
      $theme_dbfile{$db_key} = 1;
    }
    $prod_keyword_dbfile{$db_key} = $keywords;
    push @new_prod_array, $prod_id0;
  }

  if ($product1 == 1) {
    $db_key = $prod_id1;
    $prod_prof_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $title1, $desc1, $image_url1, $dest_url1, $theme1, $num_of_keywords, $comments1, $d2, $d3, $d4, $d5);
    if ($theme1 == 1) {
      $theme_dbfile{$db_key} = 1;
    }
    $prod_keyword_dbfile{$db_key} = $keywords;
    push @new_prod_array, $prod_id1;
  }

  if ($product2 == 1) {
    $db_key = $prod_id2;
    $prod_prof_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $title2, $desc2, $image_url2, $dest_url2, $theme2, $num_of_keywords, $comments2, $d2, $d3, $d4, $d5);
    if ($theme2 == 1) {
      $theme_dbfile{$db_key} = 1;
    }
    $prod_keyword_dbfile{$db_key} = $keywords;
    push @new_prod_array, $prod_id2;
  }

  if ($product3 == 1) {
    $db_key = $prod_id3;
    $prod_prof_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $title3, $desc3, $image_url3, $dest_url3, $theme3, $num_of_keywords, $comments3, $d2, $d3, $d4, $d5);
    if ($theme3 == 1) {
      $theme_dbfile{$db_key} = 1;
    }
    $prod_keyword_dbfile{$db_key} = $keywords;
    push @new_prod_array, $prod_id3;
  }

  if ($product4 == 1) {
    $db_key = $prod_id4;
    $prod_prof_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $title4, $desc4, $image_url4, $dest_url4, $theme4, $num_of_keywords, $comments4, $d2, $d3, $d4, $d5);
    if ($theme4 == 1) {
      $theme_dbfile{$db_key} = 1;
    }
    $prod_keyword_dbfile{$db_key} = $keywords;
    push @new_prod_array, $prod_id4;
  }

  foreach (@keywords_array) {
    @products = ();
    if ($keyword_dbfile{$_}) {
      @products = $keyword_dbfile{$_};
    }
    @products = (@products, @new_prod_array);
    $keyword_dbfile{$_} = @products;
  }

  untie %prod_prof_dbfile;
  untie %prod_keyword_dbfile;
  untie %theme_dbfile;
  untie %keyword_dbfile;

  return (0, @data_array);

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

  my $keywords  = $query->param('fpq50');

  my $screen_html_file = $PAGE_DIR.'prqck.html';
  my $screen_html;
  my $checked   = "CHECKED";

  use Fcntl;

  # convert case
  # replace any white space to a single space
  # remove leading and trailing whitespace
  $keywords =~ tr/A-Z/a-z/;
  $keywords =~ s/\s+/ /g;
  $keywords =~ s/(^\s+)|(\s+$)//;

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

  if ($error_msg eq "success") {
    $error_msg = "The products have been successfully added.";
    $data_array[1]  = undef;
    $data_array[8]  = undef;
    $data_array[15] = undef;
    $data_array[22] = undef;
    $data_array[29] = undef;
  } else {
    $error_msg = "Error:".$error_id." ".$error_msg;
  }

  if ($error_id eq 'pq99') {
    $screen_html =~ s/:::grepin-fpq99:::/$error_msg/g;
  } else {
    $screen_html =~ s/:::grepin-fpq99:::/"There has been an error."/g;
    if ($error_id eq 'pq90') {
      $screen_html =~ s/:::grepin-fpq90:::/$error_msg/g;
    } elsif ($error_id eq 'pq91') {
      $screen_html =~ s/:::grepin-fpq91:::/$error_msg/g;
    } elsif ($error_id eq 'pq92') {
      $screen_html =~ s/:::grepin-fpq92:::/$error_msg/g;
    } elsif ($error_id eq 'pq93') {
      $screen_html =~ s/:::grepin-fpq93:::/$error_msg/g;
    } elsif ($error_id eq 'pq94') {
      $screen_html =~ s/:::grepin-fpq94:::/$error_msg/g;
    }
  }
    
  $screen_html =~ s/:::grepin-fpq50:::/$keywords/g;

  $screen_html =~ s/:::grepin-fpq00:::/$data_array[1]/g;
  $screen_html =~ s/:::grepin-fpq01:::/$data_array[2]/g;
  $screen_html =~ s/:::grepin-fpq02:::/$data_array[3]/g;
  $screen_html =~ s/:::grepin-fpq03:::/$data_array[4]/g;
  $screen_html =~ s/:::grepin-fpq04:::/$data_array[5]/g;
  if ($data_array[6] == 1) {
    $screen_html =~ s/:::grepin-fpq05a:::/$checked/g; # select the yes 
  } else {
    $screen_html =~ s/:::grepin-fpq05:::/$checked/g;  # select the no (default)
  }
  $screen_html =~ s/:::grepin-fpq06:::/$data_array[7]/g;

  $screen_html =~ s/:::grepin-fpq10:::/$data_array[8]/g;
  $screen_html =~ s/:::grepin-fpq11:::/$data_array[9]/g;
  $screen_html =~ s/:::grepin-fpq12:::/$data_array[10]/g;
  $screen_html =~ s/:::grepin-fpq13:::/$data_array[11]/g;
  $screen_html =~ s/:::grepin-fpq14:::/$data_array[12]/g;
  if ($data_array[13] == 1) {
    $screen_html =~ s/:::grepin-fpq15a:::/$checked/g; # select the yes 
  } else {
    $screen_html =~ s/:::grepin-fpq15:::/$checked/g;  # select the no (default)
  }
  $screen_html =~ s/:::grepin-fpq16:::/$data_array[14]/g;

  $screen_html =~ s/:::grepin-fpq20:::/$data_array[15]/g;
  $screen_html =~ s/:::grepin-fpq21:::/$data_array[16]/g;
  $screen_html =~ s/:::grepin-fpq22:::/$data_array[17]/g;
  $screen_html =~ s/:::grepin-fpq23:::/$data_array[18]/g;
  $screen_html =~ s/:::grepin-fpq24:::/$data_array[19]/g;
  if ($data_array[20] == 1) {
    $screen_html =~ s/:::grepin-fpq25a:::/$checked/g; # select the yes 
  } else {
    $screen_html =~ s/:::grepin-fpq25:::/$checked/g;  # select the no (default)
  }
  $screen_html =~ s/:::grepin-fpq26:::/$data_array[21]/g;

  $screen_html =~ s/:::grepin-fpq30:::/$data_array[22]/g;
  $screen_html =~ s/:::grepin-fpq31:::/$data_array[23]/g;
  $screen_html =~ s/:::grepin-fpq32:::/$data_array[24]/g;
  $screen_html =~ s/:::grepin-fpq33:::/$data_array[25]/g;
  $screen_html =~ s/:::grepin-fpq34:::/$data_array[26]/g;
  if ($data_array[27] == 1) {
    $screen_html =~ s/:::grepin-fpq35a:::/$checked/g; # select the yes 
  } else {
    $screen_html =~ s/:::grepin-fpq35:::/$checked/g;  # select the no (default)
  }
  $screen_html =~ s/:::grepin-fpq36:::/$data_array[28]/g;

  $screen_html =~ s/:::grepin-fpq40:::/$data_array[29]/g;
  $screen_html =~ s/:::grepin-fpq41:::/$data_array[30]/g;
  $screen_html =~ s/:::grepin-fpq42:::/$data_array[31]/g;
  $screen_html =~ s/:::grepin-fpq43:::/$data_array[32]/g;
  $screen_html =~ s/:::grepin-fpq44:::/$data_array[33]/g;
  if ($data_array[34] == 1) {
    $screen_html =~ s/:::grepin-fpq45a:::/$checked/g; # select the yes 
  } else {
    $screen_html =~ s/:::grepin-fpq45:::/$checked/g;  # select the no (default)
  }
  $screen_html =~ s/:::grepin-fpq46:::/$data_array[35]/g;

  return (0, $screen_html);

}


sub d_model {

  my $prod_id   = $query->param('prd');
  my %prod_prof_dbfile;
  my $db_key;
  my ($title, $desc, $image_url, $dest_url, $theme, $num_of_keywords);
  my $screen_html_file = $PAGE_DIR.'prqck.html';
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

  $screen_html =~ s/:::grepin-fpq01:::/$title/g;
  $screen_html =~ s/:::grepin-fpq02:::/$desc/g;
  $screen_html =~ s/:::grepin-fpq03:::/$image_url/g;
  $screen_html =~ s/:::grepin-fpq04:::/$dest_url/g;
  if ($theme == 1) {
    $screen_html =~ s/:::grepin-fpq05a:::/$checked/g; # select the yes 
  } else {
    $screen_html =~ s/:::grepin-fpq05:::/$checked/g;  # select the no (default)
  }

  $screen_html =~ s/:::grepin-fpq11:::/$title/g;
  $screen_html =~ s/:::grepin-fpq12:::/$desc/g;
  $screen_html =~ s/:::grepin-fpq13:::/$image_url/g;
  $screen_html =~ s/:::grepin-fpq14:::/$dest_url/g;
  if ($theme == 1) {
    $screen_html =~ s/:::grepin-fpq15a:::/$checked/g; # select the yes 
  } else {
    $screen_html =~ s/:::grepin-fpq15:::/$checked/g;  # select the no (default)
  }

  $screen_html =~ s/:::grepin-fpq21:::/$title/g;
  $screen_html =~ s/:::grepin-fpq22:::/$desc/g;
  $screen_html =~ s/:::grepin-fpq23:::/$image_url/g;
  $screen_html =~ s/:::grepin-fpq24:::/$dest_url/g;
  if ($theme == 1) {
    $screen_html =~ s/:::grepin-fpq25a:::/$checked/g; # select the yes 
  } else {
    $screen_html =~ s/:::grepin-fpq25:::/$checked/g;  # select the no (default)
  }

  $screen_html =~ s/:::grepin-fpq31:::/$title/g;
  $screen_html =~ s/:::grepin-fpq32:::/$desc/g;
  $screen_html =~ s/:::grepin-fpq33:::/$image_url/g;
  $screen_html =~ s/:::grepin-fpq34:::/$dest_url/g;
  if ($theme == 1) {
    $screen_html =~ s/:::grepin-fpq35a:::/$checked/g; # select the yes 
  } else {
    $screen_html =~ s/:::grepin-fpq35:::/$checked/g;  # select the no (default)
  }

  $screen_html =~ s/:::grepin-fpq41:::/$title/g;
  $screen_html =~ s/:::grepin-fpq42:::/$desc/g;
  $screen_html =~ s/:::grepin-fpq43:::/$image_url/g;
  $screen_html =~ s/:::grepin-fpq44:::/$dest_url/g;
  if ($theme == 1) {
    $screen_html =~ s/:::grepin-fpq45a:::/$checked/g; # select the yes 
  } else {
    $screen_html =~ s/:::grepin-fpq45:::/$checked/g;  # select the no (default)
  }

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
