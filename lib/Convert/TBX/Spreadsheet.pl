#!/usr/bin/perl

package Convert::TBX::Spreadsheet;
use strict;
use warnings;
use Spreadsheet::Read 'row';
use TBX::Min;
use Path::Tiny;
use Exporter::Easy (
	OK => [ 'convert_spreadsheet' ]
	);
	
use open ':encoding(utf8)', ':std';

our $VERSION = 0.01;

sub convert_spreadsheet {
	my ($fh, $fhout);
	my ($input, $output) = @_;
	($fh, $fhout) = _get_handle($input, $output);
	
	_convert($fh, $fhout);
}

sub _run {
	convert_spreadsheet($ARGV[0], $ARGV[1]);
}

sub _get_handle {
    my ($input, $output) = @_;

    my ($fh, $fhout);
	
	open $fhout, '>', $output;
	
    if((ref $input) eq 'SCALAR'){

        open $fh, '<', $input; ## no critic(RequireBriefOpen)

    }else{

		$fh = path($input)->filehandle('<');
     
    }
    return ($fh, $fhout);
}

sub _convert {
	my $started;
	my ($fh, $fhout) = @_;
	
	my $data = Spreadsheet::Read->ReadData($fh);
	
	my @row = row($fh);
	print $fhout "@row";
	
	while (<$fh>) {
		if ($. == 1) {
			s/^(?:\xef\xbb\xbf|\x{feff})//;  #remove BOM
		}
		
		# if (/source||target/i) {
			# $started = 1;
			# next;
		# }
		# next unless $started;
		
		# next if (/^\s*$/); #skip if blank
		my $row;
		
		
		print $fhout "$_";
		
		
		
		
	}
}

_run() unless caller;