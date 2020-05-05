#!/usr/bin/perl

  BEGIN {
     $|=1;
     use CGI::Carp('fatalsToBrowser');
  }

  # Grepin Search and Services
  # Copyright (C) 2004 Grepin Search and Services <contact@grepin.com>

  {
    $0 =~ /(.*)(\\|\/)/;
    push @INC, $1 if $1;
  }

  use Fcntl;
  use CGI;

  package main;

  my $query = new CGI;

  print "Content-Type: text/html\n\n";

  my $password = $query->param('pwd');
  my $fname = $query->param('fname');
  if ($password ne 'mzlapqnxksowbcjdie'){
    print "You are not authorized to invoke this program.\n";
    exit;
  }

  if (!$fname) {
    print "File name has to be supplied.\n";
    exit;
  }

  my $file_name;
  if ($fname eq 'errorlog'){
    $file_name = 'errorlog.txt';
  } elsif ($fname eq 'srcherrlog'){
    $file_name = 'srcherrlog.txt';
  } elsif ($fname eq 'webscrerr'){
    $file_name = 'webscrerr.txt';
  } else {
    print "Invalid File name.\n";
    exit;
  }


  my $ERRFILE = '/home/grepinco/public_html/cgi-bin/log/'.$file_name;

  print "<font face=courier>\n";

  print "<br><b><u><font size=3> Deleting Error log file - $file_name </u></b><font size=0> \n";
  eval {
    if (-e $ERRFILE) {
      unlink($ERRFILE) or (die "Cannot delete '$ERRFILE': $!");
    }
  };
  if ($@){
    print "$@ \n";
  }


  print "<br><br><br><b> THE END <b> \n";


  exit;