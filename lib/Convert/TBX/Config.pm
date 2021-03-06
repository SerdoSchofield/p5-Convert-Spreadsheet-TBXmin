#!usr/bin/perl

package Convert::Spreadsheet::Min::Config;
use strict;
use warnings;
use Path::Tiny;
use Exporter::Easy (
	OK => [ 'config_spreadsheet' ]
	);
use Spreadsheet::Read qw(ReadData rows);
use Encode qw(decode);
#use utf8;
use open ':encoding(utf-8)', ':std';

# report parsing errors from TBX::Min in the caller's namespace,
# not ours
our @CARP_NOT = __PACKAGE__;

# VERSION

# ABSTRACT: Configure Spreadsheet to be Converted to TBX-Min
=head1 DESCRIPTION

This module provides a simple command line based UI for pre-configuring
a spreadsheet to be converted by Convert::Spreadsheet::Min.
Alternatively, an external UI may be used by
calling L<Convert::Spreadsheet::Min::Config/config_spreadsheet
and passing in

=cut

=head1 FUNCTIONS

=head2 C<min2basic>

Converts TBX-Min data into TBX-Basic data. The input may be either
a TBX::Min object or data to be passed to TBX::Min's
L<TBX::Min/new_from_xml> constructor. The return value is a scalar
ref containing the TBX-Basic XML document as a UTF-8-encoded string.

=cut

# This is intended to work with the webapp at tbxconvert.gevterm.net/tbx-min.  It will not do much of anything without the PHP end.  
# The config_spreadsheet_terminal function below will allow for configuration via terminal
sub config_spreadsheet {
	my ($fh, $fhout, $data);
	my ($input, $source_lang, $target_lang, $timestamp, $license, $creator, $description, $directionality, $subject, $d_id, $realFileName) = @_;

	if ($realFileName =~ /\.xlsx/ || $input =~ /\.xlsx/)
	{
		$data = ReadData($input, parser => 'xlsx')
		or die "couldn't read '.xlsx' spreadsheet; check file extension or try another format?";
	}
	elsif ($realFileName =~ /\.xls/ || $input =~ /\.xls/)
	{
		$data = ReadData($input, parser=> 'xls')
		or die "couldn't read '.xls' spreadsheet; check file extension or try another format?";
	}
	elsif ($realFileName =~ /\.csv|\.utx|\.txt/ || $input =~ /\.csv|\.utx|\.txt/)
	{
		$data = ReadData($input, parser=> 'csv')
		or die "couldn't read 'csv' spreadsheet; check file extension or try another format?";
	}
	elsif ($realFileName =~ /\.ods|\.oo/ || $input =~ /\.ods|\.oo/)
	{
		$data = ReadData($input, parser=>'ods') or $data = undef;
		if (!defined ($data))
		{
			$data = ReadData($input, parser=>'oo') or $data = undef;
			if (!defined ($data))
			{
				$data = ReadData($input, parser=>'openoffice') or $data = undef;
				if (!defined ($data))
				{
					$data = ReadData($input, parser=>'libreoffice') or die "Still cannot parse the given spreadsheet;  Check file extension or try another format?";
				}
			}
		}
	}
	else
	{
		$data = ReadData($input) or
		die "couldn't read spreadsheet; check file extension or try another format?";
	}
	
	my @rows = rows ($data->[1]);
	
	my $header_found = 0;
	
	foreach my $row_array (@rows) 
	{
		my @row = @$row_array;
		my $x;
		foreach $_ (@row)
		{
			$x++;
			$_ = decode 'utf8', $_;
			s/\x{00}//g;
			s/\s+/ /g;
			if (!defined $_ || /^\s+[\r\n]*$/ || /^\s*\b[a-z]\b\s*[\r\n]*$/i){
				$row[$x-1] = "(>^_^)>";
				next;
			}
			$_ .= "(>^_^)>";  #this will be used in place of \t delimiter for storage
		}
		
		$fhout .= "@row<(^_^)>";
	}
	print $fhout;
}

sub config_spreadsheet_terminal {
	my ($fh, $fhout, $data);
	my ($input, $source_lang, $target_lang, $timestamp, $license, $creator, $description, $directionality, $subject, $d_id, $realFileName) = @_;
	
#	$fh = _get_handle($input);
	open $fhout, ">", "$input.configured.txt";
	
	if ($realFileName =~ /\.xlsx/ || $input =~ /\.xlsx/)
	{
		$data = ReadData($input, parser => 'xlsx') #, parser => 'csv')
        	# or die "couldn't read spreadsheet; check file extension?";
		# or $data = ReadData($input, parser=> 'xls')
		# or $data = ReadData($input, parser=> 'csv')
		or die "couldn't read '.xlsx' spreadsheet; check file extension or try another format?";
	}
	elsif ($realFileName =~ /\.xls/ || $input =~ /\.xls/)
	{
		$data = ReadData($input, parser=> 'xls')
		or die "couldn't read '.xls' spreadsheet; check file extension or try another format?";
	}
	elsif ($realFileName =~ /\.csv|\.utx/ || $input =~ /\.csv|\.utx/)
	{
		$data = ReadData($input, parser=> 'csv')
		or die "couldn't read 'csv' spreadsheet; check file extension or try another format?";
	}
	elsif ($realFileName =~ /\.ods|\.oo/ || $input =~ /\.ods|\.oo/)
	{
		$data = ReadData($input, parser=>'ods') or $data = undef;
		if (!defined ($data))
		{
			$data = ReadData($input, parser=>'oo') or $data = undef;
			if (!defined ($data))
			{
				$data = ReadData($input, parser=>'openoffice') or $data = undef;
				if (!defined ($data))
				{
					$data = ReadData($input, parser=>'libreoffice') or die "Still cannot parse the given spreadsheet;  Check file extension or try another format?";
				}
			}
		}
	}
	else
	{
		$data = ReadData($input) or
		die "couldn't read spreadsheet; check file extension or try another format?";
	}
	
	my @rows = rows ($data->[1]);
	
	print $fhout ("source_lang: ".$source_lang) if (defined $source_lang && $source_lang ne "\n");
	print $fhout ("target_lang: ".$target_lang) if (defined $target_lang && $target_lang ne "\n");
	print $fhout ("timestamp: ".$timestamp) if (defined $timestamp && $timestamp ne "\n");
	print $fhout ("creator: ".$creator) if (defined $creator && $creator ne "\n");
	print $fhout ("license: ".$license) if (defined $license && $license ne "\n");
	print $fhout ("description: ".$description) if (defined $description && $description ne "\n");
	print $fhout ($directionality) if (defined $directionality && $directionality ne "\n");
	print $fhout ("subject: ".$subject) if (defined $subject && $subject ne "\n");
	print $fhout ("dict_id: ".$d_id) if (defined $d_id && $d_id ne "\n");
	
	my $header_found = 0;
	foreach my $row_array (@rows) {
		my @row = @$row_array;

		foreach $_ (@row){
			my $char = $_;
			my $result = eval { $char = decode 'utf-8', $_; };
			unless ($result) {
				print "Trying 'Latin 1' because Decode 'UTF-8' failed with: $@";
				
				my $result = eval { $char = decode 'Latin1', $_; };
				unless($result) {
					 print "Decode 'Latin 1' failed with: $@"
  			    }
            }
			$_ = $char;
			$_ = "\t" if (defined $_ == 0)
		}
		if (@row > 1 && $header_found == 0) {
			print "Is this the row that contains column headers? \n\n@row\n\nY/N: ";
				my $yes_or_no = <STDIN>;
			if ($yes_or_no =~ /yes|y/i) { 
				$header_found = 1
			} else { next };
			
			my @original_row = @row;
			
			my $col_num;
			while (1) {
			print "\nWhich column represents TERMS from the SOURCE language? (1,2,3,4,etc. | '0' or RETURN/ENTER if none): ";
				$col_num = <STDIN>;
				if ($col_num !~ /[0-9]/){
					print "\nNumerals only please!!\n\n";
					redo;
				} else { 
					$row[($col_num - 1)] = "src_term" if ($col_num =~ /[1-9]/);
					last;
				}
			}
			
			while (1) {
			print "TARGET language: ";
				$col_num = <STDIN>;
				if ($col_num !~ /[0-9]/){
					print "\nNumerals only please!!\n\n";
					redo;
				} else { 
					$row[($col_num - 1)] = "tgt_term" if ($col_num =~ /[1-9]/);
					last;
				}
			}
			
			while (1) {
			print "PART OF SPEECH: ";
				$col_num = <STDIN>;
				if ($col_num !~ /[0-9\n]/){
					print "\nNumerals only please!!\n\n";
					redo;
				} else { 
					$row[($col_num - 1)] = "partOfSpeech" if ($col_num =~ /[1-9]/);
					last;
				}
			}
			
			while (1) {
			print "TERM STATUS: ";
				$col_num = <STDIN>;
				if ($col_num !~ /[0-9\n]/){
					print "\nNumerals only please!!\n\n";
					redo;
				} else { 
					$row[($col_num - 1)] = "status" if ($col_num =~ /[1-9]/);
					last;
				}
			}
			
			while (1) {
			print "CUSTOMER: ";
				$col_num = <STDIN>;
				if ($col_num !~ /[0-9\n]/){
					print "\nNumerals only please!!\n\n";
					redo;
				} else { 
					$row[($col_num - 1)] = "customer" if ($col_num =~ /[1-9]/);
					last;
				}
			}
			
			while (1) {
			print "NOTES: ";
				$col_num = <STDIN>;
				if ($col_num !~ /[0-9\n]/){
					print "\nNumerals only please!!\n\n";
					redo;
				} else { 
					$row[($col_num - 1)] = "note" if ($col_num =~ /[1-9]/);
					last;
				}
			}
			
			while (1) {
			print "SUBJECT MATTER: ";
				$col_num = <STDIN>;
				if ($col_num !~ /[0-9\n]/){
					print "\nNumerals only please!!\n\n";
					redo;
				} else { 
					$row[($col_num - 1)] = "subject" if ($col_num !~ /[0\n]/);
					last;
				}
			}
			
			while (1) {
			print "ENTRY IDs: ";
				$col_num = <STDIN>;
				if ($col_num !~ /[0-9\n]/){
					print "\nNumerals only please!!\n\n";
					redo;
				} else { 
					$row[($col_num - 1)] = "id" if ($col_num !~ /[0\n]/);
					last;
				}
			}

			while (1) {
				print "Is this correct? \n\nORIGINAL HEADER ROW:\n\n\t@original_row\n\nCONFIGURED HEADER ROW:\n\n\t@row\n\nY/N: ";
				$yes_or_no = <STDIN>;
				if ($yes_or_no =~ /yes|y|no|n/i)
				{
					last;
				}
				else
				{
					print "Please type either 'y' or 'n' or 'yes' or 'no'";
				}
			}
			if ($yes_or_no =~ /no|n/i) {
                return -1;
            }
            
		} elsif ($header_found == 0) {
			next 
		}
		local $" = "\t";
		print $fhout "\n@row";
		# _print_tabdelim(
	}
	
	
	return \$fhout;
}

sub _run {

	if (!defined($ARGV[9]))
	{
	print "Please answer a few questions (* means optional):\n";
	print "Source language (ISO 639, e.g.  German = 'de',  English = 'en', etc.): ";
		my $source_lang = <STDIN>;
	print "Target language (ISO 639, e.g.  German = 'de',  English = 'en', etc.): ";
		my $target_lang = <STDIN>;
	print "Timestamp (ISO 8601, e.g. 2014-03-02, >>leave blank to generate new<<)*: ";
		my $timestamp = <STDIN>;
	print "License*: ";
		my $license = <STDIN>;
	print "Creator*: ";
		my $creator = <STDIN>;
	print "Description*: ";
		my $description = <STDIN>;
	print "Directionality (monodirectional OR bidirectional?): ";
		my $directionality = <STDIN>;
	print "Subject (leave blank if each entry is different)*: ";
		my $subject = <STDIN>;
	print "Dictionary ID*: ";
		my $d_id = <STDIN>;
		
		while(1){
			last if (config_spreadsheet_terminal($ARGV[0], $source_lang, $target_lang, $timestamp, $license, $creator, $description, $directionality, $subject, $d_id, $ARGV[0]) != -1)
		}
	}
	else
	{
		config_spreadsheet(@ARGV);
	}
}

#sub _get_handle {
#    my ($input, $output) = @_;

#    my ($fh, $fhout);
	
	# open $fhout, '>', $output;
	
#    if((ref $input) eq 'SCALAR'){

#        open $fh, '<', $input; ## no critic(RequireBriefOpen)

#    }else{

#		$fh = path($input)->filehandle('<');
     
#    }
#    return ($fh, $fhout);
#}

_run() unless caller;