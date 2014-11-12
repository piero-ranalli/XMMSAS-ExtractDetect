# NAME

XMMSAS::Detect  --  interface to XMM-Newton SAS emldetect (and more)

# SYNOPSIS

    use XMMSAS::Detect;
    my $sas = XMMSAS::Detect->new;

## Background fit

    $sas->img( $images );
    $sas->expmap( $expmaps );
    $sas->novign( $expmaps_novign );

    $sas->fitbkg;



## Detection

    $sas->cellname( "my_cell_name" );  # cellname is used when files are reframed

    # $images,$expmaps,$expmaps_novign,$bkgs are array refs containing the
    # filenames on which to run emldetect

    $sas->img( $images );
    $sas->expmap( $expmaps );
    $sas->novign( $expmaps_novign );
    $sas->bkg( $bkgs );
    $sas->emlcat( "my_catalogue_name.fits" );

    $sas->ecf(   [ ($ecf)   x $nimg ] ); # $nimg = number of images
    $sas->pimin( [ ($pimin) x $nimg ] );
    $sas->pimax( [ ($pimax) x $nimg ] );

    $sas->odf( "/path/to/nnnnSUM.SAS" );
    $sas->ccf( "/path/to/ccf.cif" );
    $sas->srclist( $srclist );  # $srclist is the input catalogue

    # frame everything in a common WCS reference
    # or otherwise emldetect will complain
    $sas->framesizex( $framesizex );
    $sas->framesizey( $framesizey );
    $sas->framera(  $centre_ra  );
    $sas->framedec( $centre_dec );
    $sas->reframe;
    $sas->fudge_obsid_instr;

    # call emldetect
    $sas->emldetect;



## Sensitivity maps

    $sas->expmap( $expmaps );
    $sas->bkg( $bkgs );

    $sas->make_srcmasks;
    $sas->fudge_obsid_instr_in_detmasks;
    $sas->sensmap( sprintf("sensmap-%s.fits",$sas->cellname) );
    $sas->esensmap;

# DESCRIPTION

This module is an interface to the detection process in XMM-Newton
observation. It does three things:

- fit a background model to the images and exposure maps, using
the method developed for XMM-COSMOS (Cappelluti et al. 2009);
- run emldetect on a set of images, taking care of reframing
them if they are in different WCS reference systems;
- compute sensitivity maps (using the SAS tool esensmap).

The reference for using this module is the
[griddetect](http://members.noa.gr/piero.ranalli/griddetect) programme.
More information can be provided by asking the author.

# AUTHOR

(c) 2014 Piero Ranalli

pranalli-github@gmail.com

Post-doctoral researcher at the IAASARS, National Observatory of Athens;
Associate of INAF-OABO.

# LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see http://www.gnu.org/licenses/.



# HISTORY

1.0   2014  First public version


