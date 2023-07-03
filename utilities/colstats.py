#!/usr/bin/python3

## Take a tab-delimited input and tally stats for given column
## Optionally output the unique values or the duplicate values found
##
## https://github.com/solesby
## (c) 2023 Adam Solesby

### command line option flags
### Actions
## default (output key stats)
## -u  output unique keys
## -d  output duplicate keys
## -o  output the first row for every key

### Options
## -s      sort keys
## -c      comma as delimiter
## -t      tab as delimiter
## -H      keep header
## -0...9  use column N for index
## -C      use clipboard for input (TBD)
## default (stdin using column 0)

import os, sys, fileinput

def log(*args): print(file=sys.stderr, *args)

def output(*args): print( *args )

def output_cols(*args): output( '\t'.join([ str(v) for v in args])  )

def clean(value):
    ## TODO: convert to int/float/date based on data type
    return value
    
def process(args):
    files         = []
    action_unique = False
    action_dupes  = False
    action_output = False
    opts_header   = True
    opts_index    = 0
    opts_sort     = False
    opts_delim    = '\t'

    ## Process command line options
    files = [ o for o in args if not o.startswith('-')]
    opts  = ''.join([ o for o in args if o.startswith('-') ]).replace('-','')
    if 'H' in opts: opts_header   = True ## default: no header
    if 's' in opts: opts_sort     = True ## default: not sorted
    if 'c' in opts: opts_delim    = ','  ## default: tab '\t'
    if 'u' in opts: action_unique = True ## output unique counts
    if 'd' in opts: action_dupes  = True ## output duplicate counts
    if 'o' in opts: action_output = True ## output rows / default: output stats
    for n in '0123456789':
        if n in opts: opts_index = int(n)
    log('>opts', opts, '>files', files)

    ## Tracking values
    counts    = {}    ## how many times value has been seen
    first     = {}    ## first lineno appeared
    last      = {}    ## last lineno appeared
    first_row = {}    ## first row with this key
    last_row  = {}    ## last row with this key
    minimum   = None  ## minimum value seen
    maximum   = None  ## maximum value seen
    total     = 0     ## total row count
    header    = ''    ## save the header row

    log('>process', files)

    for line in fileinput.input(files=files):
        line   = line.rstrip('\n')
        lineno = fileinput.lineno()
        vals   = line.split(opts_delim)
        index  = clean( vals[opts_index] )
        # log(fileinput.lineno(), line)

        if not line: continue ## skip blank lines

        if opts_header and not header:
            header = line
            continue

        ## initialize stats
        if index not in counts    : counts[index]     = 0;
        if index not in first     : first[index]      = lineno;
        if index not in last      : last[index]       = lineno;
        if index not in first_row : first_row[index]  = line;
        if index not in last_row  : last_row[index]   = line;
        if not minimum            : minimum = index
        if not maximum            : maximum = index

        ## tally stats
        total          += 1
        counts[index]  += 1
        last[index]     = lineno
        last_row[index] = line
        minimum         = min(minimum, index)
        maximum         = max(maximum, index)

    # log('>counts  ', counts  )
    # log('>first   ', first   )
    # log('>last    ', last    )
    # log('>minimum ', minimum )
    # log('>maximum ', maximum )
    # log('>total   ', total   )
    # log('>header  ', header  )

    uniques = counts.keys() ## default: order in file
    if opts_sort:
        uniques = sorted(uniques)

    if action_output:
        if header: output(header)
        for k in uniques:
            if action_dupes and counts[k] == 1: continue
            output( first_row[k] )
        log('Duplicates' if action_dupes else 'Uniques', '(to file)')
        for k in uniques:
            if action_dupes and counts[k] == 1: continue
            log( k, counts[k], first[k], last[k] )

    elif action_dupes or action_unique:
        output('Duplicates' if action_dupes else 'Uniques')
        for k in uniques:
            if action_dupes and counts[k] == 1: continue
            # log( k, counts[k], first[k], last[k] )
            output_cols( k, counts[k] )

    else: ## default show stats
        output('Statistics')
        output_cols('value','first_row','last_row')
        for k in uniques:
            output_cols( k, counts[k], first[k], last[k])
        output_cols('minimum', minimum)
        output_cols('maximum', maximum)
        output_cols('total', total)
                    
if __name__ == '__main__':
    process( sys.argv[1:] )
