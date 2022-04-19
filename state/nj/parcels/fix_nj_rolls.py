# Add the municipal code to the file. 

import csv, re
from nj_muni_codes import muni_codes

infile =  "ModIVNJ17.csv"


reader_fh = open(infile, 'r') # use kwarg encoding='VERBATIM_ENCODING'
reader = csv.DictReader(reader_fh)

outfile = 'nj_rolls_2017.csv'
print("Writing output to %s" % outfile)

fieldnames = None

CITY_STATE_REGEX = re.compile(r'(.+?)\,*\s+([A-Z]{2})\s*\Z')

def get_writer(outfile, headers):
    headers = headers + ['state', 'municipality', 'owner_state', 'owner_city_only']
    outfilehandle = open(outfile, 'w')
    dw = csv.DictWriter(outfilehandle, headers, extrasaction='ignore')
    dw.writeheader()
    return dw


writer = None
total_lines = None
regex_failed = 0

for linecount, line in enumerate(reader):


    total_lines = linecount

    # The situs state is NJ, but this is left out
    line['state'] = 'NJ'
    code = line['muncode']
    try:
        line['municipality'] = muni_codes[code]
    except KeyError:
        print("No muni for code '%s'" % code)


    try:
        owner_city = line['owner_city']
        # add a space after commas, sometimes this is omitted
        owner_city = owner_city.replace(",", ", ")
        owner_city = owner_city.replace("NEW JERSEY", "NJ")
        owner_city = owner_city.replace(".", "")

        owner_city = owner_city.replace("N J", "NJ") # happens a lot?
        owner_city = owner_city.replace("N Y", "NY") # happens a lot?
        owner_city = owner_city.replace("M A", "MA") # happens a lot?
        owner_city = owner_city.replace("FLORIDA", "FL") # happens a lot?


        result = re.match(CITY_STATE_REGEX, owner_city)
        if result:
            line['owner_state'] = result.group(2)
            line['owner_city_only'] = result.group(1)
        else:
            # Show regex failures, there are about 
            #print("no match on regex for '%s'" % owner_city)
            regex_failed += 1

    except KeyError:
        line['owner_city_only'] = line['owner_city']
        line['owner_city_only'] = line['owner_city_only'].replace("NJ", "")


    if not fieldnames:
        fieldnames = reader.fieldnames
        writer = get_writer(outfile, fieldnames)

    writer.writerow(line)

print("Total of %s lines written" % total_lines)
print("City, state extraction using regex failed in %s lines" % regex_failed)
