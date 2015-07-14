#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use File::Basename;
use Math::Round;
use File::Find::Rule;
use Cwd;

my $safe = 0;
my $unsafe = 0;
my $zero = 0;
my $ones = 0;

my $opts = {
	'verbose'              => 0,
	'help'                 => \&help,
	'dry-run'              => 0,
	'min=f'                => 1.5,           # abs(Values) between this and 0 will not be scaled
	'scale=f'              => 1,             # multiply all values by
	'factor=f'             => 3,             # Round to the nearest factor
	'processed-suffix=s'   => '-updated'
};

prepOptions();

# print "Intook:\n" . Dumper($opts, \@ARGV, optsGetKeys());

main();

exit;

#
### SUBS ###
#

sub main {
	# If input args are empty, lets work on the current directory.
	push(@ARGV, getcwd()) unless ($#ARGV);
	my $processed_files = 0;

	my $excludeFiles = File::Find::Rule->file
			->name(sprintf('*%s.*', $opts->{'processed-suffix'})) # Provide specific list of directories to *not* scan
			->discard;

	my $includeFiles = File::Find::Rule->file
			->name('*.less', '*.css'); # search by file extensions


	foreach my $arg (@ARGV) {
		message('-----') if ($processed_files and $#ARGV);
		if (-d $arg) {
			my $directory = $arg;
			my @Files = File::Find::Rule->or( $excludeFiles, $includeFiles )->in($directory);
			# print map { "$_\n" } @Files;
			foreach my $file (@Files) {
				processFile($file);
			}
			$processed_files+= scalar(@Files);
		}
		elsif (-f $arg) {
			processFile($arg);
			$processed_files++;
		}
		else {
			message($arg . ' not found...');
		}
	}

	if ($processed_files) {
		message(sprintf(':) %d safe values; %d rounding issues... :( %d zeros :| %d ones :| %d total in %d files :O', $safe, $unsafe, $zero, $ones, $safe + $unsafe + $zero + $ones, $processed_files));
	}
	else {
		message('Could not find any files to work on. Nothing to do. Exiting :(');
	}
}

sub processFile($) {
	my $file = shift();
	my $ofh;
	my $modded_file = '';
	my $mod_lines = 0;
	my $wetrun = !$opts->{'dry-run'};

	message('Processing '. $file, 1);
	open(my $fh, '<', $file) or die("Can't open file $file: $!");

	my $selector = '';
	while (<$fh>) {
		if (/^\s*((\@[^:;]+)|(.*)\s\{)/) {
			$selector = ($2 or $3);
		}
		my $before = $_;

		if (/\w\s*:.*\d/) {
			s/^(\s*)(\S+)(\s*:\s*)([^;]+)(;?.*\s*$)/$1 . $2 . $3 . &parseValue($4, $selector, $2) . $5/gex;
		}
		# # Look for (non-whitespace), (a sesector, the : and a non-color), (a whole number), (a px, space or ;)
		# s/(\S+)(\s*:\s*[^#\d]?)(-?\d+)(px|\s|;)/$1 . $2 . &countItUp($3, $file, $selector, $1) . $4/gex;

		my $after = $_;
		$mod_lines++ if ($before ne $after);

		$modded_file.= $_;
	}
	close($fh);

	if ($mod_lines and $wetrun) {
		my ($filename, $dirs, $suffix) = fileparse($file, qr/\.[^.]*/);
		my $new_filename = $dirs . $filename . $opts->{'processed-suffix'} . $suffix;
		message('Creating file ' . $new_filename);
		open($ofh, '>', $new_filename) or die("Can't create file $new_filename: $!");

		print $ofh $modded_file;

		close($ofh)
	}
}

sub parseValue {
	my $source_value = shift();
	my $selector = shift();
	my $rule = shift();
	my @Values = split(/\s+/, $source_value);

	if ($selector eq $rule) {
		$selector = '';
	}
	else {
		$selector.= ' { ';
	}
	my $count = 0;
	foreach (@Values) {
		$count++;
		if (/px$/) {
			(my $val = $_) =~ s/^.*(-?(\d\.)?\d+)(\w+)$/$1/;
			if ($val ne $_) {
				my $before = $val;
				my $unit = $3;
				$val = countItUp($val, $rule);
				message(sprintf(' %-70s %s%s', $selector.$rule, ($#Values ? ($count .': ') : '   '), ($before == $val) ? 'OK' : ($before .'->'. $val)), 1);
				$_ = $val . $unit;
			}
		}
	}
	return join(' ', @Values)
}

sub countItUp($) {
	my $orig_num = shift();
	my $rule = shift();
	my $factor = $opts->{'factor'};

	my $num = $orig_num * $opts->{'scale'};
	$num = round($num);

	if ($num == 0) {
		$zero++;
	}
	elsif (abs($num) <= $opts->{'min'}) {
		$ones++;
	}
	elsif ($num % $factor) {
		$unsafe++;
		$num = nearest($factor, $num);
	}
	else {
		$safe++;
	}
	return $num;
}

sub message {
	my $threshold = scalar(@_) >= 2 ? pop() : 0;
	print @_, "\n" if ($opts->{'verbose'} >= $threshold);
}

sub prepOptions {
	my ($cleanoptions, @OptSwitches);
	foreach my $key (keys %{$opts}) {
		(my $o = $key) =~ s/[^\w\-].*$//;
		$cleanoptions->{$o} = $opts->{$key};
		push(@OptSwitches, $key);
		delete $opts->{$key};
	}
	$opts = $cleanoptions;

	GetOptions($opts, @OptSwitches) or help();
}

sub help {
	my ($opt_name, $opt_value) = @_;
	my $script_name = \$0;
	my $help_text = <<END_HELP;
=========================================================
----- Welcome to the CSS Value Checker and Updater  -----
=========================================================

  $ $script_name <folder> <folder> <file> <file>

Below are the supported options.

  USEFUL SWITCHES
    -d or --dry-run    =  Run in pretend mode, and don't modify any files.
    -s or --scale      =  Supply a value, and all pixel values will be
                          multiplied by this number. Float values are
                          acceptable. (Default: 1)
    -m or --min        =  The minumum value to not modify. (Default: 1.5)
    -f or --factor     =  The rounding value, to which all numbers should be
                          rounded to the nearest. (Default: 3)
    --processed-suffix =  This string will be appended to the end of processed
                          filenames. (Default: "-updated")

  LESS USEFUL SWITCHES
    -v or --verbose    =  Turn on verbose output, show everything we are doing.
    -h or --help       =  Show this help.

END_HELP
	$opt_value ? print $help_text : die "See --help below:\n" . $help_text;
	exit;
}
