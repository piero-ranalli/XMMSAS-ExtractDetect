package XMMSAS::Call;

=head1 NAME

XMMSAS::Call.pm

=head1 VERSION

Version 2.0;

=cut

our $VERSION = '2.0';

=head1 SYNOPSIS

This is a Moose role, so it cannot be used directly. Use rather
XMMSAS::Extract or XMMSAS::Detect.

my $sas = XMMSAS::Extract->new;

$sas->ccf("path/to/ccf.cif");    # provided by XMMSAS::Call

$sas->odf("path/to/...SUM.SAS"); # provided by XMMSAS::Call

$sas->call("command");

=cut

use Moose::Role 'has';

has 'ccf'     => ( is => 'rw', isa => 'Str', predicate => 'has_ccf' );
has 'odf'     => ( is => 'rw', isa => 'Str', predicate => 'has_odf' );
has 'verbose' => ( is => 'rw', isa => 'Bool', default=> 1 );

sub call {
    my $self = shift;
    my $cmd = shift;

    if ($self->has_ccf and $self->has_odf) {
	my $ccf = $self->ccf;
	my $odf = $self->odf;
	$cmd = "SAS_CCF=$ccf SAS_ODF=$odf ".$cmd;
    }

    #print($LOG "$$ COMMAND: $SAS $cmd\n");
    print("$$ COMMAND:  $cmd\n") if $self->verbose;
    my $out = `$cmd`;

    # check exit status and print output and/or errors
    if ($?) {
	print("$$: something wrong happened. Please check for errors in the log.\nThe command line was:\n$cmd\n");
      }
    print("$$ STDOUT:\n$out") if $self->verbose;

    return $out;
}



1;


=head1 AUTHOR

(c) 2011-2013 Piero Ranalli   piero.ranalli (at) noa.gr

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Piero Ranalli.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see http://www.gnu.org/licenses/.

=cut

