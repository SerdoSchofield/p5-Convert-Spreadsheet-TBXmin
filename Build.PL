use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
	module_name	=> 'Convert::TBX::Spreadsheet',
	dist_abstract => 'Convert spreadsheet Glossaries to TBX-Min',
	license	=>	'perl',
	dist_version_from	=>	'lib/Convert/TBX/Spreadsheet.pm',
	script_files	=>	[ qw(bin/spreadsheet2tbx) ],
	build_requires	=>	{
		"TBX::Min" => "0.05",
		"Exporter::Easy" => "0.16",
		"Path::Tiny" => "0.052",
	},
	create_makefile_pl => 'traditional',
);

$build->create_build_script();