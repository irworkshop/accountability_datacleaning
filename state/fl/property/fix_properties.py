import csv, re, codecs

infile = "fl_properties.csv"

def get_writer(outfile, headers):
    headers = headers + ['PHY_STATE']
    outfilehandle = open(outfile, 'w')
    dw = csv.DictWriter(outfilehandle, headers, extrasaction='ignore')
    dw.writeheader()
    return dw

#reader_fh = codecs.open(infile, 'rU', encoding="latin_1") 
reader_fh = codecs.open(infile, 'r')
reader = csv.DictReader(reader_fh)
outfile = 'cleaned_fl_properties.csv'

writer = None
fieldnames = None
for i, line in enumerate(reader):
    line['PHY_STATE'] = 'FL'
    if not fieldnames:
        fieldnames = reader.fieldnames
        writer = get_writer(outfile, fieldnames)
    writer.writerow(line)