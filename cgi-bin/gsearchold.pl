#!/usr/bin/perl -w
#$rcs = ' $Id: gsearch,v 1.0 2004/03/30 00:00:00 Exp $ ' ;

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
#   use CGI::Carp qw(carpout);
#   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/srcherrlog.txt")
#       or die "Unable to append to errorlog: $!\n";
#   carpout(*ERRORLOG);
}

# Grepin Search and Services
# Copyright (C) 2004 Grepin Search and Services <contact@grepin.com>

# Comment in the next two lines to log and show how long searches take:
use Time::HiRes qw ();
my $start_time = [Time::HiRes::gettimeofday];

$|=1;    # autoflush

use CGI;
use Fcntl;
use POSIX qw(strftime);

#use Compress::Zlib;
#my $compressed_data;

# added program path to @INC because it fails to find ./conf.pl if started from
# other directory
{ 
  # block is for $1 not mantaining its value
  $0 =~ /(.*)(\\|\/)/;
  push @INC, $1 if $1;
}

my $db_package = "";
# To use tainting, comment in the next 2 lines and comment out the next 8 lines.
# Note that you also have to add "./" to the filenames in the require commands.
#use DB_File;
#$db_package = 'DB_File';
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

package main;

my $query;
$query = new CGI;

my $user_id = $query->param('uid');

print "Content-Type: text/html\n\n";

if (!$user_id){
  print "<br />Note: The parameter uid is either invalid or empty.\n";
  print "<br />      Please give the correct uid and try again.\n";
  print "<br />      Or please inform the webmaster about this error.\n";
  exit;
}

my $MAIN_DIR          = '/home/grepinco/public_html/cgi-bin/';
my $SEARCH_URL        = '/cgi-bin/gsearch.pl';
my $INSTALL_DIR       = $MAIN_DIR.'users/users/'.$user_id.'/search/';
my $DATA_DIR          = $INSTALL_DIR.'/data/';
my $LOGDIR            = $INSTALL_DIR.'/log/';
my $TEMPLATE_DIR      = $INSTALL_DIR.'/templates/';

my $STOPWORDS_FILE    = $INSTALL_DIR.'/stopwords.txt';

my $UPDATE_FILE       = $DATA_DIR.'update';
my $INV_INDEX_DB_FILE = $DATA_DIR.'inv_index';
my $DOCS_DB_FILE      = $DATA_DIR.'docs';
my $URLS_DB_FILE      = $DATA_DIR.'urls';
my $SIZES_DB_FILE     = $DATA_DIR.'sizes';
my $TERMS_DB_FILE     = $DATA_DIR.'terms';
my $DF_DB_FILE        = $DATA_DIR.'df';
my $TF_DB_FILE        = $DATA_DIR.'tf';
my $CONTENT_DB_FILE   = $DATA_DIR.'content';
my $DESC_DB_FILE      = $DATA_DIR.'desc';
my $TITLES_DB_FILE    = $DATA_DIR.'titles';
my $DATES_DB_FILE     = $DATA_DIR.'dates';

my $USER_AFF_DB_FILE  = $MAIN_DIR.'users/useraff';

my $INDEX_NUMBERS     = 1;
my $RESULTS_TEMPLATE  = $TEMPLATE_DIR.'resultspage.html';
my $INITRSLT_TEMPLATE = $TEMPLATE_DIR.'initrsltpage.html';
my $SEARCH_TEMPLATE   = $TEMPLATE_DIR.'search.html';
my $NO_MATCH_TEMPLATE = $TEMPLATE_DIR.'nomatch.html';

my $RESULTS_PER_PAGE  = 10;
my @EXT = ("html", "HTML", "htm", "HTM", "shtml", "SHTML");
my $HTTP_DEBUG = 1;
my $MAX_RESULTS = 0;
my $PERCENTAGE_RANKING = 1;
my $CONTEXT_SIZE = 10000;
my $CONTEXT_EXAMPLES = 3;
my $CONTEXT_DESC_WORDS = 10;
my $MINLENGTH = 3;
my $SPECIAL_CHARACTERS = 1;
my $STEMCHARS = 0;
my $MULTIPLE_MATCH_BOOST = 2;
my $DATE_FORMAT = "%Y-%m-%d";
my $IGNORED_WORDS = '<p>The following words are either too short or very common and were
	not included in your search: <strong><WORDS></strong></p>';
my $PREV_PAGE = "Previous";
my $NEXT_PAGE = "Next";

# get results_per_page data from the query
if(defined($query->param('disp')) && ($query->param('disp') == (5 || 10 || 15 || 20 || 25 || 30 || 35 || 40 || 45 || 50 || 75 || 100))) {
  $RESULTS_PER_PAGE = $query->param('disp');
}

my $yday = (localtime time())[7];
my $LOGFILE   = $LOGDIR.'searchlog'.$yday;
my $ERRORFILE = $LOGDIR.'errorlog';

# See indexer.pl for a description of the data structures:
my %inv_index_db;
my %docs_db;
my %sizes_db;
my %desc_db;
my %content_db;
my %titles_db;
my %dates_db;
my %terms_db;
my %users_aff_db;

eval {
  tie %inv_index_db, $db_package, $INV_INDEX_DB_FILE, O_RDONLY, 0755 or die "Cannot open $INV_INDEX_DB_FILE: $!";   
  tie %docs_db,      $db_package, $DOCS_DB_FILE, O_RDONLY, 0755 or die "Cannot open $DOCS_DB_FILE: $!";   
  tie %sizes_db,     $db_package, $SIZES_DB_FILE, O_RDONLY, 0755 or die "Cannot open $SIZES_DB_FILE: $!";   
  tie %desc_db,      $db_package, $DESC_DB_FILE, O_RDONLY, 0755 or die "Cannot open $DESC_DB_FILE: $!";   
  tie %content_db,   $db_package, $CONTENT_DB_FILE, O_RDONLY, 0755 or die "Cannot open $CONTENT_DB_FILE: $!"; 
  tie %titles_db,    $db_package, $TITLES_DB_FILE, O_RDONLY, 0755    or die "Cannot open $TITLES_DB_FILE: $!";   
  tie %dates_db,     $db_package, $DATES_DB_FILE, O_RDONLY, 0755 or die "Cannot open $DATES_DB_FILE: $!";   
  tie %terms_db,     $db_package, $TERMS_DB_FILE, O_RDONLY, 0755 or die "Cannot open $TERMS_DB_FILE: $!";   
  tie %users_aff_db, $db_package, $USERS_AFF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USERS_AFF_DB_FILE: $!";   
};
if ($@) {
  print "<br />Note: This web site is not yet indexed for search.\n";
  print "<br />      Please inform the webmaster about this error.\n";
  exit;
}  

my (@force, @not, @other);
my (@docs, @valid_docs);
my %answer;

build_char_string();
my %stopwords_hash = load_stopwords();
my @stopwords = keys(%stopwords_hash);
my @stopwords_ignored;    # stopwords that are in the user's query
my $punct = ',.!?:"\'/%()-';
my $joker;

main();

untie %inv_index_db;
untie %docs_db;
untie %sizes_db;
untie %desc_db;    
untie %content_db; 
untie %titles_db;  
untie %dates_db;   
untie %terms_db;   
untie %users_aff_db;

exit;

sub main {
    # initialize everything with empty values (because we might run under mod_perl)
    @force = ();
    @not = ();
    @other = ();
    @docs = ();
    @valid_docs = ();
    %answer = ();

    # code for adding wild-card or joker
    if ($query->param('q') =~ /\*/) {
      # it is a wild-card search
      $joker = 1;
    } else {
      $joker = 0;
    }
    if ($joker) {
      create_joker_query();
    } else {
      create_query();
      apply_booleans();
    }
    answer_query();

    my $html = cast_template();
    print $html;
    if ($query->param('q')) {
      log_query();
    }
}

sub is_ignored {
  my $buffer = shift;
  my $save = shift;
  if( ! $INDEX_NUMBERS && $buffer =~ m/^\d+$/ ) {
    add_ignored($buffer, $save);
    return 1;
  }
  if( grep(/^\Q$buffer\E$/, @stopwords) || length($buffer) < $MINLENGTH ) {
    add_ignored($buffer, $save);
    return 1;
  } else {
    return 0;
  }
}

sub add_ignored {
  my $term = shift;
  my $save = shift;
  if( $save && ! grep(/^\Q$term\E$/, @stopwords_ignored) ) {
    # don't show words twice:
    push(@stopwords_ignored, $term);
  }
}

sub create_joker_query {
  my $query_str = cleanup($query->param('q'));
  my $mode = cleanup($query->param('mode'));
  my @terms = split " ", $query_str;
  my $buffer;
  my ($sterm, $nterm);
  
  my @tmpforce = ();
  my $ct = 0;
  foreach my $term (@terms) {
    $ct++;
    my $org_term = $term;
    $term = normalize($term);
    if( grep(/^\Q$term\E$/, @stopwords) ) {
      push(@stopwords_ignored, $org_term);
      next;
    }
    $term =~ s/^\s+//;
    $term =~ s/\s+$//;
    $sterm = stem($term);
    @tmpforce = ();
    if ( $mode eq 'all' && $term !~ m/^(\+|\-)/ ) {
      # For "Match all words" just add a "+" to every term that has no operator:
      $term = '+'.$term;
    }
    if( $term =~ /\*/ ) {
      $term =~ s/\*/.*/g;	# use '*' as Joker
      foreach $listterm (keys %terms_db) {
       #debug: print "$listterm =~ m/^$term\$/i ($terms_db{$listterm})<br>\n";
       if( $listterm =~ m/^$term$/i ) {
          #print "** match<br>\n";
          %v = unpack("S*", $inv_index_db{$terms_db{$listterm}});
          push(@tmpforce, keys %v);
          push(@force, $terms_db{$listterm});
        }
      }
    } else {
      if( $terms_db{$sterm} ) {
        %v = unpack("S*", $inv_index_db{$terms_db{$sterm}});
        push(@tmpforce, keys %v);
        push(@force, $terms_db{$sterm});
       }
    }
    if( $ct > 1 ) {
      @valid_docs = intersection(\@valid_docs, \@tmpforce);
    } else {
      @valid_docs = @tmpforce;
    }
  }
}

sub create_query {
  my $query_str = cleanup($query->param('q'));
  my $mode = cleanup($query->param('mode'));
  my @terms = split(/\s+/, $query_str);
  my $buffer;
  my ($sterm, $nterm);
  
  # Use an extra loop because the loop below will stop
  # on the first term that's not found if there's an AND search:
  foreach my $term (@terms) {
    is_ignored($term, 1);
  }
  
  foreach my $term (@terms) {
    if( is_ignored($term, 0) ) {
      next;
    }
    $buffer = normalize($term);
    foreach my $nterm (split " ",$buffer) {
      $sterm = stem($nterm);
      # For "Match all words" just add a "+" to every term that has no operator:
      if ( $mode eq 'all' && $term !~ m/^(\+|\-)/ ) {
        $term = '+'.$term;
      }
      if ($term =~ /^\+/) {
        if ($terms_db{$sterm}) {
          push @force, $terms_db{$sterm};
        } else {
          return 0;    # this term was not found, we can stop already
        }
      } elsif ($term =~ /^\-/) {
        push @not, $terms_db{$sterm} if $terms_db{$sterm};
      } else {
        push @other, $terms_db{$sterm} if $terms_db{$sterm};
      }
    }
  }
}

sub apply_booleans {
  #locate the valid documents by applying the booleans
  my ($term_id, $doc_id, $first_doc_id);
  my %v = ();
  my @ary = ();
  my @not_docs = ();

  my %not_docs = ();
  map { $not_docs{$_} = 1 } @not_docs;

  foreach $term_id (@not) {
    %v = unpack("S*", $inv_index_db{$term_id});
    foreach $doc_id (keys %v) {
      push @not_docs, $doc_id unless exists $not_docs{$doc_id};
    }
  }
  
  if (@force) {
    $first_doc_id = pop @force;
    %v  = unpack("S*", $inv_index_db{$first_doc_id});
    @valid_docs = keys %v; 
    foreach $term_id (@force) {
      %v = unpack("S*", $inv_index_db{$term_id});
      @ary = keys %v;
      @valid_docs = intersection(\@valid_docs, \@ary);
    }
    push @force, $first_doc_id;
  } else {
    @valid_docs = keys %docs_db;
  }

  @valid_docs = minus(\@valid_docs, \@not_docs);
}

sub answer_query {
  my @term_ids = (@force, @other);
  my %valid_docs = ();
  map { $valid_docs{$_} = 1 } @valid_docs;

  foreach my $term_id (@term_ids) {
    my %v = unpack('S*', $inv_index_db{$term_id});
    foreach my $doc_id (keys %v) {
      # optionally include only certain files:
      my $include_exp = $query->param('i');
      $include_exp =~ s/\\\*/\.\*/g;  # * is replaced by .*
      # TODO: escaping $include_exp/$exclude_exp would disable use of RegExp
      next if( $include_exp && $docs_db{$doc_id} !~ m/$include_exp/i );
      # optionally exclude certain files:
      my $exclude_exp = $query->param('e');
      $exclude_exp =~ s/\\\*/\.\*/g;  # * is replaced by .*
      next if( $exclude_exp && $docs_db{$doc_id} =~ m/$exclude_exp/i );
      if( exists $valid_docs{$doc_id} ) {
        my $boost = $answer{$doc_id};
        $answer{$doc_id} += $v{$doc_id};
        $answer{$doc_id} *= $MULTIPLE_MATCH_BOOST if( $MULTIPLE_MATCH_BOOST && $boost );
        if( $query->param('priority') && $query->param('priority') != 0 && $dates_db{$doc_id} != -1 ) {
          # increase the rank of new documents by giving old ones low priority:
          my $age_in_days = (time() - $dates_db{$doc_id})/60/60/24;
          my $priority = $age_in_days * $query->param('priority');
          $priority = 100 if( $priority > 100 );
          $answer{$doc_id} = $answer{$doc_id} - (($answer{$doc_id}/100) * $priority);
        }
      }
    }
  }
}

# Populate the template with search results. All external data has to be
# accessed via cleanup(), to avoid cross site scripting attacks.
sub cast_template {
  my %h = ();
  my $rank = 0;

  my $p = cleanup($query->param('p'));
  my $include = cleanup($query->param('i'));
  my $exclude = cleanup($query->param('e'));
  my $priority = cleanup($query->param('priority'));
  my $mode = cleanup($query->param('mode'));
  my $sort = cleanup($query->param('sort'));
  my $q = cleanup($query->param('q'));
  my $disp = cleanup($query->param('disp'));
  my $show_content = cleanup($query->param('content'));
  my $source = cleanup($query->param('source'));
  my $category     = $query->param('category');
  my $border_color = $query->param('bcolor');
  my $footer_color = $query->param('fcolor');
  my $assoc_id     = $query->param('aid');
  my $locale       = $query->param('locale');

  my $results_file = $RESULTS_TEMPLATE;
  my $initrslt_file = $INITRSLT_TEMPLATE;
  my $file;

  if( keys(%answer) == 0 ) {
    # No match found
    $file = $NO_MATCH_TEMPLATE;
  } else {
    $file = $SEARCH_TEMPLATE;
  }
  my $template = get_template($results_file, $file, $initrslt_file);
  # %h carries values that will show up in the result page at <!--cgi: key-->:
  $h{'uid'} = $user_id;
  $h{'query_str'}   = $q;
  $h{'query_str_escaped'} = my_uri_escape($q);    # can be used to link to other search engines
  $h{'docs_total'} = keys %docs_db;
  $h{'i'} = $include;
  $h{'e'} = $exclude;
  $h{'priority'} = $priority;
  $h{'sort'} = $sort;
  $h{'disp'} = $disp;
  $h{'content'} = $show_content;
  $h{'source'} = $source;
  $h{'category'} = $category;
  $h{'locale'} = $locale;
  $h{'fcolor'} = $footer_color;
  $h{'bcolor'} = $border_color;
  $h{'aid'} = $assoc_id;

  if( $mode eq 'all' ) {
    $h{'match_all'} = "checked";
  } else {
    $h{'match_all'} = "";
  }

  if( scalar(@stopwords_ignored) > 0 ) {
    my $ignored_terms = join(" ", @stopwords_ignored);
    if( $IGNORED_WORDS ) {
      $IGNORED_WORDS =~ s/<WORDS>/$ignored_terms/gs;
      $h{'ignored_terms'} = $IGNORED_WORDS;
    }
  } else {
    $h{'ignored_terms'} = "";
  }

  my $current_page = $p;
  $current_page ||= 1;

  my ($first, $last); 
  $first = ($current_page - 1) * $RESULTS_PER_PAGE; 
  $last  = $first + $RESULTS_PER_PAGE - 1;
  
  my $percent_factor = 0;
  if( $PERCENTAGE_RANKING ) {
    my $max_score = 0;
    foreach my $doc_ranking (values %answer) {
      $max_score = $doc_ranking if( $doc_ranking > $max_score );
    }
    $percent_factor = 100/$max_score if( $max_score );
  }
  
  my @keys; 
  if (defined($query->param('sort'))) { 
    if ($query->param('sort') eq 'title') { 
      @keys = sort {uc($titles_db{$a}) cmp uc($titles_db{$b})} (keys %answer); 
    } elsif ($query->param('sort') eq 'date' ) { 
      @keys = sort {uc($dates_db{$b}) cmp uc($dates_db{$a})} (keys %answer); 
    } elsif ($query->param('sort') eq 'size' ) { 
      @keys = sort {uc($sizes_db{$b}) cmp uc($sizes_db{$a})} (keys %answer); 
    } else { 
      @keys = sort {$answer{$b} <=> $answer{$a}} (keys %answer); 
    } 
  } else { 
    @keys = sort {$answer{$b} <=> $answer{$a}} (keys %answer); 
  } 

  my $real_last = keys(%answer);

  if ($real_last > 0) {
    if( $MAX_RESULTS > 0 ) {
      if( $real_last > $MAX_RESULTS ) {
        $real_last = $MAX_RESULTS;
      }
    }
    if ($last >= $real_last) {
      $last = $real_last - 1;
    }
    $h{'first_number'} = $first+1;
    $h{'last_number'} = $last+1;
  } else {
    $h{'first_number'} = 0;
    $h{'last_number'} = 0;
  }

  my @terms = split(" ", normalize_special_chars($q));
  my $all_terms; 
  my $first_time = 1; 
  # +/- operators aren't interesting here:
  # and put all the terms together for good matching and form all_terms
  foreach my $term (@terms) {
    $term =~ s/^(\+|\-)//;
    my $boldterm = $term; 
    $boldterm =~ s/([^\w\s])/\\$1/g; 
    $boldterm = &add_wildcard($boldterm) if ($boldterm =~ /\S\\\* / || $boldterm =~ /\S\\\*$/); 
    if ($first_time == 1) { 
      $all_terms = '(\b'.$boldterm.'\b)'; 
      $first_time = 0;
    } else { 
      $all_terms .= '|(\b'.$boldterm.'\b)'; 
    } 
  }

  my $result_count = 0;
  foreach (@keys[$first..$last]) {
    my $score = $answer{$_};
    if( $PERCENTAGE_RANKING ) {
      $score = sprintf("%.f", $score*$percent_factor);
      $score .= '%';
    } else {
      $score = sprintf("%.2f", $score/100);
    }

    my $desc = get_summary($_, $all_terms, @terms);
    my $visible_url;
    $url = $docs_db{$_};
    $visible_url = $docs_db{$_};
    my $show_url = CGI::escape($docs_db{$_});
    my $date;
    if( $dates_db{$_} != -1 ) {
      $date = POSIX::strftime($DATE_FORMAT, localtime($dates_db{$_}));
    } else {
      $date = '-';
    }
    my $title = get_title_highlight($titles_db{$_}, $q);
    $template = template_results($template, [{rank => $first+(++$rank), 
                       url => $url,
                       visibleurl => $visible_url, 
                       title => $title, 
                       date => $date, 
                       score => $score,
                       description => $desc,
                       size => sprintf("%.0f", $sizes_db{$_}/1000) || 1,
                      }]);
    $result_count++;
  }
  $template =~ s/<!--\s*loop:\s*results\s*-->.*<!--\s*end:\s*results\s*-->//s;

  $h{'results_num'} = $real_last;
  
  my $last_page = ceil($real_last, $RESULTS_PER_PAGE);
  $last_page ||= 1;
  # Note: Keep order of arguments as in search_form.html to get correct visited link recognition:
  # Note that using "&" is correct, "&" isn't. 
  my $queries = "&uid=".CGI::escape($user_id);
  $queries .= "&i=".CGI::escape($include);
  $queries .= "&e=".CGI::escape($exclude);
  $queries .= "&priority=".CGI::escape($priority);
  if( defined($query->param('sort')) ) {
    $queries .= "&sort=".CGI::escape($query->param('sort'));
  }
  if( defined($query->param('disp')) ) {
    $queries .= "&disp=".CGI::escape($query->param('disp'));
  }
  if( defined($query->param('content')) ) {
    $queries .= "&content=".CGI::escape($query->param('content'));
  }
  if( defined($query->param('source')) ) {
    $queries .= "&source=".CGI::escape($query->param('source'));
  }
  $queries .= "&mode=".CGI::escape($mode);
  $queries .= "&q=".CGI::escape($q);
  $queries .= "&category=$category&locale=$locale&bcolor=$border_color&fcolor=$footer_color&aid=$assoc_id";

  if ($current_page == 1) {
    $h{'previous'} = "";
    if ($last_page > $current_page) {
      $h{'next'} = "<a href=\"$SEARCH_URL?p=2$queries\">$NEXT_PAGE</a>";
    } else {
      $h{'next'} = "";
    }
  } elsif ($current_page == $last_page) {
    $h{'previous'} = "<a href=\"$SEARCH_URL?p=".($last_page-1)."$queries\">$PREV_PAGE</a>";
    $h{'next'} = "";
  } else {
    $h{'previous'} = "<a href=\"$SEARCH_URL?p=".($current_page-1)."$queries\">$PREV_PAGE</a>";
    $h{'next'} = "<a href=\"$SEARCH_URL?p=".($current_page+1)."$queries\">$NEXT_PAGE</a>";
  }
  
  for (1..$last_page) {
    if ($_ != $current_page) {
      $h{'navbar'} .= "<a href=\"$SEARCH_URL?p=$_$queries\">$_</a> ";
    } else {
      $h{'navbar'} .= "<strong>$_</strong> ";
    }
  }

  $h{'current_page'} = $current_page;
  $h{'total_pages'}  = $last_page;
  $h{'search_url'}   = $SEARCH_URL;

  $h{'search_time'} = '';
  # Show time needed to search:
  if( $start_time ) {
    $h{'search_time'} = sprintf(" %.2f seconds", Time::HiRes::tv_interval($start_time));
  }

  my ($aff_id, $aff_us, $aff_uk, $d1);
  if ($user_aff_db{$user_id}) {
    ($aff_id, $aff_us, $aff_uk, $d1) = unpack("C/A* C/A* C/A* C/A*",$user_aff_db{$user_id});
  }

  my $tower_disp;
  if( keys(%answer) == 0 ) {
    $tower_disp = 1;
  } else {
    if (($last - $first) < 3) { 
      $tower_disp = 1;
    } elsif (($last - $first) < 5) { 
      $tower_disp = 2;
    } elsif (($last - $first) < 7) { 
      $tower_disp = 3;
    } else { 
      $tower_disp = 4;
    }
  }

  my $skyscraper_url = "http://www.grepin.com/cgi-bin/amznbar.pl?query=$q&category=$category&out=javascript&locale=$locale&page=$current_page&bcolor=$border_color&fcolor=$footer_color&type=tower&disp=$tower_disp&seq=2&aid=$assoc_id&uid=$user_id&aus=$aff_us&auk=$aff_uk&source=$source&gsrc=1";
  my $skybar_url     = "http://www.grepin.com/cgi-bin/amznbar.pl?query=$q&category=$category&out=javascript&locale=$locale&page=$current_page&bcolor=$border_color&fcolor=$footer_color&type=bar&seq=1&aid=$assoc_id&uid=$user_id&aus=$aff_us&auk=$aff_uk&source=$source&gsrc=1";

# http://www.grepin.com/cgi-bin/amznbar.pl?query=&category=&itemid=&out=&locale=&page=&type=&seq=&bcolor=&fcolor=&disp=&aid=&uid=&aus=&auk=&source=&gsrc=
# '<iframe src="http://www.grepin.com/cgi-bin/amznbar.pl?query=$q&category=$category&out=&locale=$locale&page=$current_page&bcolor=$border_color&fcolor=$footer_color&disp=4&type=bar&seq=1&aid=$assoc_id&uid=$user_id&aus=$aff_us&auk=$aff_uk&source=$source&gsrc=1" width="" height="" scrolling="no" marginwidth="0" marginheight="0" frameborder="0"></iframe>';

  $h{'skybar'}       = '<script src="'.$skybar_url.'"></script>';
  $h{'skyscraper'}   = '<script src="'.$skyscraper_url.'"></script>';

  $template =~ s/<!--\s*cgi:\s*(\S+?)\s*-->/$h{$1}/gis;
  $template =~ s/:::grepin-query-string:::/$q/g;

  return $template;
}

sub get_template {
   my $results_file = shift;
   my $file = shift;
   my $init_results_file = shift;
   my $templfile;
   my $srchtemplfile;
   eval {
     if (-e $results_file) {
       open(RESULTS_FILE, $results_file) or die "Cannot open file $results_file: $!";
     } else {
       open(RESULTS_FILE, $init_results_file) or die "Cannot open file $init_results_file: $!";
     }
     while(<RESULTS_FILE>) {
         $templfile .= $_;
         last if /<\/html>/i;
     }
     close(RESULTS_FILE);
     open(FILE, $file) or die "Cannot open file $file: $!";
     while(<FILE>) {
         $srchtemplfile .= $_;
         last if /<\/html>/i;
     }
     $templfile =~ s/:::search-results:::/$srchtemplfile/g;
   };
   if ($@) {
     log_error ("gettemplate", $@);
     print "<br />Note: There has been an internal error displaying the search results.\n";
     print "<br />      Please inform the webmaster about this error.\n";
     exit;
   }
   return $templfile;
}

sub template_results {
   my ($templ_loop, $results_values) = @_;
   $templ_loop =~ m/<!--\s*loop:\s*results\s*-->(.*)<!--\s*end:\s*results\s*-->/s;
   my $loop = $1;
   my $loop_copy = $loop;
   my $out;
   foreach (@{$results_values}) {
     $loop = $loop_copy;
     $loop =~ s/<!--\s*item:\s*(\S+?)\s*-->/$$_{$1}/gis;
     $out .= $loop;
   }
   $templ_loop =~ s/(<!--\s*loop:\s*results\s*-->).*(<!--\s*end:\s*results\s*-->)/$out$1$loop_copy$2/s;
   return $templ_loop;
}

sub get_title_highlight {
  my $title = $_[0];
  my @terms = split(" ", normalize_special_chars($_[1]));
  foreach my $term (@terms) {
    my $bldterm = $term;
    $bldterm =~ s/([^\w\s])/\\$1/g;
    $bldterm = add_wildcard($bldterm) if ($bldterm =~ /\S\\\* / || $bldterm =~ /\S\\\*$/);
    $title =~ s/\b($bldterm)\b/\n\t$1\n \t/gis;
  }
  $title =~ s/\n\t/<B>/gs;
  $title =~ s/\n \t/<\/B>/gs;
  return $title;
}

# Log the query in a file, using this format:
# REMOTE_HOST;date;terms;matches;current page;(time to search in seconds);
# For the last value you need to use Time::HiRes (see top of the script)
sub log_query {

  my $elapsed_time = sprintf("%.2f", Time::HiRes::tv_interval($start_time)) if( $start_time );
  my @line = ();
  my $addr = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};
  push(@line, $query->param('q') || '-',
              time(),
              $elapsed_time || '-',
              scalar(keys %answer),
              $query->param('p') || 0,
              $query->param('source') || '-',
              $addr || '-');

  use Fcntl ':flock';        # import LOCK_* constants
  open(LOG, ">>$LOGFILE") or die "Cannot open logfile '$LOGFILE' for writing: $!";
  flock(LOG, LOCK_EX);
  seek(LOG, 0, 2);
  print LOG join(':::', @line).":::\n";
  flock(LOG, LOCK_UN);
  close(LOG);
}

# Log the error in a file, using this format:
# REMOTE_HOST;date;terms;
# For the last value you need to use Time::HiRes (see top of the script)
sub log_error {

  my $process = shift;
  my $message = shift;
  my @line = ();
  my $addr = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};
  push(@line, $process || '-',
              $message || '-',
              $query->param('q') || '-',
              get_iso_date(),
              $addr || '-');

  use Fcntl ':flock';        # import LOCK_* constants
  open(ERRLOG, ">>$ERRORFILE") or die "Cannot open errorfile '$ERRORFILE' for writing: $!";
  flock(ERRLOG, LOCK_EX);
  seek(ERRLOG, 0, 2);
  print ERRLOG join(':::', @line).":::\n";
  flock(ERRLOG, LOCK_UN);
  close(ERRLOG);
}

sub normalize {
  my $buffer = $_[0];

  $buffer =~ s/-(\s*\n\s*)?//g; # join parts of hyphenated words

  if( $SPECIAL_CHARACTERS ) {
    # We don't have special characters in our index, so don't try to search for them:
    $buffer =~ s/[∆Ê]/ae/gs;
    $buffer =~ s/[ﬁ˛]/th/igs;
    $buffer =~ s/ﬂ/ss/gs;
    $buffer =~ tr/ƒ≈∆«»“…‹” Ê›‘ÀÁﬁ’Ã˙ÒËﬂ÷Õ˚ÚÈ‡Œ¸ÛÍ·ÿœ˝ÙÎ‚Ÿ–˛ıÏ„⁄—ˇˆÌ‰€¿ÓÂ¡¯Ô¬˘√/AAACEOEUOEaYOEecTOIunesOIuoeaIuoeaOIyoeaUEtoiaUNyoiaUAiaAoiAuA/;
  }

  if ($INDEX_NUMBERS) {
    $buffer =~ s/(<[^>]*>)/ /gs;
  } else {
    $buffer =~ s/(\b\d+\b)|(<[^>]*>)/ /gs;
  }

  if ($joker) {
    $buffer =~ tr/a-zA-Z0-9_*/ /cs;		# joker: don't filter '*'
  } else {
    $buffer =~ tr/a-zA-Z0-9_/ /cs;
    $buffer =~ s/^\s+//;
    $buffer =~ s/\s+$//;
  }
  return lc $buffer;
}

# Returns the content of the META description tag or the context of the match,
# if $CONTEXT_SIZE is enabled:
sub get_summary {
  my $id = shift;
  my $all_terms = shift;
  my @terms = @_;
  my $desc;
  if( $CONTEXT_SIZE && ($query->param('content') == 1)) {
#    $compressed_data = $content_db{$id};
#    $uncompressed_data = uncompress($compressed_data);
#    $desc = get_context($uncompressed_data, $all_terms);
    $desc = get_context($content_db{$id}, $all_terms);
  }    
  if( length $desc == 0 ) {
#    $compressed_data = $desc_db{$id};
#    $desc = uncompress($compressed_data);
    $desc = $desc_db{$id};
  }
  foreach my $term (@terms) {
    my $bldterm = $term;
    $bldterm =~ s/([^\w\s])/\\$1/g;
    $bldterm = add_wildcard($bldterm) if ($bldterm =~ /\S\\\* / || $bldterm =~ /\S\\\*$/);
    $desc =~ s/\b($bldterm)\b/\n\t$1\n \t/gis;
  }
  $desc =~ s/\n\t/<B>/gs;
  $desc =~ s/\n \t/<\/B>/gs;
  return $desc;
}

# Get contexts for all the queried terms. Return "" if no context is found.
sub get_context {
  my $bdy = shift;
  my $all_terms = shift;
  my ($line, $pre, $post, $match, $prem, $postm);
  my @lines;
  my $count; 
  while ($count < $CONTEXT_EXAMPLES && $bdy =~ /$all_terms/gis) { 
    $count++; $pre = "$`"; $post = "$'"; $match = $&; 
    my $LENGTH = int ($CONTEXT_DESC_WORDS/2); 
    $pre =~ m/((?:\w+\W+){0,$LENGTH})$/gis; $prem = $1; 
    $post =~ m/^((?:\W+\w+){0,$LENGTH})/gis; $postm = $1; $bdy = "$'"; 
    $line = join("", '...', $prem, $match, $postm, '...'); 
    push @lines, $line; 
  } 
  return join("\n  \t", @lines);
}


sub add_wildcard {	# unescape * for wildcard
  my @termw = split ' ', $_[0];
  foreach (@termw) {
    $_ =~ s/^(\S+)\\\*$/$1\\S\*/g;
  }
  my $unescaped = join ' ', @termw;
  return $unescaped;
}

sub stem {
  my $str = $_[0];
  $str = substr $str, 0, $STEMCHARS if $STEMCHARS;
  return $str;
}

sub ceil {
  my $x = $_[0];
  my $y = $_[1];

  if ($x % $y == 0) {
    return $x / $y;
  } else {
    return int($x / $y + 1);
  }
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
  foreach my $doc_id (@{$ra}) {
    push @i, $doc_id if( $check{$doc_id} );
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
  foreach my $doc_id (@{$ra}) {
    push @i, $doc_id if( ! defined($check{$doc_id}) );
  }
  return @i;
}

# Return current date and time in ISO 8601 format, i.e. yyyy-mm-dd hh:mm:ss
sub get_iso_date {
  use Time::localtime;
  my $date = (localtime->year() + 1900).'-'.two_digit(localtime->mon() + 1).'-'.two_digit(localtime->mday());
  my $time = two_digit(localtime->hour()).':'.two_digit(localtime->min()).':'.two_digit(localtime->sec());
  return "$date $time";
}

# Returns "0x" for "x" if x is only one digit, otherwise it returns x unmodified.
sub two_digit {
  my $value = $_[0];
  $value = '0'.$value if( length($value) == 1 );
  return $value;  
}

# Escape some special characters in URLs. This function escapes each part
# of the path (i.e. parts delimited by "/") on its own.
sub my_uri_escape {
    my $str = shift;
    my @parts = split("(/)", $str);
    foreach my $part (@parts) {
      if( $part ne '/' ) {
        $part = CGI::escape($part);
      }
    }
    $str = join("", @parts);
    return $str;
}

# tools

# Remove some HTML special characters from a string. This is necessary
# to avoid cross site scripting attacks. 
# See http://www.cert.org/advisories/CA-2000-02.html
sub cleanup {
  my $str = $_[0];
  if( ! defined($str) ) {
    return "";
  }
  $str =~ s/[<>"'&]/ /igs;
  return $str;
}

sub isHTML {
  my $filename = shift;
  my $ext = get_suffix($filename);
  if( $ext ) {
    return grep(/^$ext$/i, @EXT);
  } else {
    return 0;
  }
}

sub get_suffix {
  my $filename = shift;
  ($suffix) = ($filename =~ m/\.([^.]*)$/);
  return $suffix;
}

sub debug {
	my $str = shift;
	if( $HTTP_DEBUG && $ENV{'REQUEST_METHOD'} ) {
		print $str;
	} elsif( $HTTP_DEBUG && ! $ENV{'REQUEST_METHOD'} ) {
		print STDERR $str;
	}
}

sub error {
	my $str = shift;
	if( $ENV{'REQUEST_METHOD'} ) {
		print $str;
	} else {
		print STDERR $str;
	}
}

# Load the user's list of (common) words that should not be indexed.
# Use a hash so lookup is faster. Well-chosen stopwords can make 
# indexing faster.
sub load_stopwords {
  my %stopwords;
  open(FILE, $STOPWORDS_FILE) or (warn "Cannot open '$STOPWORDS_FILE': $!" and return);
  while (<FILE>) {
    chomp;
    $_ =~ s/\r//g; # get rid of carriage returns
    $stopwords{$_} = 1;
  }
  close(FILE);
  return %stopwords;
}

my $special_chars;	# special characters we have to replace
# Build list of special characters that will be replaced in normalize(),
# put this list in global variable $special_chars.
sub build_char_string {
  foreach my $number (keys %entities) {
    $special_chars .= chr($number);
  }
}

# Represent all special characters as HTML entities like &<entitiy>;
sub normalize_special_chars {
  my $buffer = $_[0];
  # There may be special characters that are not encoded, so encode them:
# kishore - should remove following comment line and solve error
#   $buffer =~ s/([$special_chars])/"&#".ord($1).";"/gse;
  # Special characters can be encoded using hex values:
  $buffer =~ s/&#x([\dA-F]{2});/"&#".hex("0x".$1).";"/igse;
  # Special characters may be encoded with numbers, undo that (use the if() to avoid warnings):
  $buffer =~ s/&#(\d\d\d);/if( $1 >= 192 && $1 <= 255 ) { "&$entities{$1};"; }/gse;
  return $buffer;
}

%entities = (
	192 => 'Agrave',	#  capital A, grave accent 
	193 => 'Aacute',	#  capital A, acute accent 
	194 => 'Acirc',		#  capital A, circumflex accent 
	195 => 'Atilde',	#  capital A, tilde 
	196 => 'Auml',		#  capital A, dieresis or umlaut mark 
	197 => 'Aring',		#  capital A, ring 
	198 => 'AElig',		#  capital AE diphthong (ligature) 
	199 => 'Ccedil',	#  capital C, cedilla 
	200 => 'Egrave',	#  capital E, grave accent 
	201 => 'Eacute',	#  capital E, acute accent 
	202 => 'Ecirc',		#  capital E, circumflex accent 
	203 => 'Euml',		#  capital E, dieresis or umlaut mark 
	205 => 'Igrave',	#  capital I, grave accent 
	204 => 'Iacute',	#  capital I, acute accent 
	206 => 'Icirc',		#  capital I, circumflex accent 
	207 => 'Iuml',		#  capital I, dieresis or umlaut mark 
	208 => 'ETH',		#  capital Eth, Icelandic (Dstrok) 
	209 => 'Ntilde',	#  capital N, tilde 
	210 => 'Ograve',	#  capital O, grave accent 
	211 => 'Oacute',	#  capital O, acute accent 
	212 => 'Ocirc',		#  capital O, circumflex accent 
	213 => 'Otilde',	#  capital O, tilde 
	214 => 'Ouml',		#  capital O, dieresis or umlaut mark 
	216 => 'Oslash',	#  capital O, slash 
	217 => 'Ugrave',	#  capital U, grave accent 
	218 => 'Uacute',	#  capital U, acute accent 
	219 => 'Ucirc',		#  capital U, circumflex accent 
	220 => 'Uuml',		#  capital U, dieresis or umlaut mark 
	221 => 'Yacute',	#  capital Y, acute accent 
	222 => 'THORN',		#  capital THORN, Icelandic 
	223 => 'szlig',		#  small sharp s, German (sz ligature) 
	224 => 'agrave',	#  small a, grave accent 
	225 => 'aacute',	#  small a, acute accent 
	226 => 'acirc',		#  small a, circumflex accent 
	227 => 'atilde',	#  small a, tilde
	228 => 'auml',		#  small a, dieresis or umlaut mark 
	229 => 'aring',		#  small a, ring
	230 => 'aelig',		#  small ae diphthong (ligature) 
	231 => 'ccedil',	#  small c, cedilla 
	232 => 'egrave',	#  small e, grave accent 
	233 => 'eacute',	#  small e, acute accent 
	234 => 'ecirc',		#  small e, circumflex accent 
	235 => 'euml',		#  small e, dieresis or umlaut mark 
	236 => 'igrave',	#  small i, grave accent 
	237 => 'iacute',	#  small i, acute accent 
	238 => 'icirc',		#  small i, circumflex accent 
	239 => 'iuml',		#  small i, dieresis or umlaut mark 
	240 => 'eth',		#  small eth, Icelandic 
	241 => 'ntilde',	#  small n, tilde 
	242 => 'ograve',	#  small o, grave accent 
	243 => 'oacute',	#  small o, acute accent 
	244 => 'ocirc',		#  small o, circumflex accent 
	245 => 'otilde',	#  small o, tilde 
	246 => 'ouml',		#  small o, dieresis or umlaut mark 
	248 => 'oslash',	#  small o, slash 
	249 => 'ugrave',	#  small u, grave accent 
	250 => 'uacute',	#  small u, acute accent 
	251 => 'ucirc',		#  small u, circumflex accent 
	252 => 'uuml',		#  small u, dieresis or umlaut mark 
	253 => 'yacute',	#  small y, acute accent 
	254 => 'thorn',		#  small thorn, Icelandic 
	255 => 'yuml',		#  small y, dieresis or umlaut mark
);


# Shut up misguided -w warnings about "used only once". Has no functional meaning.
sub CGI_pl_sillyness {
  my $zz;
  $zz = $SPECIAL_CHARACTERS;
  $zz = $INDEX_NUMBERS;
  $zz = $CONTEXT_EXAMPLES;
  $zz = $CONTEXT_SIZE;
  $zz = $DATE_FORMAT;
  $zz = $MINLENGTH;
}
