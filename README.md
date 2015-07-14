# css-updater
Manipulate your CSS or LESS files en mass!

## Usage

```
$ ./css-updater.pl <folder> <folder> <file> <file>
```
_Example_

    Run on an entire directory:
    $ ./css-updater.pl ~/myFolder/
    
    Run on a single file:
    $ ./css-updater.pl ~/myFolder/TheBestCSSFileEver.css
    
    Run on several folders and a file:
    $ ./css-updater.pl ~/myFolder/ ~/myOtherFolder/ ~/SomeoneElsesFolder/NotTheBestCSSFileEver.css
    
    Run with switches:
    $ ./css-updater.pl ~/myFolder/ --dry-run --scale 1.5 --factor 3 -v


## Useful Switches
Below are the supported options.
### Dry-run
    -d or --dry-run
Run in pretend mode, and don't modify any files.

### Scale All Values
    -s or --scale
Supply a value, and all pixel values will be multiplied by this number. Float values are acceptable. (Default: 1)
                          
### Minimum Unit Value
    -m or --min
The minumum value to not modify. (Default: 1.5)
    
### Rounding Factor
    -f or --factor
The rounding value, to which all numbers should be rounded to the nearest. (Default: 3)
                          
### Processed Files Suffix
    --processed-suffix
This string will be appended to the end of processed filenames. (Default: "-updated")

## Less Useful Switches
### Verbose Mode
    -v or --verbose
Turn on verbose output, show everything we are doing.

### Help!
    -h or --help
Show this help.