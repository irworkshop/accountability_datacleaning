import csv, re, codecs

infile = "ny_parcels_2018_raw.csv"

outfile = 'ny_parcels_2018_output.csv'

writer = None
BASE_FIELDS = ['COUNTY_NAME','MUNI_NAME','PARCEL_ADDR','CITYTOWN_NAME','LOC_ST_NBR','LOC_STREET','LOC_UNIT','LOC_ZIP','PROP_CLASS','ROLL_SECTION','LAND_AV','TOTAL_AV','FULL_MARKET_VAL','YR_BLT','FRONT','DEPTH','SQ_FT','ACRES','SCHOOL_NAME','BLDG_STYLE_DESC','SQFT_LIVING','NBR_KITCHENS','NBR_FULL_BATHS','NBR_BEDROOMS','USED_AS_DESC','BOOK','PAGE','GRID_EAST','GRID_NORTH','MUNI_PARCEL_ID','ROLL_YR','OWNER_TYPE','CALC_ACRES']

OWNER_FIELDS = ['OWNER','MAIL_ADDR','PO_BOX','MAIL_CITY','MAIL_STATE','MAIL_ZIP']

fieldnames = ['STATE'] + BASE_FIELDS + OWNER_FIELDS


def copy_fields(base_dict, field_list, new_dict):
    for field in field_list:
        try:
            new_dict[field] = base_dict[field]
        except KeyError:
            print("Key Error: %s in base_dict %s" % (field, base_dict))
            pass
    return new_dict

def get_writer(outfile, headers):
    outfilehandle = open(outfile, 'w')
    dw = csv.DictWriter(outfilehandle, headers, extrasaction='ignore')
    dw.writeheader()
    return dw

print("Writing output to outfile %s" % outfile)
writer = get_writer(outfile, fieldnames)

reader_fh = codecs.open(infile) 
reader = csv.DictReader(reader_fh) # deal with null bytes?


for i, line in enumerate(reader):
    
    line_base = {'STATE':'NY'}
    line_base = copy_fields(line, BASE_FIELDS, line_base)

    owner1 = line_base
    owner1['OWNER'] = line['PRIMARY_OWNER']
    owner1 = copy_fields(line, ['MAIL_ADDR','PO_BOX','MAIL_CITY','MAIL_STATE','MAIL_ZIP'], owner1)
    writer.writerow(owner1)


    if line['ADD_OWNER']:
        owner2 = line_base
        owner2['OWNER'] = line['ADD_OWNER']
        owner2['MAIL_ADDR'] = line['ADD_MAIL_ADDR']
        owner2['PO_BOX'] = line['ADD_MAIL_PO_BOX']
        owner2['MAIL_CITY'] = line['ADD_MAIL_CITY']
        owner2['MAIL_STATE'] = line['ADD_MAIL_STATE']
        owner2['MAIL_ZIP'] = line['ADD_MAIL_ZIP']
        writer.writerow(owner2)
