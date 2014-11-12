# NAME

XMMSAS::Extract  --  Perl interface to XMM-Newton SAS to extract data products

# VERSION

Version 2.01;

# SYNOPSIS

    my $sas = XMMSAS::Extract->new;

    $sas->evtfile("eventfile.fits");  # input evt

    my $boolean = $sas->camera_is_pn;    # boolean

    $sas->ccf("path/to/ccf.cif");    # provided by XMMSAS::Call

    $sas->odf("path/to/...SUM.SAS"); # provided by XMMSAS::Call

    $sas->attitude("path/to/...AttHk.fits");

    # $sas->verbose([01]); # set chatter level; default: 1

    $sas->addexpr('expr1','expr2',...); # adds filtering expressions

    $sas->add_predefined_expr($filter);
      # (or $sas->add_predefired_expr("not $filter");)
      # adds an expression from a library, appropriate for the camera.
      # For $filter, see B<EXPRESSION LIBRARY> below.
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

# DESCRIPTION

- setstdexpr()

    Sets standard PATTERN expressions appropriate for the camera.  (Not
    FLAG nor XMMEA, or the corner events would be lost).

    If you want also \#XMMEA and FLAG, use: $sas->add\_predefined\_expr('stdfilter')

# EXPRESSION LIBRARY

The actual expressions are different according to the camera.

- fov (ESAS)

    One (PN) or the union of more (MOS) circles.

- corners (ESAS)

    ! ( fov || a number of boxes for problematic detector regions )

- mfov, molendifov (De Luca & Molendi)

    Not a circle, but a corona: it excludes the inner 12'. Corners are
    excluded with (FLAG & 0x10000) == 0

- mcorners, molendicorners (De Luca & Molendi)

        PN:  ! ( ~esasfov )
        MOS: ! ( ~esasfov || boxes )

    In all cameras, FOV is also excluded with (FLAG & 0x10000) == 0.



- quad\[1-7\] (MOS), quad\[1-4\] (PN)       (ESAS)

    for the MOSes, quadrant==CCDNR. The regions are anyway defined in terms
    of BOXes.

- fulldef (ESAS)
- ruffovdef (ESAS)
- lowbkg (CDFS)

    Remove known instrumental lines.

        PN:  ! ((PI in [1450:1540])||(PI in [7200:7600])||(PI in [7800:8200]))
        MOS: ! (PI in [1450:1540])

- lowerbkg (CDFS)

    A more aggressive line removal than lowbkg.

        PN:  ! ((PI in [1390:1550])||(PI in [7350:7600])||(PI in [7840:8280])||(PI in [8540:9000]))
        MOS: ! ((PI in [1390:1550])||(PI in [1690:1800]))

- cuhole (CDFS)

    Like lowerkbg, but for the Cu complex (i.e. lines > 7 keV) in PN only
    the inner area where the lines are present is filtered out.

- stdfilter

        PN:  #XMMEA_EP && (PATTERN<=4) && (FLAG==0)
        MOS: #XMMEA_EM && (PATTERN<=12) && (FLAG==0)

# TODO

    # $sas->logfile([$file]); # set log to file (or to screen if file is not
                              # specified;  not yet implemented



# AUTHOR

Piero Ranalli   piero.ranalli (at) noa.gr

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

# HISTORY

1.0   2012/05       used for XMM-CDFS simulations
1.1   2012/07       added Cu-hole to the library
1.11  2013/08/04    added this history notice
1.2   2013/08/04    added XYIMGMINMAX and BINSIZE to imgextract()
                    added addbadpixels()
2.0   2013/08/08    refactored into XMMSAS::Extract with role XMMSAS::Exec
                    to allow XMMSAS::Detect to be put in the same distribution
2.01  2014/11/12    improved docs
