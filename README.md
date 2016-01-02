
PFFT
====

PDF File Fixing Tool

Script to fix PDF file that wont open on non Windows platforms.
This most commonly occurs because of corrput/bad metadata or fonts.
This tool uses pdfseparate and pdfunite to split and re-unit file
into a PDF file that will open in viewer.

License
-------

This software is licensed as CC-BA (Creative Commons By Attrbution)

http://creativecommons.org/licenses/by/4.0/legalcode

Usage
-----

```
$ ./pfft.rb --help

Usage: ./pfft.rb

"--input",      "-i"  Input file
"--verbose",    "-v"  Verbose mode
"--version",    "-V"  Print version
"--help",       "-h"  Print usage
"--changelog",  "-c"  Output file
"--output",     "-o"  Output file
```

Example
-------

Fix input.pdf

```
$ ./pfft.rb --input=input.pdf --output=output.pdf
```

Fix input.pdf

```
$ ./pfft.rb --input=input.pdf
```