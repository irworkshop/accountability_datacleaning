import csv, re, codecs

infiles =['Ottawa_OH_raw.csv',]

outfile = 'Ottawa_OH.csv'

def get_writer(outfile, headers):
    headers = headers + ['prop_state']
    print(headers)
    outfilehandle = open(outfile, 'w')
    dw = csv.DictWriter(outfilehandle, headers, extrasaction='ignore')
    dw.writeheader()
    return dw




writer = None
fieldnames = None

for infile in infiles:

    reader_fh = codecs.open(infile, 'rU', encoding="latin_1") 
    reader = csv.DictReader(reader_fh) 
    print("Reading from %s writing to %s" % (infile, outfile))


    for i, line in enumerate(reader):
        line['prop_state'] = 'OH'
        if not fieldnames:
            fieldnames = reader.fieldnames
            writer = get_writer(outfile, fieldnames)
        writer.writerow(line)


        