#!/usr/bin/perl

package Convert::TBX::Spreadsheet;
use strict;
use warnings;
# use Spreadsheet::Read qw(ReadData row);
use TBX::Min;
use Path::Tiny;
use DateTime;
use Exporter::Easy (
	OK => [ 'convert_spreadsheet' ]
	);

use open ':encoding(utf8)', ':std';

our $VERSION = 0.02;

sub convert_spreadsheet {
	my ($fh, $fhout);
	my ($input, $output) = @_;
	($fh, $fhout) = _get_handle($input, $output);
	
	my $TBXmin_string = _convert($fh, $fhout);
	
	return \$TBXmin_string;
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
	
	do {
		$_ = <$fh>;
		chomp;
		if ($. == 1) {
			s/^(?:\xef\xbb\xbf|\x{feff})//;  #remove BOM
		}
		
		if($_ !~ /src_term|tgt_term/i){
			$source_lang = $1 if /source_lang: ([a-zA-Z-]+)/;
			$target_lang = $1 if /target_lang: ([a-zA-Z-]+)/;
			#$timestamp = $1 if /timestamp: ?([0-9T:+-]+)/; #spreadsheet converter only generates timestamp
			$creator = $1 if /creator: ?([^;]+)/i;
			$license = $1 if /license: ?([^;]+)/i;
			$description = $1 if /description: ?([^;]+)/i;
			$id = $1 if /dict_id:* ?([^;]+)/i;
			$directionality = $1 if /(bidirectional|monodirectional)/i;
			$subject = $1 if /subject\w*: ?([^;]+)/i;
		}
		
		if (!defined $target_lang)
		{
			$directionality = undef;
		}
		
		if (/src_term|tgt_term/i) {
			$started = 1;
			chomp;
			@field_name = split /\t/;
		};
	} until (defined $started);

	my $TBXmin = TBX::Min->new();
	my $ID_Check = TBX::Min->new();
	$timestamp = DateTime->now()->iso8601();
	$TBXmin->source_lang($source_lang) if (defined $source_lang);
	$TBXmin->target_lang($target_lang) if (defined $target_lang && $target_lang !~ /\s*[\r\n]?/);
	$TBXmin->creator($creator) if (defined $creator && $creator !~ /\s*[\r\n]?/);
	$TBXmin->date_created($timestamp);
	$TBXmin->description($description) if (defined $description  && $description !~ /\s*[\r\n]?/);
	$TBXmin->directionality($directionality) if (defined $directionality);
	$TBXmin->license($license) if (defined $license && $license !~ /\s*[\r\n]?/);
	$TBXmin->id($id) if (defined $id && $id !~ /\s*[\r\n]?/);

	my @ERROR;
	my $NAMES;
	while(<$fh>){
		chomp;
		s/\s*$//;
		next if /^$/;  #do not include blank lines

		# turn line to list, then list to hash
		my @field = split /\t/;
		foreach (@field)
		{
			s/^\s+//;
		}
		my %record;
		%record = map {$field_name[$_] => $field[$_]} (0..$#field);
		
		push @record, \%record;
	}
		
		my $x = 0;
		foreach my $hash_ref (@record) {
			my $noteGrp = TBX::Min::NoteGrp->new;
			my ($lang_group_source, $lang_group_target, $term_group_source, $term_group_target);
			my %hash = %$hash_ref;
			my $entry = TBX::Min::TermEntry->new();
			
			while(my ($key, $value) = each %hash){
				if ($key =~ /src_term/){
					$lang_group_source = TBX::Min::LangSet->new({code => $source_lang});
					$term_group_source = TBX::Min::TIG->new({term => $value}) if (defined $value && $value ne '');
				}
				elsif ($key =~ /tgt_term/){
					$lang_group_target = TBX::Min::LangSet->new({code => $target_lang});
					$term_group_target = TBX::Min::TIG->new({term => $value}) if (defined $value && $value ne '');
				}
			}
			
			while(my ($key, $value) = each %hash) {
				if ($key =~ /^id$/i){
					$entry->id($value) if (defined $value);
				}
				elsif ($key =~ /status/i){
					$value = undef if (defined $value && $value !~ /admitted|preferred|notRecommended|obsolete/i);
					if ($key =~ /source/i) {$term_group_source->status($value)}
					elsif ($key =~ /target/i){$term_group_target->status($value)}
					else {
						$term_group_source->status($value) if (defined $term_group_source);
						$term_group_target->status($value) if (defined $term_group_target);
					}
				}
				elsif ($key =~ /partOfSpeech/i){
					$value = undef if (defined $value && $value =~ /verb|adjective|adverb|noun/i);
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
				
					push(@ERROR, "LINE $x: $key + $value ||<br>\n");
					
					if ($value !~ /\w+/){next}
					if (!defined $noteGrp)
					{
						my $key = $1 if ($key =~ /(?<=:)\s*(.+)/);
						my $note = TBX::Min::Note->new(noteValue => $value);
						$note->noteKey($key) if defined $key;
						$noteGrp->add_note($note);
						$NAMES .= $key."_i_|_i_<br>";
					}
					else
					{
						my $key = $1 if ($key =~ /(?<=:)\s*(.+)/);
						my $note = TBX::Min::Note->new(noteValue => $value);
						$note->noteKey($key) if defined $key;
						$noteGrp->add_note($note);
						$NAMES .= $key."_i_|_i_<br>";
					}
# 					if ($value =~ /\w+/){
# 						if (defined $term_group_source)
# 						{
# 							if (!defined ${$term_group_source->note_groups}[0])
# 							{
# 								$noteGrp = TBX::Min::NoteGrp->new();
# 								my $note = TBX::Min::Note->new();
# 								if ($key =~ /note:(.+)/){
# 									$note->noteKey($1);
# 									$note->noteValue($value);
# 								}else{
# 									$note->noteValue($value);
# 								}
# 								
# 								$noteGrp->add_note($note);
# 							}
# 							else
# 							{
# 								$noteGrp = @{$term_group_source->note_groups}[0];
# 								my $note = TBX::Min::Note->new();
# 								if ($key =~ /:(.+)/){
# 									$note->noteKey($1);
# 									$note->noteValue($value);
# 								}else{
# 									$note->noteValue($value);
# 								}
# 								$noteGrp->add_note($note);
# 							}
# 							if (defined $term_group_source && defined $noteGrp) { $term_group_source->add_note_group($noteGrp) }
# 						}
# 						if (defined $term_group_target)
# 						{
# 							if (!defined ${$term_group_target->note_groups}[0])
# 							{
# 								$noteGrp = TBX::Min::NoteGrp->new();
# 								my $note = TBX::Min::Note->new();
# 								
# 								if ($key =~ /note:(.+)/){
# 									$note->noteKey($1);
# 									$note->noteValue($value);
# 								}else{
# 									$note->noteValue($value);
# 								}
# 								
# 								$noteGrp->add_note($note);
# 							}
# 							else
# 							{
# 								$noteGrp = @{$term_group_target->note_groups}[0];
# 								my $note = TBX::Min::Note->new();
# 								
# 								if ($key =~ /:(.+)/){
# 									$note->noteKey($1);
# 									$note->noteValue($value);
# 								}else{
# 									$note->noteValue($value);
# 								}
# 								$noteGrp->add_note($note);
# 							}
# 							if (defined $term_group_target && defined $noteGrp) { $term_group_target->add_note_group($noteGrp) }
# 						}
# 					}
				}
				elsif ($key =~ /subject/i && (defined $subject == 0)){
					if ($key =~ /source/i) {$subject = $value if defined $value}
					elsif ($key =~ /target/i){$subject = $value if defined $value}
					else {
						$subject = $value if defined $value;
					}
				}
			}
			
			
				if (defined $term_group_source) {
					$term_group_source->add_note_group($noteGrp) if (@{$noteGrp->notes} > 0);
					$lang_group_source->add_term_group($term_group_source);
					$entry->add_lang_group($lang_group_source);
				}
				if (defined $term_group_target) {
					$term_group_target->add_note_group($noteGrp) if (@{$noteGrp->notes} > 0);
					$lang_group_target->add_term_group($term_group_target);
					$entry->add_lang_group($lang_group_target);
				}
			$entry->subject_field($subject);
			$ID_Check->add_entry($entry);
			$x++;
		}
	
	my (%count_ids_one, %count_ids_two, @entry_ids, $generated_ids);
	my $entry_list = $ID_Check->entries;
	foreach my $entry_value (@$entry_list) {
		my $c_id = $entry_value->id;
		if (defined $c_id){
			$count_ids_one{$c_id}++;
			for ($c_id) {s/C([0-9]+)/$1/i};
			push (@entry_ids, $c_id);
		}
	}
	
	foreach my $entry_value (@$entry_list) {
		my $c_id = $entry_value->id;
		$count_ids_two{$c_id}++ if defined $c_id;
		
		if (defined $c_id == 0 or $c_id eq '-'  or (defined $c_id && $count_ids_one{$c_id} > 1 && $count_ids_two{$c_id} > 1)) {
			do  {$generated_ids++} until ("@entry_ids" !~ sprintf("%03d", $generated_ids));
			push @entry_ids, $generated_ids;
			$entry_value->id("C".sprintf("%03d", $generated_ids))
		}
		$TBXmin->add_entry($entry_value);
	}	
	
	
	if (defined $started == 0) {die "This file has not been preconfigured!\n"}
	
	my $TBXmin_ref = $TBXmin->as_xml;
	my $TBXminstring .= "<?xml version='1.0' encoding=\"UTF-8\"?>\n".$$TBXmin_ref;
	
# 	die "$NAMES<br><br><br>@ERROR\n\n<br><br><br>$TBXminstring";
	print $fhout $TBXminstring;
	
	return $TBXminstring;
}

sub _set_picklist {
	my ($entry, $term_group, %hash) = @_;
	while(my ($key, $value) = each %hash) {
		if ($key =~ /^id$/i){
			$entry->id($value) if (defined $value);
		}
		elsif ($key =~ /status/i){
			$term_group->status($value) if (defined $value && $value =~ /admitted|preferred|notRecommended|obsolete/);
		}
		elsif ($key =~ /partOfSpeech/i){
			$term_group->part_of_speech($value) if (defined $value && $value =~ /noun|verb|adjective|adverb/);
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