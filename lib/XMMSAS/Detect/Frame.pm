package XMMSAS::Detect::Frame;

# frame everything in a common WCS reference
# or otherwise emldetect will complain

use Moose::Role qw/has/;
use PDL;
use File::Temp;

use Carp;

has 'framera'     => ( is => 'rw', isa => 'Num' );
has 'framedec'    => ( is => 'rw', isa => 'Num' );
has 'framesizex'  => ( is => 'rw', isa => 'Num' );
has 'framesizey'  => ( is => 'rw', isa => 'Num' );
has 'frame'       => ( is => 'rw', isa => 'Object' );
has 'cellname'    => ( is => 'rw', isa => 'Str' );

sub reframe {
    my $self = shift;

    $self->createframe( 'cell_img_'.$self->cellname.'.fits' );

    my $framed = $self->putinframe( $self->img );
    $self->img( $framed );

    $framed = $self->putinframe( $self->expmap );
    $self->expmap( $framed );

    $framed = $self->putinframe( $self->novign );
    $self->novign( $framed );

    $framed = $self->putinframe( $self->bkg );
    $self->bkg( $framed );
}


sub createframe {
    my $self = shift;
    my $frame1 = shift;

    # frame1 is the cell image
    # frame2 is the empty frame

    #my $frametemp1 = File::Temp->new( 'frameXXXX', SUFFIX=>'.fits', UNLINK=>0 );
    #my $frame1 = $frametemp1->filename;
    unlink $frame1 if (-e $frame1);

    my $frametemp2 = File::Temp->new( 'frameXXXX', SUFFIX=>'.fits' );
    my $frame2 = $frametemp2->filename;


    # add images to create frame
    my $cmd = 'addimages '.join(' ',@{$self->img})." $frame1 expand=yes";
    $self->call($cmd);

    # empty frame
    $cmd = "imcarith $frame2 = $frame1 '*' 0";
    $self->call($cmd);

    $self->frame($frametemp2);
}


sub putinframe {
    my $self = shift;
    my $imgs = shift;

    my @framed;
    for my $i (@$imgs) {

	my $f = "framed_$i";
	unlink ($f) if (-e $f);

	my $cmd = 'addimages '.$self->frame->filename." $i $f expand=no";
	$self->call($cmd);

	# transfer pointing information
	my $hdr = rfitshdr($i);
	for my $k (qw/RA_PNT DEC_PNT PA_PNT/) {
	    $cmd = sprintf("fparkey %12.8f %s+0 %s add=yes",$hdr->{$k},$f,$k);
	    $self->call($cmd);
	}

	push @framed,$f;
    }

    return \@framed;
}


1;
