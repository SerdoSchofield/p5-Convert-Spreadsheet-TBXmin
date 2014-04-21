# NAME

Convert::TBX::Spreadsheet - Convert a Spreadsheet Glossary into TBX-Min

# SYNOPSIS

	use Convert::TBX::Spreadsheet;
	my $TBX_string_output = convert_spreadsheet('/path/to/file.utx', '/path/to/output');  

# DESCRIPTION

A converter for preconfigured UTF-8 tab delimited spreadsheets to TBX-Min.

# SPREADSHEET FORMAT

A pre-configuration module has been added to walk the user through this process, should they prefer not to do it manually.

To use this module, simply download this package, and via command promt navigate into the 'lib/Convert/TBX/' directory.  Then, run the perl script 'config.pm' as shown: 

'-$ perl config.pm <input file (the spreadsheet you wish to configure)>'

The process will require at least the following modules to be installed via CPAN console command:

Spreadsheet::Read
Exporter::Easy

*May or may not require (This depends on your spreadsheet type, e.g. Excel, Libre Office, Open Office):
*The easiest way to know what you need is to run the script and see what module it asks for

Spreadsheet::ReadSXC,   (Libre Office/Open Office)
Spreadsheet::ParseExcel, (MS Excel)
Spreadsheet::ParseXLSX, (MS Excel)
Spreadsheet::XLSX, (MS Excel)
Text::CSV_XS, (CSV files)
Text::CSV_PP, (CSV files)


Edit Manually:

1) Add all relevent header info to the beginning of spreadsheet on separate rows like so:
	
	source_lang: en (or whatever the language)
	target_lang: es
	timestamp: (Timestamp using ISO 8601)
	creator: creator
	license: license
	description: a glossary of terms
	dict_id: D001 (or whatever the dictionary id)
	bidirectional  (or if monodirectional, "monodirectional")
	subject: examples
	
2) Change all compatible column headers to any of the following depending on best match:
	
	src_term
	tgt_term
	id (meaning entry/concept id)
	partOfSpeech (must be noun/verb/adjective/adverb to convert)
	status (must be admitted/preferred/notRecommended/obsolete to convert)
	note
	customer
	
	Ex: (all columns are tab delimited in this example)
		src_term	tgt_term	status	partOfSpeech	note	customer	id
		apple	manzana		admitted	noun	a type of fruit	Apple Pie Factory	C001

3) Clean up unnecessary markup (such as alphbetical grouping markers)
4) Ensure UTF-8 encoding.
	
# METHODS

## 'convert_spreadsheet(input [, output])'

	Converts spreadsheets into TBX-Min format.  'Input' can be either filename or scalar ref containing scalar data.  If given only 'input' it returns a scalar ref containing the converted data.  If given both 'input' and 'output', it will print converted data to the 'output' file.

# TERMINAL COMMANDS

## 'spreadsheet2tbx (input_utx) (output)'

	Converts Spreadsheet to TBX-Min and prints to <output>.

# AUTHORS

James Hayes <james.s.hayes@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alan Melby.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

