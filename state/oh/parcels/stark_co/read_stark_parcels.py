import csv, re, codecs

infiles =['Stark_OH_raw.csv',]

outfile = 'Stark_OH.csv'

def get_writer(outfile, headers):
    headers = headers + ['SITUS_STATE', 'SITUS_ZIP', 'BILL_CITY', 'BILL_STATE', 'BILL_ZIP']
    print(headers)
    outfilehandle = open(outfile, 'w')
    dw = csv.DictWriter(outfilehandle, headers, extrasaction='ignore')
    dw.writeheader()
    return dw



STATE_ZIP_RE = re.compile(r'(.+?)\s+([A-Z]{2})\s+(\d\d\d\d\d)\s*')

writer = None
fieldnames = None

for infile in infiles:

    reader_fh = codecs.open(infile, 'rU', encoding="latin_1") 
    reader = csv.DictReader(reader_fh) 
    print("Reading from %s writing to %s" % (infile, outfile))


    for i, line in enumerate(reader):
        
        ## DEAL WITH SITE ADDRESS
        parts = line['SITUS_ADDR'].split("OH")
        line['SITUS_STATE'] = 'OH'
        try:
            parts[1]
            line['SITUS_ADDR'] = parts[0].strip()
            line['SITUS_ZIP'] = parts[1].strip()
        except IndexError:
            pass


        



        #print(line)
        found_in_2 = False
        matches = re.search(STATE_ZIP_RE, line['BILLING__2'])
        if matches:
            line['BILL_CITY'] = matches.group(1).strip()
            line['BILL_STATE'] = matches.group(2).strip()
            line['BILL_ZIP'] = matches.group(3).strip()
            found_in_2 = True
            #print("Got city %s state %s zip %s from %s" % (city, state, zip, line['BILLING__2']))
        else:
            #print("No match in %s" % line['BILLING__2'])
            pass

        # if we can't parse this entry, it might be in billing_3 instead
        if not found_in_2:
            matches = re.search(STATE_ZIP_RE, line['BILLING__3'])
            
            if matches:
                line['BILL_CITY'] = matches.group(1).strip()
                line['BILL_STATE'] = matches.group(2).strip()
                line['BILL_ZIP'] = matches.group(3).strip()
                found_in_2 = True
                #print("Got from Billing_3: city %s state %s zip %s from %s" % (city, state, zip, line['BILLING__3']))
            else:
                print("No 3 match in %s" % line['BILLING__3'])



        if not fieldnames:
            fieldnames = reader.fieldnames
            writer = get_writer(outfile, fieldnames)
        writer.writerow(line)


        