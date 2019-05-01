import csv, re, codecs

infile = "Output/PropertyProfile.txt"

def get_writer(outfile, headers):
    headers = headers + ['situs_state']
    outfilehandle = open(outfile, 'w')
    dw = csv.DictWriter(outfilehandle, headers, extrasaction='ignore')
    dw.writeheader()
    return dw

reader_fh = codecs.open(infile, 'rU', encoding="latin_1") 
reader = csv.DictReader((l.replace('\0', '') for l in reader_fh), delimiter='\t') # deal with null bytes?
outfile = 'fulton_co_ga_properties.csv'
print("Writing output to %s" % outfile)

writer = None
fieldnames = None
for i, line in enumerate(reader):
    line['situs_state'] = 'GA'
    if not fieldnames:
        fieldnames = reader.fieldnames
        writer = get_writer(outfile, fieldnames)
    writer.writerow(line)
