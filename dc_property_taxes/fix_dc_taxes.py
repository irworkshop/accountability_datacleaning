import csv

infile = "Integrated_Tax_System_Public_Extract_Facts.csv"
outfile = 'dc_tax_extract_cleaned.csv'

print("Writing output to %s" % outfile)

def get_writer(outfile, headers):

    # Add fields for city and state of the site and distinct columns for owner city state and zip
    headers = headers + ['site_state', 'site_city', 'OWNER_CITY', 'OWNER_STATE', 'OWNER_ZIP']

    outfilehandle = open(outfile, 'w')
    dw = csv.DictWriter(outfilehandle, headers, extrasaction='ignore')
    dw.writeheader()
    return dw


fieldnames = None
writer = None


reader_fh = open(infile, 'r') 
reader = csv.DictReader(reader_fh)

for line in reader:

    line['site_state'] = 'DC'
    line['site_city'] = 'Washington'


    owner_city = None
    owner_state = None
    owner_zip = None

    owner_csz = line['OWNER_ADDRESS_CITYSTZIP']
    owner_csz_parts = owner_csz.split("              ")
    owner_csz_parts = [i.strip() for i in owner_csz_parts]
    owner_city = owner_csz_parts[0]
    if len(owner_csz_parts) > 1:
        state_zip = owner_csz_parts[1]
        state_zip_parts = state_zip.split(" ")
        owner_state = state_zip_parts[0]
        if len(state_zip_parts) > 1:
            owner_zip = state_zip_parts[1]

    line['OWNER_CITY'] = owner_city
    line['OWNER_STATE'] = owner_state
    line['OWNER_ZIP'] = owner_zip

    if not fieldnames:
        fieldnames = reader.fieldnames
        writer = get_writer(outfile, fieldnames)

    writer.writerow(line)
