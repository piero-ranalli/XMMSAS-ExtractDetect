# NAME

XMMSAS::Extract  --  Perl interface to XMM-Newton SAS to extract data products

XMMSAS::Detect  --  interface to XMM-Newton SAS emldetect (and more)

# ABOUT

These two modules are an interface to the XMM-Newton SAS software,
namely the evselect, eexpmap, emldetect and esensmap. Their use case
is for example in the analysis of large surveys or archives, or in
simulations, or whenever the above tasks must be repeated over and
over.

Below the synopsis is given for all the tools. More documentation is
given inside the modules themselves, and in the files
XMMSAS-Extract.md and XMMSAS-Detect.md .

The two modules share some code and are part of the same distribution,
therefore they can be installed together at the same time with the
standard sequence for Perl modules:

 perl Makefile.PL
 make
 make test
 make install

# Dependencies

There are several prerequisite for these module, some are mandatory:

- the FTOOLS and XMM-SAS software, along with the XMM CCFs;

- the PDL and Moose modules for Perl (can be installed from the
  repositories of any Linux distribution; or with Macports for the Mac);

- the L<Astro::WCS::PP
  module|https://github.com/piero-ranalli/Astro-WCS-PP>;

while the following is optional:

- L<Alexey Vikhlinin's
  zhtools|http://hea-www.harvard.edu/RD/zhtools/>, whose addimages
  command is used when reframing images before detection.
  

# SYNOPSIS

## Data product extraction

 my $sas = XMMSAS::Extract->new;

 $sas->evtfile("eventfile.fits");  # input evt

 my $boolean = $sas->camera_is_pn;    # boolean

 $sas->ccf("path/to/ccf.cif");

 $sas->odf("path/to/...SUM.SAS");

 $sas->attitude("path/to/...AttHk.fits");

 # $sas->verbose([01]); # set chatter level; default: 1

 $sas->addexpr('expr1','expr2',...); # adds filtering expressions

 $sas->add_predefined_expr($filter);
   # (or $sas->add_predefired_expr("not $filter");)
   # adds an expression from a library, appropriate for the camera.
   # For $filter, see B<EXPRESSION LIBRARY>
   # The filter can be negated by putting "not" in front of it.

 $sas->resetexpr;  \# resets filtering to standard pattern only

 $sas->excludesrc(@xylist);

 $sas->evtextract("outfile.fits",{ SELFREPLACE => 0 });
   \# SELFREPLACE=>1 replaces the main event file with the newly filtered one

 $sas->addbadpixels;

 $sas->mosaic\_attcalc;  \# needed for mosaic-mode data

 $sas->reproject($RA,$DEC);

 $sas->imgextract("outfile.fits",\[ {DETCOORDS=>1,
                                    BINSIZE=>32,
                                    XYIMGMINMAX=>\[$xmin,$xmax,$ymin,$ymax\]
                                   } \]);

 $sas->attitude($attfile);
 $sas->eexpmap($img,"outfile.fits",$pimin,$pimax,$opt);

 $expr = $sas->formatexpr; \# return selection expression used by
           \# evtextract and similars. Useful for debug purposes.


## Source detection

    use XMMSAS::Detect;
    my $sas = XMMSAS::Detect->new;

### Background fit

    $sas->img( $images );
    $sas->expmap( $expmaps );
    $sas->novign( $expmaps_novign );

    $sas->fitbkg;



### Detection

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



### Sensitivity maps

    $sas->expmap( $expmaps );
    $sas->bkg( $bkgs );

    $sas->make_srcmasks;
    $sas->fudge_obsid_instr_in_detmasks;
    $sas->sensmap( sprintf("sensmap-%s.fits",$sas->cellname) );
    $sas->esensmap;


# DESCRIPTION

See the documentation inside the modules themselves (XMMSAS-Extract.md
and XMMSAS-Detect.md).


# AUTHOR

Piero Ranalli   pranalli.github@gmail.com


# LICENSE AND COPYRIGHT

Copyright 2011-2014 Piero Ranalli.

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

