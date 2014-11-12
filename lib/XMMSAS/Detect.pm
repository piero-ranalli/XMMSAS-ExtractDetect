package XMMSAS::Detect;

use Moose qw/has with after/;
with 'XMMSAS::Call';
with 'XMMSAS::Detect::Frame';
with 'XMMSAS::Sensmap';

use PDL;
use Astro::WCS::PP;
use Carp;
use List::Util ();

has 'img'     => ( is => 'rw', isa => 'ArrayRef[Str]' );
has 'expmap'  => ( is => 'rw', isa => 'ArrayRef[Str]' );
has 'novign'  => ( is => 'rw', isa => 'ArrayRef[Str]' );
has 'bkg'     => ( is => 'rw', isa => 'ArrayRef[Str]' );
has 'srclist' => ( is => 'rw', isa => 'Str' );
has 'emlcat'  => ( is => 'rw', isa => 'Str' );
has 'srccat'  => ( is => 'rw', isa => 'Any', predicate => 'has_srccat' );
has 'srclist_racol'   => ( is => 'rw', isa => 'Str', default => 'RA' );
has 'srclist_deccol'  => ( is => 'rw', isa => 'Str', default => 'DEC' );

has 'ecf'   => ( is => 'rw', isa => 'ArrayRef[Num]', predicate => 'has_ecf' );
has 'pimin' => ( is => 'rw', isa => 'ArrayRef[Num]', predicate => 'has_pimin' );
has 'pimax' => ( is => 'rw', isa => 'ArrayRef[Num]', predicate => 'has_pimax' );
has 'mlmin' => ( is => 'rw', isa => 'Num', default => 4.6 );



after 'srclist' => sub {
    my $self = shift;
    my $file = shift;

    if ($file) {
	my $cat = rfits($file.'[1]');
	$self->srccat($cat);
    }
};


sub fitbkg {
    my $self = shift;

    croak 'source list not loaded - cannot make cheesed mask for bkg fitting' unless $self->has_srccat;

    for my $i (0..$#{$self->img}) {
	$self->dofit($i);
    }
}

sub dofit {
    # background maps according to XMM-COSMOS method (Cappelluti et al. 2009)

    my $self = shift;
    my $i = shift;

    my $imgf = ${$self->img}[$i];
    my $expf = ${$self->expmap}[$i];
    my $novignf = ${$self->novign}[$i];

    my $bkgf = $imgf;
    $bkgf =~ s/_img/_bkg/;

    # my $dpn = $self->call("imexam $exp median reg=$novign");
    my $img = rfits($imgf);
    my $exp = rfits($expf);
    my $novign = rfits($novignf);

    # check that there is data in these images
    croak "no data in $imgf"    unless any($img);
    croak "no data in $expf"    unless any($exp);
    croak "no data in $novignf" unless any($novign);


    my $cheese = $self->srcmask($img);
    # cheese>0 in the holes => invert the mask
    $cheese = $cheese<1.e-3;

    # two possible interpretations for the median of the exposure:
    # 1) only active pixels
    # 2) all exposed pixel
    # no difference for the CDFS but may matter in ATLAS
    # Nico's script actually does the first one...
    my $on = $img>0;
    $on *= $cheese;
    my $dpn = $exp->where($on)->median;
    my $vpn  = $exp > $dpn;
    my $nvpn = $exp <= $dpn;

    $img *= $cheese;
    croak "no overlap between img and cheese for $imgf"
      unless any($img);

    my $c1 = $img->where($vpn)->sum;
    my $c2 = $img->where($nvpn)->sum;
    my $m11 = $novign->where($vpn)->sum;
    my $m12 = $novign->where($nvpn)->sum;
    my $m21 = $exp->where($vpn)->sum;
    my $m22 = $exp->where($nvpn)->sum;

    my $aa = ($c2*$m21 - $c1*$m22)/($m21*$m12 - $m11*$m22);
    my $bb = ($c1*$m12 - $c2*$m11)/($m21*$m12 - $m11*$m22);

    my $bkg1 = $novign * $aa;
    my $bkg2 = $exp * $bb;

    my $bkg = $bkg1+$bkg2;
    $bkg->sethdr( $img->gethdr );
    wfits($bkg,$bkgf);
}


sub srcmask {
    use PDL::NiceSlice;

    my $self = shift;
    my $img = shift;

    my ($x,$y) = wcstransfinv($img->hdr,
			      $self->srccat->{$self->srclist_racol},
			      $self->srccat->{$self->srclist_deccol}
			     );

    # extents are in image pixels
    my $extents = pdl [ $self->srccat->{EXTENT058}, $self->srccat->{EXTENT052}, $self->srccat->{EXTENT28} ];
    $extents->inplace->badmask(-1);  # -1 is ok since we are taking the maximum among positive values
    my $extent = $extents->xchg(0,1)->maximum;
    # but check anyway...
    croak 'sources with undefined extent' if (any($extent<0));

    my $maxradius= ceil($extent->max);

    # remove all srcs falling outside of the img
    my $msk = $x >= -$maxradius;
    $msk *= $x <= $img->dim(0)+$maxradius;
    $msk *= $y >= -$maxradius;
    $msk *= $y <= $img->dim(1)+$maxradius;
    $x = $x->where($msk);
    $y = $y->where($msk);
    $extent = $extent->where($msk);

    # create enlarged buffer and define its own coordinate system
    my $dim0 = $img->dim(0) + 4*$maxradius;
    my $dim1 = $img->dim(1) + 4*$maxradius;
    my $buf = zeroes sclr($dim0), sclr($dim1) ;
    my $x1 = $x+2*$maxradius;
    my $y1 = $y+2*$maxradius;

    # put mask in buffer
    for my $i (0..$x1->dim(0)-1) {
	my $ext = $extent($i)->rint->sclr;
	my $circle = rvals(2*$ext+1,2*$ext+1) <= $extent($i);
	$buf( $x1($i)->floor-$ext : $x1($i)->floor+$ext,
	      $y1($i)->floor-$ext : $y1($i)->floor+$ext )
	    += $circle;
    }

    # get cheese mask for original image
    my $cheese = $buf(2*$maxradius : -1-2*$maxradius, 2*$maxradius : -1-2*$maxradius);
    return $cheese;
    no PDL::NiceSlice;
}


sub emldetect {
    my $self = shift;

    # checks
    croak 'ecf,pimin,pimax not defined' 
	unless ($self->has_ecf and $self->has_pimin and $self->has_pimax);
    croak 'different numbers of images/expmaps/bkgs/ecf/pi'
	unless ($self->check_cardinalities);

    my $img =    'imagesets="'.join(' ',@{$self->img})   .'"';
    my $exp = 'expimagesets="'.join(' ',@{$self->expmap}).'"';
    my $bkg = 'bkgimagesets="'.join(' ',@{$self->bkg})   .'"';
    my $insrc = 'boxlistset='.$self->srclist;
    my $out =    'mllistset='.$self->emlcat;
    # my $ecf =          'ecf='.$self->ecf->[0];
    # my $pimin =      'pimin='.$self->pimin->[0];
    # my $pimax =      'pimax='.$self->pimax->[0];
    my $ecf =          'ecf="'.join(' ',@{$self->ecf})   .'"';
    my $pimin =      'pimin="'.join(' ',@{$self->pimin}) .'"';
    my $pimax =      'pimax="'.join(' ',@{$self->pimax}) .'"';
    my $mlmin =      'mlmin='.$self->mlmin;
    my $bufsize = 'imagebuffersize='.ceil(List::Util::max( $self->framesizex, $self->framesizey ));  #'imagebuffersize=10000';# 

    my @srcm = map { "src_".$_ } @{$self->img};
    my $srcmap = 'sourceimagesets="'.join(' ',@srcm)     .'"';

    my $cmd = <<EMLDETECT;
emldetect $img $exp $bkg fitextent=true extentmodel=gaussian fitposition=yes nmaxfit=2 ecut=10 scut=10 maxextent=20    $insrc  $out  $ecf $pimin $pimax  withxidband=false $mlmin withdetmask=no $bufsize withimagebuffersize=yes   withtwostage=yes  withsourcemap=yes $srcmap nmulsou=1 fitnegative=no minextent=5 -V 5
EMLDETECT

    $self->call($cmd);

}




sub check_cardinalities {
    my $self = shift;

    my $problems = 0;
    my $n = @{$self->img};
    $problems++ unless ($n == @{$self->expmap});
    $problems++ unless ($n == @{$self->novign});
    $problems++ unless ($n == @{$self->bkg});
    $problems++ unless ($n == @{$self->ecf});
    $problems++ unless ($n == @{$self->pimin});
    $problems++ unless ($n == @{$self->pimax});

    return $problems==0;
}



sub fudge_obsid_instr {
    my $self = shift;

    $self->do_fudge_o_i( $_ ) for ($self->img, $self->expmap, $self->novign, $self->bkg);
}


sub do_fudge_o_i {
    my $self = shift;
    my $files = shift;
    my $e = shift // 0;

    my $expid = 1;
    for my $f (@$files) {

	# rotate exposure values otherwise emldetect will think it's
	# the same instrument but different band, and will crash if
	# there are more than 6 "bands".

	my $cmd = "fthedit $f+$e INSTRUME add 'EPN'";
	$self->call($cmd);
	$cmd = sprintf("fthedit $f+$e EXP_ID add '%010i'",725290100+$expid);
	$self->call($cmd);
	$cmd = sprintf("fthedit $f+$e EXPIDSTR add '%03i'",$expid);
	$self->call($cmd);
	$cmd = sprintf("fthedit $f+$e OBS_ID add '%010i'",725290100+$expid++);
	$self->call($cmd);
    }
}



__PACKAGE__->meta->make_immutable;

1;
