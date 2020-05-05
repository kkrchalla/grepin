# Grepin Search and Services - Site Indexer
#$rcs = ' $Id: sub_indexer.pl,v 1.0 2004/05/01 00:00:00 Exp $ ' ;

# Grepin Search and Services
#
# Copyright (C) 2004 Grepin Search and Services <contact@grepin.com>
# 

  use Fcntl;
  use LWP::UserAgent;
  use URI;
  use Crypt::SSLeay;
#  use Compress::Zlib;

# declare global variables
  my ($INSTALL_DIR, $BASE_URL, $HTTP_START_URL, @HTTP_LIMIT_URLS, $HTTP_MAX_INDEX_PAGES);

#  my ($INDEX_STATUS, $MEMBER_STATUS, $HTTP_FOLLOW_COMMENT_LINKS, @HTTP_CONTENT_TYPES, %EXT_FILTER, @EXT, $CONTEXT_SIZE, $CONTEXT_EXAMPLES, $CONTEXT_DESC_WORDS, $DESC_WORDS, $MINLENGTH, $SPECIAL_CHARACTERS, $STEMCHARS, $IGNORE_TEXT_START, $IGNORE_TEXT_END, $MAX_TITLE_LENGTH, $NEXT_PAGE, $PREV_PAGE, $HTTP_MAX_PAGES, $INDEX_URLS, $INDEX_NUMBERS);

# indexer standard parameters - these parameters can be user configurable in future ##
  my $HTTP_FOLLOW_COMMENT_LINKS = 0;
  my @HTTP_CONTENT_TYPES = ('text/html', 'text/plain', 'application/pdf', 'application/msword');
  my %EXT_FILTER = (
	   "pdf" => "/usr/bin/pdftotext FILENAME -",
	   "doc" => "/usr/bin/antiword FILENAME",
	   "PDF" => "/usr/bin/pdftotext FILENAME -",
	   "DOC" => "/usr/bin/antiword FILENAME"
  );
  my @EXT = ("html", "HTML", "htm", "HTM", "shtml", "SHTML", "pdf", "PDF", "doc", "DOC");
  # Date format for the result page. %Y = year, %m = month, %d = day,
  # %H = hour, %M = minute, %S = second. On a Unix system use 
  # 'man strftime' to get a list of all possible options.
  my $CONTEXT_SIZE = 10000;
  my $CONTEXT_EXAMPLES = 3;
  my $CONTEXT_DESC_WORDS = 10;
  my $DESC_WORDS = 25;
  my $MINLENGTH = 3;
  my $SPECIAL_CHARACTERS = 1;
  my $STEMCHARS = 0;
  my $IGNORE_TEXT_START = '<!--ignore-grepin-start-->';
  my $IGNORE_TEXT_END = '<!--ignore-grepin-end-->';
  my $MAX_TITLE_LENGTH = 80;
  my $NEXT_PAGE = 'Next';
  my $PREV_PAGE = 'Prev';
  my $HTTP_MAX_PAGES = 5000;
  my $INDEX_URLS = 1;
  my $INDEX_NUMBERS = 1;

  my $ROBOT_AGENT = 'grepinbot';
  my $HTTP_DEBUG = 1;

  my $PERCENTAGE_RANKING = 1;
  my $TITLE_WEIGHT = 5;
  my $META_WEIGHT = 5;
  my %H_WEIGHT;
     $H_WEIGHT{'1'} = 5;	# headline <h1>...</h1>
     $H_WEIGHT{'2'} = 4;
     $H_WEIGHT{'3'} = 3;
     $H_WEIGHT{'4'} = 1;
     $H_WEIGHT{'5'} = 1;
     $H_WEIGHT{'6'} = 1;	# headline <h6>...</h6>

# indexer standard parameters - end ##

  my ($STOPWORDS_FILE, $DATA_DIR, $UPDATE_FILE, $INV_INDEX_DB_FILE, $DOCS_DB_FILE, $URLS_DB_FILE, $SIZES_DB_FILE, $TERMS_DB_FILE, $DF_DB_FILE, $TF_DB_FILE, $CONTENT_DB_FILE, $DESC_DB_FILE, $TITLES_DB_FILE, $DATES_DB_FILE);
  my ($INV_INDEX_TMP_DB_FILE, $DOCS_TMP_DB_FILE, $URLS_TMP_DB_FILE, $SIZES_TMP_DB_FILE, $TERMS_TMP_DB_FILE, $CONTENT_TMP_DB_FILE, $DESC_TMP_DB_FILE, $TITLES_TMP_DB_FILE, $DATES_TMP_DB_FILE);

#  my $to_be_compressed;
  my $special_chars;
  my ($indexlog_file, $logindex);
  my ($DN, $TN, $TN_non_unique, $no_index_count, $no_index_count_robot, $http_max_indexed_counter);

  # The data structures that Grepin Search uses to save information:
  my %inv_index_db;   # term id -> list of pairs: (document id, relevancy)
  my %docs_db;        # document id -> filename
  my %urls_db;        # filename -> 1 (for looking up if a filename/url was indexed)
  my %sizes_db;       # document id -> size in bytes
  my %desc_db;        # document id -> description (from meta tag or start of body)
  my %titles_db;      # document id -> document title
  my %dates_db;       # document id -> date of last modification
  my %content_db;     # document id -> start of the document's content (to show context of matches)
  my %terms_db;       # term -> term id
  # The following two hashes are temporary and will not be saved to disk:
  my %df_db;          # term id -> number of occurences of this term in all documents
  my %tf_db;          # term id -> list of pairs: (document id, number of occurences in this document)
  my %stopwords;
  my @no_index;

  my $md5;
  my $host;
  my $base;
  my %list;	# list of visited pages ($list{$digest} = $url)
  my $cloned_documents;
  my $ignored_documents;
  my $http_max_pages_counter = 0;

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
    log_error("subindexer1", "The DB_File module was not found.");
    exit;
  }


sub p_indexer {

  my $user_id = shift;
  my $USER_DIR_DIR = shift;

  $INSTALL_DIR = $USER_DIR_DIR.$user_id.'/search/';

  $host = "";
  $base = "";
  %list = undef;
  $special_chars = undef;
  $DN  	= 0;
  $TN  	= 0;
  $TN_non_unique  = 0;
  $no_index_count = 0;
  $no_index_count_robot = 0;
  $http_max_indexed_counter = 0;
  $MAIN_DIR = '/home/grepinco/public_html/cgi-bin/';


  BEGIN {
     eval {
                require Digest::MD5;
                import Digest::MD5;
                $md5 = new Digest::MD5;
     };
     if ($@) { # oops, no Digest::MD5
                require MD5;
                import MD5;
                $md5 = new MD5;
     }
  }


  $indexlog_file = $INSTALL_DIR.'/indexlog.txt';
  $logindex = 1;

  use Fcntl ':flock';        # import LOCK_* constants
  eval {
    open(INDEXLOG, ">$indexlog_file") or (die "Cannot open indexlogfile '$indexlog_file' for writing: $!");
    flock(INDEXLOG, LOCK_EX);
    seek(INDEXLOG, 0, 0);
    print INDEXLOG "Starting at ".time()."\n";
  };
  if ($@) {
    log_error("subindexer2", $@);
    $logindex = undef;
  }
print "<br>starting at ".time()."\n";

  my $USER_INDEX_DATA_DB_FILE    = $MAIN_DIR.'users/userindxdata';
  my %user_index_data;
  my ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10);

  eval {
    tie %user_index_data, "DB_File", $USER_INDEX_DATA_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_INDEX_DATA_DB_FILE: $!";   
    ($BASE_URL, $HTTP_START_URL, $HTTP_MAX_INDEX_PAGES, $db_limit_urls, $db_exclude_pages, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_index_data{$user_id});
    untie %user_index_data;
  };
  if ($@){
    log_error("subindexer3", $@);
print "<br>crawler error at tie USERINDEX DBFILE with reason $@\n";
    if ($logindex) {
      print INDEXLOG "Crawler error occured at the tie of userindexdbfile = $@\n";
    }
  }

print "<br /> baseurl = $BASE_URL \n";
print "<br> db_exclude = $db_exclude_pages \n";

  @HTTP_LIMIT_URLS = split /\s/, $db_limit_urls;
  push @HTTP_LIMIT_URLS, $BASE_URL;
# $db_exclude_pages = quotemeta;       # escape all non-alphanumeric characters
print "<br> db_exclude = $db_exclude_pages \n";
  $db_exclude_pages =~ s/\\\*/\.\*/g;  # except for the * which is replaced by .*
print "<br> db_exclude = $db_exclude_pages \n";
  @no_index = split /\s/, $db_exclude_pages;
print "<br> no_index = @no_index \n";

#  require $INSTALL_DIR.'/sub_userconf.pl';
#  ($INDEX_STATUS, $MEMBER_STATUS, $HTTP_FOLLOW_COMMENT_LINKS, @HTTP_CONTENT_TYPES, %EXT_FILTER, @EXT, $CONTEXT_SIZE, $CONTEXT_EXAMPLES, $CONTEXT_DESC_WORDS, $DESC_WORDS, $MINLENGTH, $SPECIAL_CHARACTERS, $STEMCHARS, $IGNORE_TEXT_START, $IGNORE_TEXT_END, $MAX_TITLE_LENGTH, $NEXT_PAGE, $PREV_PAGE, $HTTP_MAX_PAGES, $INDEX_URLS, $INDEX_NUMBERS) = v_userconf();

  $STOPWORDS_FILE    = $INSTALL_DIR.'/stopwords.txt';

  $DATA_DIR          = $INSTALL_DIR.'/data/';
  $UPDATE_FILE       = $DATA_DIR.'update';
  $INV_INDEX_DB_FILE = $DATA_DIR.'inv_index';
  $DOCS_DB_FILE      = $DATA_DIR.'docs';
  $URLS_DB_FILE      = $DATA_DIR.'urls';
  $SIZES_DB_FILE     = $DATA_DIR.'sizes';
  $TERMS_DB_FILE     = $DATA_DIR.'terms';
  $DF_DB_FILE        = $DATA_DIR.'df';
  $TF_DB_FILE        = $DATA_DIR.'tf';
  $CONTENT_DB_FILE   = $DATA_DIR.'content';
  $DESC_DB_FILE      = $DATA_DIR.'desc';
  $TITLES_DB_FILE    = $DATA_DIR.'titles';
  $DATES_DB_FILE     = $DATA_DIR.'dates';

  $INV_INDEX_TMP_DB_FILE = $DATA_DIR.'inv_index_tmp';
  $DOCS_TMP_DB_FILE      = $DATA_DIR.'docs_tmp';
  $URLS_TMP_DB_FILE      = $DATA_DIR.'urls_tmp';
  $SIZES_TMP_DB_FILE     = $DATA_DIR.'sizes_tmp';
  $TERMS_TMP_DB_FILE     = $DATA_DIR.'terms_tmp';
  $CONTENT_TMP_DB_FILE   = $DATA_DIR.'content_tmp';
  $DESC_TMP_DB_FILE      = $DATA_DIR.'desc_tmp';
  $TITLES_TMP_DB_FILE    = $DATA_DIR.'titles_tmp';
  $DATES_TMP_DB_FILE     = $DATA_DIR.'dates_tmp';


  $BASE_URL =~ s/\/$//;		# remove trailing slash
  $HTTP_START_URL =~ s/\/$//;	# remove trailing slash

  # Checking for old temp files...\n;
  delete_temp_files();

  eval {
    tie %inv_index_db, $db_package, $INV_INDEX_TMP_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $INV_INDEX_TMP_DB_FILE: $!";
    tie %docs_db,      $db_package, $DOCS_TMP_DB_FILE, O_CREAT|O_RDWR, 0755      or die "Cannot open $DOCS_TMP_DB_FILE: $!";
    tie %urls_db,      $db_package, $URLS_TMP_DB_FILE, O_CREAT|O_RDWR, 0755      or die "Cannot open $URLS_TMP_DB_FILE: $!";
    tie %sizes_db,     $db_package, $SIZES_TMP_DB_FILE, O_CREAT|O_RDWR, 0755     or die "Cannot open $SIZES_TMP_DB_FILE: $!";
    tie %desc_db,      $db_package, $DESC_TMP_DB_FILE, O_CREAT|O_RDWR, 0755      or die "Cannot open $DESC_TMP_DB_FILE: $!"; 
    tie %titles_db,    $db_package, $TITLES_TMP_DB_FILE, O_CREAT|O_RDWR, 0755    or die "Cannot open $TITLES_TMP_DB_FILE: $!";
    tie %dates_db,     $db_package, $DATES_TMP_DB_FILE, O_CREAT|O_RDWR, 0755     or die "Cannot open $DATES_TMP_DB_FILE: $!";
    tie %terms_db,     $db_package, $TERMS_TMP_DB_FILE, O_CREAT|O_RDWR, 0755     or die "Cannot open $TERMS_TMP_DB_FILE: $!"; 
    tie %df_db,        $db_package, $DF_DB_FILE, O_CREAT|O_RDWR, 0755            or die "Cannot open $DF_DB_FILE: $!";
    tie %tf_db,        $db_package, $TF_DB_FILE, O_CREAT|O_RDWR, 0755            or die "Cannot open $TF_DB_FILE: $!";
    tie %content_db,   $db_package, $CONTENT_TMP_DB_FILE, O_CREAT|O_RDWR, 0755   or die "Cannot open $CONTENT_TMP_DB_FILE: $!";
  };
  if ($@) {
    log_error("indexer", $@);
print "<br>crawler error at tie with reason $@\n";
    if ($logindex) {
    print INDEXLOG "Crawler error occured at the tie of dbfiles = $@\n";
    }
  }

  #Building string of special characters...
print "<br>building special characters\n";
  build_char_string();

  #Loading stopwords...
print "<br>loading stopwords\n";
  %stopwords = load_stopwords();

  # Starting crawler...
print "<br>starting crawler\n";
print "<br /> baseurl = $BASE_URL \n";
  $base_url = init_http();
  init_robot_check($base_url);
  crawl_http($HTTP_START_URL);

  # Calculating weight vectors...
print "<br>calculating weight vectors\n";
  weights();

  untie %content_db;
  untie %inv_index_db;
  untie %docs_db;
  untie %urls_db;
  untie %sizes_db;
  untie %desc_db;
  untie %titles_db;
  untie %dates_db;
  untie %terms_db;
  untie %df_db;
  untie %tf_db;
  # Removing unused db files
  unlink $TF_DB_FILE;
  unlink $DF_DB_FILE;

  # Renaming newly created db files...\n";
print "<br>renaming newly created db files\n";
  rename_db();

  if ($logindex) {
    print INDEXLOG "\nCrawler finished: indexed $DN files, ".($TN_non_unique+$TN)." terms ($TN different terms).\n";
    print INDEXLOG "Ignored $no_index_count files because of conf/no_index.txt\n";
    print INDEXLOG "Ignored $no_index_count_robot files because of robots.txt\n\n";
    print INDEXLOG "\nEnding at ".time()."\n";
    flock(INDEXLOG, LOCK_UN);
    close(INDEXLOG);
  }

print "<br>Crawler finished: indexed $DN files, ".($TN_non_unique+$TN)." terms ($TN different terms).\n";
print "<br>Ignored $no_index_count files because of conf/no_index.txt\n";
print "<br>Ignored $no_index_count_robot files because of robots.txt\n\n";
print "<br>Ending at ".time()."\n";

  return (0, $DN, $TN, $no_index_count, $no_index_count_robot);
}




############### indexer subroutines starts here ########################

# Sometimes people stop indexer.pl with Ctrl-C and temp files are left over.
# We better delete them so they don't confuse us.
sub delete_temp_files {
  my @tmp_files = ($INV_INDEX_TMP_DB_FILE,$DOCS_TMP_DB_FILE,$URLS_TMP_DB_FILE,$SIZES_TMP_DB_FILE,
    $TERMS_TMP_DB_FILE,$DESC_TMP_DB_FILE,$TITLES_TMP_DB_FILE,$CONTENT_TMP_DB_FILE);
  push(@tmp_files, $DF_DB_FILE,$TF_DB_FILE);
  foreach my $oldfile (@tmp_files) {
    next unless (-e $oldfile);
    if (!(unlink $oldfile)) {
      if ($logindex) {
        print INDEXLOG "Cannot unlink $oldfile: $!\n";
      }
    }
  }
}

# Save important parts of a file to the database.
sub index_file {
  my ($url, $doc_id, $filesize, $date, $buffer) = @_;
  my ($term, $term_id);
  my %tf;

  my $kb = sprintf("%.2f", $filesize / 1024);
  my $tempurl = $url;
  if( $ENV{'REQUEST_METHOD'} ) {
    $tempurl = html_escape($url);
  }
  debug("   $doc_id: $tempurl ($kb KB)\n"); 
  $http_max_indexed_counter++;
  $sizes_db{$doc_id} = $filesize;    # remember original document's size
  $date = -1 if( !$date );
  $dates_db{$doc_id} = $date;    # remember last modified date

  # Many auto-generated HTML files contain (correct) syntax that makes our
  # regexp very slow. So better clean up now:
  ${$buffer} =~ s/\s+>/>/gs;
  ${$buffer} =~ s/<\s+/</gs;

  record_desc($doc_id, $buffer, $url);
  if ($INDEX_URLS) {
    # to search for parts of URLs, e.g. filenames:
    ${$buffer} = $url." ".${$buffer};
  }
  # to rank words in the title tag and in headlines differently:
  get_tag_contents("title", $buffer, $TITLE_WEIGHT);
  get_headline_contents($buffer);
  # to search for text in the follwing meta tags:
  ${$buffer} .= " ".get_meta_content("description", $buffer, $META_WEIGHT);
  ${$buffer} .= " ".get_meta_content("keywords", $buffer, $META_WEIGHT);
  ${$buffer} .= " ".get_meta_content("author", $buffer, $META_WEIGHT);
  # to search for images' alt texts:
  get_alt_texts($buffer);
  normalize($buffer);
  
  foreach (split " ", ${$buffer}) {
    next if( $stopwords{$_} );    # ignore stopwords
    $_ = substr $_, 0, $STEMCHARS if $STEMCHARS;
    if (length $_ >= $MINLENGTH) {
      $term_id = record_term($_);
      ++$tf{$term_id};
    }
  }
  
  foreach (keys %tf) {
    $df_db{$_}++;
    $tf_db{$_} = '' unless defined $tf_db{$_};
    $tf_db{$_} .= pack("ww", $doc_id, $tf{$_}); 
  }
}

# Calculate the weight (score) for each term in each file and 
# save it to the database.
sub weights {
  my ($weight, $term_id, $doc_id);

  foreach $term_id (keys %tf_db) {
    my $weights = $inv_index_db{$term_id} || '';
    my $df = $df_db{$term_id};
    my %tdf = unpack("w*",$tf_db{$term_id}); 
    foreach $doc_id (keys %tdf) {
      #print "weight = $tdf{$doc_id} * log ($DN / $df)\n";
      if($DN == $df){
	  $df = $df - 1
      }
      if($df == 0){
        $weight = 65535
      } else {
        $weight = $tdf{$doc_id} * log ($DN / $df);
        $weight = int($weight*100);
        $weight = 65535 if ( $weight > 65535 );    # we're limited to 16 bit
      }
      $weights .= pack("SS", $doc_id, $weight);
    }
    undef %tdf;
    $inv_index_db{$term_id} = $weights;
  }
}

# Replace umlauts etc by ASCII characters, remove HTML, 
# remove remaining special charcaters. In the end, we only have [a-zA-Z0-9_].
# Then it is converted to lowercase and returned.
sub normalize {
  my $buffer = $_[0];

  if( $IGNORE_TEXT_START && $IGNORE_TEXT_END ) {  # strip user defined parts
    ${$buffer} =~ s/$IGNORE_TEXT_START.*?$IGNORE_TEXT_END//gis;
  }
  ${$buffer} =~ s/<!--.*?-->//gis;  # strip html comments
  ${$buffer} =~ s/-(\s*\n\s*)?//g;  # join parts of hyphenated words

  if( $SPECIAL_CHARACTERS ) {
    ${$buffer} = normalize_special_chars(${$buffer});
    ${$buffer} = remove_accents(${$buffer});
  }

  # Replace HTML tags (and maybe numbers) by spaces:
  if ($INDEX_NUMBERS) {
    ${$buffer} =~ s/(<[^>]*>)/ /gs;
  } else {
    ${$buffer} =~ s/(\b\d+\b)|(<[^>]*>)/ /gs;
  }

  ${$buffer} =~ tr/a-zA-Z0-9_/ /cs;
  ${$buffer} = lc ${$buffer};
}

# Return the body without HTML and unnecessary whitespace.
sub get_cleaned_body {
  my $buffer = $_[0];
  my $filename = $_[1];
  my $cleaned = "";
  if( isHTML($filename) ) {
    ($cleaned) = (${$buffer} =~ m/<BODY.*?>(.*)<\/BODY>/is);
    $cleaned = ${$buffer} if( ! $cleaned );    # broken HTML files maybe don't have a <body>
  } else {
    # non HTML files don't have a "body" (e.g. PDF)
    $cleaned = ${$buffer};
  }
  $cleaned =~ s/$IGNORE_TEXT_START.*?$IGNORE_TEXT_END//gis;  # strip user defined parts
  $cleaned =~ s/<!--.*?-->//gis;        # strip html comments
  $cleaned =~ s/<.+?>/ /gis;            # strip html
  $cleaned =~ s/\s+/ /gis;              # strip too much whitespace
  $cleaned =~ tr/\n\r/ /s;
  # comment out the following line if you want to index Arabic (and other non-Latin1 charstets?):
  $cleaned = normalize_special_chars($cleaned);
  return $cleaned;
}

# Save the (document ID, filename) relation to the database.
sub record_file {
  my $file = $_[0];
  ++$DN;
  # for development only:
  #if( $DN % 100 == 0 ) {
  #  memory_usage();
  #}
  if( $DN >= 65535 ) {
    if ($logindex) {
      print INDEXLOG "Error: Indexing more than 65534 documents is not supported";
    }
    return; # kishore
  }
  $docs_db{$DN} = $file;
  $urls_db{$file} = 1;
  return $DN;
}

# Save a short description for every document to the database. If no 
# meta description tag is available, take the first words from the body.
# Also save the <title> to the database.
sub record_desc {
  my ($doc_id, $buffer, $file) = @_;
  my ($desc, $title, $cleanbody);
  my @desc_ary;

  # Save Description or beginning of body:
  $desc = get_meta_content("description", $buffer, 1);
  if( ! $desc || $CONTEXT_SIZE ) {
    $cleanbody = get_cleaned_body($buffer, $file);
  }
  unless ($desc) {
    @desc_ary = split " ", $cleanbody;
    my $to = $DESC_WORDS;
    $to = scalar(@desc_ary)-1 if( $DESC_WORDS >= scalar(@desc_ary) );
    $desc = join " ", @desc_ary[0..$to];
    $desc .= "..." if( $desc !~ m/\.\s*$/ );
  }
#  $to_be_compressed = undef;
#  $to_be_compressed = removeHTML($desc);
#  $desc_db{$doc_id} = compress($to_be_compressed);
  $desc_db{$doc_id} = removeHTML($desc);

  # Save title:
  ($title) = (${$buffer} =~ m/<TITLE>(.*?)<\/TITLE>/is);
  if( (! $title) || $title =~ m/^\s+$/ ) {
    $file =~ s/.*\///;    # remove the path
    $title = $file;
  }
  if( (! $title) || $title =~ m/^\s+$/ ) {
    $title = removeHTML($desc);
  }
  if( length($title) > $MAX_TITLE_LENGTH ) {
    $title = substr($title, 0, $MAX_TITLE_LENGTH) . "...";
  }
  $titles_db{$doc_id} = removeHTML($title);

  # Optionally save the document (to show results with context):
  if( $CONTEXT_SIZE ) {
    my $cont = $cleanbody;
    $cont = substr($cont, 0, $CONTEXT_SIZE) if( $CONTEXT_SIZE != -1 );
#    $to_be_compressed = undef;
#    $to_be_compressed = removeHTML($cont);
#    $content_db{$doc_id} = compress($to_be_compressed);
    $content_db{$doc_id} = removeHTML($cont);
  }
}

# Get the content part for a certain meta tag. Weight with
# a certain factor by just repeating the result that often.
sub get_meta_content {
  my $name = $_[0];
  my $buffer = $_[1];
  my $weight = $_[2];
  my ($content) = (${$buffer} =~ m/<META\s+name\s*=\s*[\"\']?$name[\"\']?\s+content=[\"\'](.*?)[\"\'][\/\s]*>/is);
  return "" if( ! $content || $content =~ m/^\s+$/ );
  $content = (($content." ") x $weight);
  return $content;  
}

# Add all values for alt="...", joined with spaces to $buffer.
sub get_alt_texts {
  my $buffer = $_[0];
  my $alt_texts = "";
  while( ${$buffer} =~ m/alt\s*=\s*[\"\'](.*?)[\"\']/gis ) {
    $alt_texts .= " ".$1;
  }
  ${$buffer} .= $alt_texts;
}

# Add the contents of a certain tag, weighted by just repeating these contents
# to $buffer.
sub get_tag_contents {
  my $tag = $_[0];
  my $buffer = $_[1];
  my $weight = $_[2];
  my $tag_content = "";
  while( ${$buffer} =~ m/<$tag.*?>(.*?)<\/$tag>/igs ) {
    $tag_content .= (" ".$1) x $weight;
  }
  ${$buffer} .= $tag_content;
}

# Add the contents of all headline levels, weighted by just repeating these contents
# to $buffer.
sub get_headline_contents {
  my $buffer = $_[0];
  my $level;
  my $headlines = "";
  for( $level = 1; $level <= 6; $level++ ) {
    while( ${$buffer} =~ m/<h$level.*?>(.*?)<\/h$level>/igs ) {
      $headlines .= (" ".$1) x $H_WEIGHT{$level};
    }
  }
  ${$buffer} .= $headlines;
}

# Save a term's ID to the database, if it does not yet exist. Return the ID.
sub record_term {
  my $term = $_[0];
  my $lookup = $terms_db{$term};
  if ($lookup) {
    $TN_non_unique++;
    return $lookup;
  } else {
    $TN++;
    $terms_db{$term} = $TN;
    return $TN;
  }
}

# Is the file listed in @no_index?
# Supported ways to list a file in conf/no_index:
# /test/index.html 
# /test/
# http://localhost/test/index.html
sub to_be_ignored {
  my $file = shift;
  # Check @no_index:
  foreach my $regexp (@no_index) {
    if( $file =~ m/$regexp/) {
      $no_index_count++;
      return "listed in exclude-pages";
    }
  }
  if( $ROBOT_AGENT ) {
    if( ! $main::robot->allowed($file) ) {
      $no_index_count_robot++;
      return "disallowed by robots.txt";
    }
  }
  return undef;
}

# Move the temporary files to their non-temporary places. This is
# called when the new index is complete. This way the old index 
# files can still be used while the new ones are being created.
sub rename_db {
  my @files = (
    [$TERMS_TMP_DB_FILE, $TERMS_DB_FILE],
    [$DOCS_TMP_DB_FILE, $DOCS_DB_FILE],
    [$URLS_TMP_DB_FILE, $URLS_DB_FILE],
    [$SIZES_TMP_DB_FILE, $SIZES_DB_FILE],
    [$TITLES_TMP_DB_FILE, $TITLES_DB_FILE],
    [$DATES_TMP_DB_FILE, $DATES_DB_FILE],
    [$CONTENT_TMP_DB_FILE, $CONTENT_DB_FILE],
    [$DESC_TMP_DB_FILE, $DESC_DB_FILE],
    [$INV_INDEX_TMP_DB_FILE, $INV_INDEX_DB_FILE],
  );

  foreach (@files) {
    rename $_->[0], $_->[1] or (print INDEXLOG "Cannot rename $_->[0]: $!" and next);
  }
}

# Remove HTML from a string.
sub removeHTML {
  my $str = $_[0];
  $str =~ s/<!--.*?-->//igs;
  $str =~ s/<.*?>//igs;
  $str =~ s/[<>]//igs;    # these may be left
  $str =~ s/&nbsp;/ /igs;
  $str =~ s/&quot;/"/igs;
  $str =~ s/&apos;/'/igs;
  $str =~ s/&gt;/>/igs;
  $str =~ s/&lt;/</igs;
  $str =~ s/&copy;/(c)/igs;
  $str =~ s/&trade;/(tm)/igs;
  $str =~ s/&#8220;/"/igs;
  $str =~ s/&#8221;/"/igs;
  $str =~ s/&#8211;/-/igs;
  $str =~ s/&#8217;/'/igs;
  $str =~ s/&#38;/&/igs;
  $str =~ s/&#169;/(c)/igs;
  $str =~ s/&#8482;/(tm)/igs;
  $str =~ s/&#151;/--/igs;
  $str =~ s/&#147;/"/igs;
  $str =~ s/&#148;/"/igs;
  $str =~ s/&#149;/*/igs;
  $str =~ s/&reg;/(R)/igs;
  $str =~ s/&amp;/&/igs;

  return $str;
}

# For development only: check memory usage during indexing.
sub memory_usage {
  my $pid = $$;
  my $str = `top -b -n 0 -p $pid`;
  my ($line) = ($str =~ m/^(.*?grepinbot\.*?)$/igm);
  $line =~ s/^\s+//;
  my @line = split(/\s+/, $line);
  print INDEXLOG "mem: $line[4]\n";
}

# indexer_web

## Get the host and base part of $BASE_URL
sub init_http {
print "<br /> baseurl = $BASE_URL \n";
	my $uri = new URI($BASE_URL);
	$host = $uri->host;
	$base = $uri->scheme.":".$uri->opaque;
	$cloned_documents = 0;
	$ignored_documents = 0;
	return $uri->scheme."://".$uri->host;
}

## Fetch $url and all URLs that this document links to. Remember
## visited documents and their checksums in %list
sub crawl_http {
	my $url = shift;
	my $date = "";
	my $filesize = 0;
	my $original_url = $url;

	# fetch URL via http, if not yet visited:
	foreach my $visited_url (values %list) {
		if( $url eq $visited_url ) {
			debug("Ignoring '$url': already visited\n"); 
			return;
		}
	}
	if( ! check_accept_url($url) ) {
		$list{'ign_'.$ignored_documents} = $url;
		$ignored_documents++;
		return;
	}
	my $content;
	my $gu_url = $url;
	my $http_user_agent = LWP::UserAgent->new;
	($url, $date, $filesize, $content) = get_url($http_user_agent, $gu_url);
	return if( ! $url );
      if ($gu_url ne $url) {
	  foreach my $visited_url (values %list) {
		if( $url eq $visited_url ) {
			debug("Ignoring '$url': already visited\n"); 
			return;
		}
        }
      }

	my $ext = get_suffix($url);
	if( $ext && $EXT_FILTER{$ext} ) {
		my $tmpfile = "${TMP_DIR}tempfile";
		open(TMPFILE, ">$tmpfile") or (warn "Cannot write '$tmpfile': $!" and return);
		binmode(TMPFILE);
		print TMPFILE $content;
		close(TMPFILE);
		$content = filterFile($tmpfile, $ext);
		unlink $tmpfile or warn "Cannot remove '$tmpfile: $!'"
	}

	# Calculate checksum of content:
	$md5->reset();
	$md5->add($content);
	my $digest = $md5->hexdigest();
	# URL with the same content already visited?:
	if( $list{$digest} ) {
		debug("Ignoring '$url': content identical to '$list{$digest}'\n"); 
		$list{'clone_'.$cloned_documents} = $original_url;
		$cloned_documents++;
		return;
	}
	# return if content could not be fetched, but before remember digest and URL:
	$list{$digest} = $url;
	return if( ! $url );
	# Check for meta tags against robots
	my $meta_tags = robot_meta_tag(\$content);
	if( $meta_tags eq "none" ) {	# indexing and following are forbidden by meta tags
		debug("Ignoring '$url': META tags forbid indexing and following\n"); 
		return;
	} 
	my $content_tmp = $content; 	# content might be modified below
	if( $meta_tags eq "noindex" ) {	# indexing this file is forbidden by meta tags
		debug("'$url': META tags forbid indexing\n"); 
	} else {
		# call the index functions:
		my $doc_id = record_file($url);
		index_file($url, $doc_id, $filesize, $date, \$content);
	}
	if( $meta_tags eq "nofollow" ) {	# following is forbidden by meta tags
		debug("'$url': META tags forbid following\n"); 
		return;
	} 
	if( !$HTTP_FOLLOW_COMMENT_LINKS ) {
		# remove all HTML comments
		$content_tmp =~ s#<!--.*?-->##igs;
	}
	# 'parse' HTML for new URLs (Meta-Redirects and Anchors):
	while( $content_tmp =~ m/
			content\s*=\s*["'][0-9]+;\s*URL\s*=\s*(.*?)['"]
			|
			href\s*=\s*["'](.*?)['"]
			|
			frame[^>]+src\s*=\s*["'](.*?)['"]
			/gisx ) {
		my $new_url = $+;
		# &amp; in a link to distinguish arguments is actually correct, but we have to
		# convert it to fetch the file:
		$new_url =~ s/&amp;/&/g;
		my $next_url = next_url($url, $new_url);
		if ( $next_url && ($http_max_indexed_counter < $HTTP_MAX_INDEX_PAGES)) {
			crawl_http($next_url);
		}
	}

}

## Return an absolute version of the $new_url, which is relative
## to $url.
sub next_url {
	my $base_url = shift;
	my $new_url = shift;
	# a hack by Daniel Quappe to work around some strange bug in the URI module:
	$new_url =~ s/^javascript:/mailto:/igs;
	my $new_uri = URI->new_abs($new_url, $base_url);
	# get rid of "#fragment":
	$new_uri = URI->new($new_uri->scheme.":".$new_uri->opaque);
	# get the right URL even if the link has too many "../":
	my $path = $new_uri->path;
	$path =~ s/\.\.\///g;
	$new_uri->path($path);
	$new_url = $new_uri->as_string;
	return $new_url;
}

## Check if URL is accepted, return 1 if yes, 0 otherwise
sub check_accept_url {
	my $url = shift;
	my $reject;
	# ignore "empty" links (shouldn't happen):
	if( ! $url || $url eq '' ) {
		$reject = "empty/undefined URL";
	}
	# ignore foreign servers/URLs and non-http protocols:
	my $server_okay = 0;
	foreach my $allowed_url (@HTTP_LIMIT_URLS) {
		if( $url =~ m/:\/\// && $url =~ m/^$allowed_url/i ) {
			$server_okay = 1;
			last;
		}
	}
	if( !$server_okay ) {
		$reject = "not below LIMIT_URLS or non-http protocol";
	}
	# ignore file links:
	if( $url =~ m/^file:/i ) {
		$reject = "file URL";
	}
	# ignore javascript: and mailto: links:
	if( $url =~ m/^mailto:/i ) {        # javascript: was replaced by mailto: already
		$reject = "mailto or javascript link";
	}
	# ignore document internal links:
	if( $url =~ m/^#/i ) {
		$reject = "local link";
	}
	if( !$reject ) {
		my $ignore_reason = to_be_ignored($url);
		if( $ignore_reason ) {
			$reject = $ignore_reason;
		}
	}
	if( $reject ) {
		debug("Ignoring '$url': $reject\n"); 
		return 0;
	}
	return 1;
}

# tools

# Escape some HTML special characters in a string. This is necessary
# to avoid cross site scripting attacks. 
# See http://www.cert.org/advisories/CA-2000-02.html
sub html_escape {
  my $str = $_[0];
  if( ! defined($str) ) {
    return "";
  }
  $str =~ s/&/&amp;/igs;
  $str =~ s/</&lt;/igs;
  $str =~ s/>/&gt;/igs;
  $str =~ s/"/&quot;/igs;
  $str =~ s/'/&apos;/igs;
  return $str;
}


sub init_robot_check {
	my $base = shift;
	if( $ROBOT_AGENT ) {
		eval "use WWW::RobotRules";
		if( $@ ) {
			die("Cannot use robots.txt, maybe WWW::RobotRules is not installed? $!");
		}
		$main::robot = WWW::RobotRules->new($ROBOT_AGENT);
		my $url = "$base/robots.txt";
            if ($logindex) {
		  print INDEXLOG "Loading $url...\n";
            }
		my $http_user_agent_irc = LWP::UserAgent->new;
		my $robots_txt;
		(undef, undef, undef, $robots_txt) = get_url($http_user_agent_irc, $url);
		if( $robots_txt ) {
			$main::robot->parse($url, $robots_txt);
		} else {
			warn("Not using any robots.txt.\n");
		}
	}
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

sub filterFile {
  my $filename = shift;
  my $ext = shift;
  my $buffer;
  my @args = split(/\s+/, $EXT_FILTER{$ext});
  # don't allow any filename for security reasons:
  if( $filename !~ m/^[\/a-zA-Z0-9_.: +-]*$/ || $filename =~ m/\.\./ ) {
    if ($logindex) {
      print INDEXLOG "Ignoring '$filename': illegal characters in filename\n";
    }
    return "";
  }
  foreach (@args) {
    if( $_ eq 'FILENAME' ) {
      $_ =~ s/FILENAME/"$filename"/g;
    }
  }
  my $command = join(' ', @args);
  open(CMD, "$command|") || warn("Cannot execute '$command': $!") && return "";
  while( <CMD> ) {
    $buffer .= $_;
  }
  close(CMD);
  return $buffer;
}

sub debug {
	my $str = shift;
      if ($logindex) {
	  print INDEXLOG $str;
      }
}

sub error {
	my $str = shift;
      if ($logindex) {
	  print INDEXLOG $str;
      }
}

# Fetch URL via http, return real URL (differs only in case of redirect) and
# document's contents. Return nothing in case of error or unwanted Content-Type
sub get_url {
  my $http_user_agent_gu = shift;
  my $url = shift;
  my $search_mode = shift;		# $search_mode = don't show debugging

  # Do not index more than the $HTTP_MAX_INDEX_PAGES pages:
  if( $http_max_indexed_counter >= $HTTP_MAX_INDEX_PAGES ) {
    error("Error: Ignoring '$url': $HTTP_MAX_INDEX_PAGES indexed pages limit reached.\n");
    return;
  }

  # Avoid endless loops:
  if( $http_max_pages_counter >= $HTTP_MAX_PAGES ) {
         error("Error: Ignoring '$url': \$HTTP_MAX_PAGES=$HTTP_MAX_PAGES limit reached.\n");
         return;
  }

  $http_max_pages_counter++;

  my $request = HTTP::Request->new(GET => $url);
  my $response = $http_user_agent_gu->request($request);
  if( $response->is_error ) {
    error("Error: Couldn't get '$url': response code " .$response->code. "\n");
    return;
  }

  if( $response->headers_as_string =~ m/^Content-Type:\s*(.+)$/im ) {
    my $content_type = $1;
    $content_type =~ s/^(.*?);.*$/$1/;		# ignore possible charset value
    if( ! grep(/^$content_type$/i, @HTTP_CONTENT_TYPES) ) {
      debug("Ignoring '$url': content-type '$content_type'\n");
      return;
    }
  }

  my $buffer = $response->content;
  my $size = length($buffer);
  debug("\nFetched  '$url', $size bytes\n") if( ! $search_mode );
  # Maybe we are we redirected, so use the new URL.
  # Note: this also uses <base href="...">, so href="..." has to point
  # to the page itself, not to the directory (even though the latter 
  # will work okay in browsers):
  $url = $response->base;
  return ($url, $response->last_modified, $size, $buffer);
}

## Are there meta tags that forbid visiting this page /
## following its URLs? Returns "", "none", "noindex" or "nofollow"
sub robot_meta_tag {
  my $content = shift;
  my $meta_tags = "";
  while( ${$content} =~ m/<meta(.*?)>/igs ) {
    my $tag = $1;
    if( $tag =~ m/name\s*=\s*"robots"/is ) {
      my ($value) = ($tag =~ m/content\s*=\s*"(.*?)"/igs);
      if( $value =~ m/none/is ) {
        $meta_tags = "none";
      } elsif( $value =~ m/noindex/is && $value =~ m/nofollow/is ) {
        $meta_tags = "none";
      } elsif( $value =~ m/noindex/is ) {
        $meta_tags = "noindex";
      } elsif( $value =~ m/nofollow/is ) {
        $meta_tags = "nofollow";
      }
    }
  }
  return $meta_tags;
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

# Build list of special characters that will be replaced in normalize(),
# put this list in global variable $special_chars.
sub build_char_string {
  foreach my $number (keys %entities) {
    $special_chars .= chr($number);
  }
}

# Represent all special characters as the character they are based on.
sub remove_accents {
  my $buffer = $_[0];
  # Special cases:
  $buffer =~ s/&thorn;/th/igs;
  $buffer =~ s/&eth;/d/igs;
  $buffer =~ s/&szlig;/ss/igs;
  # Now represent special characters as the characters they are based on:
  $buffer =~ s/&(..?)(grave|acute|circ|tilde|uml|ring|cedil|slash|lig);/$1/igs;
  return $buffer;
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

my %entities = (
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
sub warnings_sillyness {
  my $zz;
  $zz = $SIZES_DB_FILE;
  $zz = $TITLE_WEIGHT;
  $zz = $SPECIAL_CHARACTERS;
  $zz = $H_WEIGHT;
  $zz = $INDEX_URLS;
  $zz = $DESC_WORDS;
  $zz = $INV_INDEX_DB_FILE;
  $zz = $MINLENGTH;
  $zz = $DESC_DB_FILE;
  $zz = $TITLES_DB_FILE;
  $zz = $DATES_DB_FILE;
  $zz = $TERMS_DB_FILE;
  $zz = $DOCS_DB_FILE;
  $zz = $URLS_DB_FILE;
  $zz = $CONTENT_DB_FILE;
  $zz = $INDEX_NUMBERS;
  $zz = $VERSION;
  $zz = $ROBOT_AGENT;
  $zz = $main::robot;
  $zz = $HTTP_LIMIT_URLS;
  $zz = $HTTP_CONTENT_TYPES;
}


1;