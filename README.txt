README
------

xdict v0.2.0

Homepage:

    https://github.com/srirangav/xdict

About:

xdict is a MacOSX command line program for accessing the MacOSX 
dictionary. 

Usage:

    xdict [-l] | [-d [dictionary] [-c [command]] [word]

    If -l is specified, xdict lists all available dictionaries.

    If -d is specified, xdict will try to use the specified
    [dictionary] to look up the specified [word]. 

    if -c is specified, xdict will execute one of the following
    commands:

    'h' or 'headword' - prints the headword only
    'm' or 'html'     - prints the html version of the defintion
    'r' or 'raw'      - prints the raw version of the definition
                        (by default xdict tries to format the 
                         definition)

    The -c option is ignored unless -d is also specified.

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

    v. 0.2.0 - add commands and format definitions
    v. 0.1.0 - initial release

Platforms:

    xdict has been tested on MacOSX 11 (BigSur) on M1.  

License:

    See LICENSE.txt

