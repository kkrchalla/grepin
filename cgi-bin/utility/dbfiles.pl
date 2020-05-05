#!/usr/bin/perl -w
#$rcs = ' $Id: dbfiles.pl,v 1.0 2004/03/30 00:00:00 Exp $ ' ;

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

######################################

  my $cmd      = $query->param('cmd');
  my $path     = $query->param('path');
  my $key      = $query->param('key');
  my $numflds  = $query->param('numflds');
  my %user_dbm_file;
  my $return_code;
  my $return_msg;
  my ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25, $d26, $d27, $d28, $d29, $d30, $d31, $d32, $d33, $d34, $d35);


  print "Content-Type: text/html\n\n";

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
    print "dbmfile not found \n\n";
    exit;
  }

  $return_code = 0;

  if ($cmd eq "retrieve") {
    $return_code = m_retrieve();
  } elsif ($cmd eq "delete") {
    $return_code = m_delete();
  } elsif ($cmd eq "update") {
    $return_code = m_update();
  } 

  if ($return_code == 0) {
    m_display();
  }

  exit;    


sub m_retrieve {

  use Fcntl;

  if (!$path) {
    print "path not supplied \n\n";
    return 1;
  } 
  if (!$key) {
    print "key not supplied \n\n";
    return 1;
  } 
  if (!$numflds) {
    print "number of fields not supplied \n\n";
    return 1;
  } 

  eval {
    tie %user_dbm_file, "DB_File", $path, O_RDONLY, 0755 or die "Cannot open $path: $!";   
  };
  if ($@){
    print $@;
    return 1;
  }

  if (!$user_dbm_file{$key}) {
    print "no record found \n\n";
    return 1;
  } 

  if ($numflds == 1) {
    $d1 = $user_dbm_file{$key};
  } elsif ($numflds == 2) {
    ($d1, $d2) = unpack("C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 3) {
    ($d1, $d2, $d3) = unpack("C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 4) {
    ($d1, $d2, $d3, $d4) = unpack("C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 5) {
    ($d1, $d2, $d3, $d4, $d5) = unpack("C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 6) {
    ($d1, $d2, $d3, $d4, $d5, $d6) = unpack("C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 7) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 8) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 9) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 10) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 11) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 12) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 13) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 14) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 15) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 16) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 17) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 18) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 19) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 20) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 21) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 22) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 23) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 24) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 25) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 26) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25, $d26) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 27) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25, $d26, $d27) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 28) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25, $d26, $d27, $d28) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 29) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25, $d26, $d27, $d28, $d29) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 30) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25, $d26, $d27, $d28, $d29, $d30) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 31) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25, $d26, $d27, $d28, $d29, $d30, $d31) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 32) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25, $d26, $d27, $d28, $d29, $d30, $d31, $d32) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 33) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25, $d26, $d27, $d28, $d29, $d30, $d31, $d32, $d33) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } elsif ($numflds == 34) {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25, $d26, $d27, $d28, $d29, $d30, $d31, $d32, $d33, $d34) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  } else {
    ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25, $d26, $d27, $d28, $d29, $d30, $d31, $d32, $d33, $d34, $d35) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_dbm_file{$key});
  }

  untie %user_dbm_file;

  return 0;

}


sub m_delete {

  use Fcntl;

  if (!$path) {
    print "path not supplied \n\n";
    return 1;
  } 
  if (!$key) {
    print "key not supplied \n\n";
    return 1;
  } 

  eval {
    tie %user_dbm_file, "DB_File", $path, O_CREAT|O_RDWR, 0755 or die "Cannot open $path: $!";   
  };
  if ($@){
    print $@;
    return 1;
  }

  delete $user_dbm_file{$key};

  untie %user_dbm_file;

  return 0;

}

sub m_update {

  $d1       = $query->param('d1');
  $d2       = $query->param('d2');
  $d3       = $query->param('d3');
  $d4       = $query->param('d4');
  $d5       = $query->param('d5');
  $d6       = $query->param('d6');
  $d7       = $query->param('d7');
  $d8       = $query->param('d8');
  $d9       = $query->param('d9');
  $d10      = $query->param('d10');
  $d11      = $query->param('d11');
  $d12      = $query->param('d12');
  $d13      = $query->param('d13');
  $d14      = $query->param('d14');
  $d15      = $query->param('d15');
  $d16      = $query->param('d16');
  $d17      = $query->param('d17');
  $d18      = $query->param('d18');
  $d19      = $query->param('d19');
  $d20      = $query->param('d20');
  $d21      = $query->param('d21');
  $d22      = $query->param('d22');
  $d23      = $query->param('d23');
  $d24      = $query->param('d24');
  $d25      = $query->param('d25');
  $d26      = $query->param('d26');
  $d27      = $query->param('d27');
  $d28      = $query->param('d28');
  $d29      = $query->param('d29');
  $d30      = $query->param('d30');

  use Fcntl;

  if (!$path) {
    print "path not supplied \n\n";
    return 1;
  } 
  if (!$key) {
    print "key not supplied \n\n";
    return 1;
  } 
  if (!$numflds) {
    print "number of fields not supplied \n\n";
    return 1;
  } 

  eval {
    tie %user_dbm_file, "DB_File", $path, O_CREAT|O_RDWR, 0755 or die "Cannot open $path: $!";   
  };
  if ($@){
    print $@;
    return 1;
  }

  if ($numflds == 1) {
    $user_dbm_file{$key} = $d1;
  } elsif ($numflds == 2) {
    $user_dbm_file{$key} = pack("C/A* C/A*", $d1, $d2);
  } elsif ($numflds == 3) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A*",$d1, $d2, $d3);
  } elsif ($numflds == 4) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4);
  } elsif ($numflds == 5) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5);
  } elsif ($numflds == 6) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6);
  } elsif ($numflds == 7) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7);
  } elsif ($numflds == 8) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8);
  } elsif ($numflds == 9) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9);
  } elsif ($numflds == 10) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10);
  } elsif ($numflds == 11) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11);
  } elsif ($numflds == 12) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12);
  } elsif ($numflds == 13) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13);
  } elsif ($numflds == 14) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14);
  } elsif ($numflds == 15) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15);
  } elsif ($numflds == 16) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16);
  } elsif ($numflds == 17) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17);
  } elsif ($numflds == 18) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18);
  } elsif ($numflds == 19) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19);
  } elsif ($numflds == 20) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20);
  } elsif ($numflds == 21) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21);
  } elsif ($numflds == 22) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22);
  } elsif ($numflds == 23) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23);
  } elsif ($numflds == 24) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24);
  } elsif ($numflds == 25) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25);
  } elsif ($numflds == 26) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25, $d26);
  } elsif ($numflds == 27) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25, $d26, $d27);
  } elsif ($numflds == 28) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25, $d26, $d27, $d28);
  } elsif ($numflds == 29) {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25, $d26, $d27, $d28, $d29);
  } else {
    $user_dbm_file{$key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18, $d19, $d20, $d21, $d22, $d23, $d24, $d25, $d26, $d27, $d28, $d29, $d30);
  }

  untie %user_dbm_file;

  return 0;

}

sub m_display {

  use Fcntl;

  my $html_file = '/home/grepinco/public_html/cgi-bin/utility/dbfiles.html';
  my $page_html;

  eval {
    open (HTMLFILE, $html_file) or die "Cannot open htmlfile '$html_file' for reading: $!";

    while (<HTMLFILE>) {
      $page_html .= $_;
    }
    close(HTMLFILE);
  };
  if ($@){
    print $@;
    return 1;
  }

  $page_html =~ s/:::path:::/$path/g;
  $page_html =~ s/:::key:::/$key/g;
  $page_html =~ s/:::numflds:::/$numflds/g;

  $page_html =~ s/:::d1:::/$d1/g;
  $page_html =~ s/:::d2:::/$d2/g;
  $page_html =~ s/:::d3:::/$d3/g;
  $page_html =~ s/:::d4:::/$d4/g;
  $page_html =~ s/:::d5:::/$d5/g;
  $page_html =~ s/:::d6:::/$d6/g;
  $page_html =~ s/:::d7:::/$d7/g;
  $page_html =~ s/:::d8:::/$d8/g;
  $page_html =~ s/:::d9:::/$d9/g;
  $page_html =~ s/:::d10:::/$d10/g;
  $page_html =~ s/:::d11:::/$d11/g;
  $page_html =~ s/:::d12:::/$d12/g;
  $page_html =~ s/:::d13:::/$d13/g;
  $page_html =~ s/:::d14:::/$d14/g;
  $page_html =~ s/:::d15:::/$d15/g;
  $page_html =~ s/:::d16:::/$d16/g;
  $page_html =~ s/:::d17:::/$d17/g;
  $page_html =~ s/:::d18:::/$d18/g;
  $page_html =~ s/:::d19:::/$d19/g;
  $page_html =~ s/:::d20:::/$d20/g;
  $page_html =~ s/:::d21:::/$d21/g;
  $page_html =~ s/:::d22:::/$d22/g;
  $page_html =~ s/:::d23:::/$d23/g;
  $page_html =~ s/:::d24:::/$d24/g;
  $page_html =~ s/:::d25:::/$d25/g;
  $page_html =~ s/:::d26:::/$d26/g;
  $page_html =~ s/:::d27:::/$d27/g;
  $page_html =~ s/:::d28:::/$d28/g;
  $page_html =~ s/:::d29:::/$d29/g;
  $page_html =~ s/:::d30:::/$d30/g;
  $page_html =~ s/:::d31:::/$d31/g;
  $page_html =~ s/:::d32:::/$d32/g;
  $page_html =~ s/:::d33:::/$d33/g;
  $page_html =~ s/:::d34:::/$d34/g;
  $page_html =~ s/:::d35:::/$d35/g;

  print $page_html;

  return 0;

}

