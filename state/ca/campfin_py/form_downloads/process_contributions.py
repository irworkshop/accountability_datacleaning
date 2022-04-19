import csv, re, codecs


infiles = ["Form460ScheduleAItem.csv","Form460ScheduleCItem.csv", "Form460ScheduleIItem.csv"]
#infiles = ["Form460ScheduleCItem.csv", "Form460ScheduleIItem.csv"]

# headers from the raw files
raw_headers = ['id','line_item','amount', 'date_received','date_received_thru','transaction_type','transaction_id','memo_reference_number','contributor_code','contributor_committee_id','contributor_title','contributor_lastname','contributor_firstname','contributor_name_suffix','contributor_city','contributor_state','contributor_zip','contributor_employer','contributor_occupation','contributor_is_self_employed','intermediary_committee_id','intermediary_title','intermediary_lastname','intermediary_firstname','intermediary_name_suffix','intermediary_city','intermediary_state','intermediary_zip','intermediary_employer','intermediary_occupation','intermediary_is_self_employed','cumulative_ytd_amount','cumulative_election_amount','fair_market_value','contribution_description','receipt_description','filing_id']


# columns that we are going to join from filers
file_vars = ['filer_id', 'filer_firstname', 'filer_lastname', 'from_date', 'thru_date']

headers = raw_headers + file_vars


# wait is it latin1? should it be utf8? 
INPUT_ENCODING_STRING = "latin_1"



# hash the filings by filing_id so we can make lines searchable by the recipient
def get_filing_dict():
    filing_dict = {}
    print("Hashing filing details")
    filings_file = 'Form460Filing.csv'
    reader_fh = codecs.open(filings_file, 'rU', encoding=INPUT_ENCODING_STRING) 
    reader = csv.DictReader(reader_fh) 
    rowcount = 0
    for row in reader:
        rowcount += 1
        filing_dict[row['filing_id']] = {}
        for var in file_vars:
            filing_dict[row['filing_id']][var] = row[var]



    print("Read %s rows" % rowcount)
    return filing_dict
         



filing_dict = get_filing_dict()


outfile = 'CA_contributions.csv'
writer= csv.DictWriter(open(outfile, 'w'), headers, extrasaction='ignore')
writer.writeheader()

print("Writing output to %s" % outfile)

for infile in infiles: 

    count = 0

    print("Reading file %s " % infile)
    reader_fh = codecs.open(infile, 'rU', encoding=INPUT_ENCODING_STRING) 
    reader = csv.DictReader(reader_fh) 

    for i, line in enumerate(reader):
        
        count += 1
        if count % 100000 == 0:
            print("Read %s rows" % count)


        filing_id = line['filing_id']
        filing_details = None
        try:
            filing_details = filing_dict[filing_id]
        except KeyError:
            print("Couldn't find filing_id=%s" % filing_id)

        if filing_details:
            for var in file_vars:
                line[var] = filing_details[var]


        writer.writerow(line)

    print("Read a total of %s lines from %s" % (count, infile))

