#!/usr/bin/perl

package Convert::TBX::Spreadsheet;
use strict;
use warnings;
# use Spreadsheet::Read qw(ReadData row);
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
	my ($source_lang, $target_lang, $timestamp, $creator, $license, $description, $id, $directionality, $subject, $started, @record, @field_name);
	my ($fh, $fhout) = @_;
	
	# my $data = ReadData($fh, parser => 'csv')
		# or die "couldn't read spreadsheet";
	
	# my @row = row($fh);
	# print $fhout "@row";
	
	do {
		$_ = <$fh>;
		chomp;
		if ($. == 1) {
			s/^(?:\xef\xbb\xbf|\x{feff})//;  #remove BOM
		}
		
		if($_ !~ /src_term|tgt_term/i){
			$source_lang = $1 if /source_lang: ([a-zA-Z-]*)/;
			$target_lang = $1 if /target_lang: ([a-zA-Z-]*)/;
			$timestamp = $1 if /timestamp: ?([0-9T:+-]+)/;
			$creator = $1 if /creator: ?([^;]+)/i;
			$license = $1 if /license: ?([^;]+)/i;
			$description = $1 if /description: ?([^;]+)/i;
			$id = $1 if /dict_id:* ?([^;]+)/i;
			$directionality = $1 if /(bidirectional|monodirectional)/i;
			$subject = $1 if /subject\w*: ?([^;]+)/i;
		}
		
		if (/src_term|tgt_term/i) {
			$started = 1;
			chomp;
			@field_name = split /\t/;
		};
	} until (defined $started);
	
		# print "$started hello @field_name";
	


	my $TBXmin = TBX::Min->new();
	
	$TBXmin->source_lang($source_lang) if (defined $source_lang);
	$TBXmin->target_lang($target_lang) if (defined $target_lang);
	$TBXmin->creator($creator) if (defined $creator);
	$TBXmin->date_created($timestamp);
	$TBXmin->description($description) if (defined $description);
	$TBXmin->directionality($directionality) if (defined $directionality);
	$TBXmin->license($license) if (defined $license);
	$TBXmin->id($id) if (defined $id);

	
	while(<$fh>){
		chomp;
		# turn line to list, then list to hash
		my @field = split /\t/;
		# print @field;
		my %record;
		%record = map {$field_name[$_] => $field[$_]} (0..$#field);
		
		push @record, \%record;
		# next if (/^\s*$/); #skip if blank
		# print @record;
		# print $fhout "";
		# print "hello";
	}
		
		
		foreach my $hash_ref (@record) {
			my ($lang_group_source, $lang_group_target, $term_group_source, $term_group_target, $source, $target);
			my %hash = %$hash_ref;
			my $entry = TBX::Min::Entry->new();

			while(my ($key, $value) = each %hash){
				# chomp($value);
				if ($key =~ /src_term/){
					$lang_group_source = TBX::Min::LangGroup->new({code => $source});
					$term_group_source = TBX::Min::TermGroup->new({term => $value});
					# print $value;
				}
				elsif ($key =~ /tgt_term/){
					$lang_group_target = TBX::Min::LangGroup->new({code => $target});
					$term_group_target = TBX::Min::TermGroup->new({term => $value});
					# ($entry, $term_group) = _set_picklist($entry, $term_group, %hash);
				}
			}
			
			# ($entry, $term_group) = _set_picklist($entry, $term_group, %hash);
			# print "hello";
			# print %hash;
			while(my ($key, $value) = each %hash) {
				# chomp($value);
				print "$value\n";
				if ($key =~ /^id$/i){
					$entry->id($value) if (defined $value);
				}
				elsif ($key =~ /status/i){
					if ($key =~ /source/i) {$term_group_source->status($value)}
					elsif ($key =~ /target/i){$term_group_target->status($value)}
					else {
						$term_group_source->status($value) if (defined $term_group_source);
						$term_group_target->status($value) if (defined $term_group_target);
					}
				}
				elsif ($key =~ /partOfSpeech/i){
					if ($key =~ /source/i) {$term_group_source->part_of_speech($value)}
					elsif ($key =~ /target/i){$term_group_target->part_of_speech($value)}
					else {
						$term_group_source->part_of_speech($value) if (defined $term_group_source);
						$term_group_target->part_of_speech($value) if (defined $term_group_target);
					}
				}
				elsif ($key =~ /customer/i){
					if ($key =~ /source/i) {$term_group_source->customer($value)}
					elsif ($key =~ /target/i){$term_group_target->customer($value)}
					else {
						$term_group_source->customer($value) if (defined $term_group_source);
						$term_group_target->customer($value) if (defined $term_group_target);
					}
				}
				elsif ($key =~ /note/i){
					if ($key =~ /source/i) {$term_group_source->note($value)}
					elsif ($key =~ /target/i){$term_group_target->note($value)}
					else {
						$term_group_source->note($value) if (defined $term_group_source);
						$term_group_target->note($value) if (defined $term_group_target);
					}
				}
				# print "1";
			}
			
				if (defined $term_group_source) {
					print "helalooa0odf";
					$lang_group_source->add_term_group($term_group_source);
					$entry->add_lang_group($lang_group_source);
				}
				if (defined $term_group_target) {
					$lang_group_target->add_term_group($term_group_target);
					$entry->add_lang_group($lang_group_target);
				}
			
			$TBXmin->add_entry($entry);
		}
	
	if (defined $started == 0) {die "This file has not been preconfigured!\n"}
	
	my $TBXmin_ref = $TBXmin->as_xml;
	my $TBXminstring .= "<?xml version='1.0' encoding=\"UTF-8\"?>\n".$$TBXmin_ref;
	
	print $fhout $TBXminstring;
}

sub _set_picklist {
	my ($entry, $term_group, %hash) = @_;
	while(my ($key, $value) = each %hash) {
		if ($key =~ /^id$/i){
			$entry->id($value) if (defined $value);
		}
		elsif ($key =~ /status/i){
			$term_group->status($value) if (defined $value);
		}
		elsif ($key =~ /partOfSpeech/i){
			$term_group->part_of_speech($value) if (defined $value);
		}
		elsif ($key =~ /customer/i){
			$term_group->customer($value) if (defined $value);
		}
		elsif ($key =~ /note/i){
			$term_group->note($value) if (defined $value);
		}
	}
	return ($entry, $term_group);
}

_run() unless caller;