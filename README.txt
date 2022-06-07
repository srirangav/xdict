README
------

xdict v0.1.0

Homepage:

    https://github.com/srirangav/xdict

About:

xdict is a MacOSX command line program for accessing the MacOSX 
dictionary. 

Usage:

    xdict [-l] | [-d [dictionary]] [word]

    If -l is specified, xdict lists all available dictionaries.

    If -d is specified, xdict will try to use the specified
    [dictionary] to look up the specified [word]. 

Build:

    $ ./configure
    $ make

Install:

    $ ./configure
    $ make
    $ make install

    By default, xdict is installed in /usr/local/bin.  To install
    it in a different location, the alternate installation prefix
    can be supplied to configure:

        $ ./configure --prefix="<prefix>"

    or, alternately to make:

        $ make install PREFIX="<prefix>"

    For example, the following will install xdict in /opt/local:

        $ make PREFIX=/opt/local install

    A DESTDIR can also be specified for staging purposes (with or
    without an alternate prefix):

        $ make DESTDIR="<destdir>" [PREFIX="<prefix>"] install

Dependencies:

   xdict relies on DictionaryServices, which are available on 
   MacOSX 10.5 (Leopard) and newer:

   https://developer.apple.com/documentation/coreservices/1446842-dcscopytextdefinition?language=objc

History:

    v. 0.1.0 - initial release

Platforms:

    xdict has been tested on MacOSX 11 (BigSur) on M1.  

License:

    See LICENSE.txt

