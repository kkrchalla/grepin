#!/usr/bin/perl 

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
}

# Grepin Search and Services
#

use Fcntl;

$|=1;    # autoflush

use CGI;

my $db_package = "";
package AnyDBM_File;
@ISA = qw(DB_File);
foreach my $isa (@ISA) {
  if( eval("require $isa") ) {
    $db_package = $isa;
    last;
  }
}
if( $db_package  ne 'DB_File' ) {
  die "*** The DB_File module was not found on your system.";
}

package main;

  my $query = new CGI;

  my $MAIN_DIR = '/home/grepinco/public_html/cgi-bin/';
  my $UTIL_DIR = $MAIN_DIR.'utility/';

  my $EMAIL_SUB_DB_FILE = $UTIL_DIR.'emailsub';

  my $cmd      = $query->param('cmd');
  my $category = $query->param('cat');	# s = site search, a = amazon promobar
  my $emailid  = $query->param('email');
  my %email_sub_dbfile;

  eval {
    tie %email_sub_dbfile, "DB_File", $EMAIL_SUB_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $EMAIL_SUB_DB_FILE: $!";  
    if (cmd eq 'optout') {
       sub_optout();
    } else {
       sub_optin();
    }
    untie %email_sub_dbfile;
  };
  if ($@){
    print $@;
    return 1;
  }

exit;

sub_optin {

  if (!$email_sub_dbfile{$emailid}) {
     $email_sub_dbfile{$emailid} = $category;
  } elsif ((($category eq 'a') && ($email_sub_dbfile{$emailid} eq 's')) || (($category eq 's') && ($email_sub_dbfile{$emailid} eq 'a'))) {
     $email_sub_dbfile{$emailid} = 'as';
  }

}


sub_optout {

  delete $email_sub_dbfile{$emailid};

}
