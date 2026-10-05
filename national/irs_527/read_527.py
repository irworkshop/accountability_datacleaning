import csv

file_location = "FullDataFile.txt"

# latin-1, not utf-8. The IRS file is mixed: of 646 non-ASCII bytes in 2.7GB,
# about 94 are genuine utf-8 sequences (0xc2 0xae = (R), 0xc2 0xa0 = nbsp) while
# the rest are bare latin-1 bytes (a lone 0xae, 0xa0, 0xe9...). No single codec
# is "correct", so read with the one that cannot fail: latin-1 maps all 256 byte
# values, so decoding never raises. The cost is that those ~94 utf-8 sequences
# come through as mojibake ("A(R)" rather than "(R)") -- 94 characters out of
# 2.9 billion. Anything stricter dies partway, which is what utf-8 was doing.
infile = open(file_location, 'r', encoding='latin-1')

DIRECTOR_HEADERS = ['record_type', 'form_id', 'director_id', 'org_name', 'ein', 'entity_name', 'entity_title', 'entity_address_1', 'entity_address_2', 'entity_address_city', 'entity_address_st', 'entity_address_zip_code', 'entity_address_zip_code_ext']
RELATED_HEADERS = ['record_type', 'form_id_number', 'entity_id', 'org_name', 'ein', 'entity_name', 'entity_relationship', 'entity_address_1', 'entity_address_2', 'entity_address_city', 'entity_address_st', 'entity_address_zip_code', 'entity_address_zip_ext']
FORM_8871_HEADERS = ['record_type', 'form_type', 'form_id_number', 'initial_report_indicator', 'amended_report_indicator', 'final_report_indicator', 'ein', 'organization_name', 'mailing_address_1', 'mailing_address_2', 'mailing_address_city', 'mailing_address_state', 'mailing_address_zip_code', 'mailing_address_zip_ext', 'e_mail_address', 'established_date', 'custodian_name', 'custodian_address_1', 'custodian_address_2', 'custodian_address_city', 'custodian_address_state', 'custodian_address_zip_code', 'custodian_address_zip_ext', 'contact_person_name', 'contact_address_1', 'contact_address_2', 'contact_address_city', 'contact_address_state', 'contact_address_zip_code', 'contact_address_zip_ext', 'business_address_1', 'business_address_2', 'business_address_city', 'business_address_state', 'business_address_zip_code', 'business_address_zip_ext', 'exempt_8872_indicator', 'exempt_state', 'exempt_990_indicator', 'purpose', 'material_change_date', 'insert_datetime', 'related_entity_bypass', 'eain_bypass']
FORM_8872_HEADERS = ['record_type', 'form_type', 'form_id_number', 'period_begin_date', 'period_end_date', 'initial_report_indicator', 'amended_report_indicator', 'final_report_indicator', 'change_of_address_indicator', 'organization_name', 'ein', 'mailing_address_1', 'mailing_address_2', 'mailing_address_city', 'mailing_address_state', 'mailing_address_zip_code', 'mailing_address_zip_ext', 'e_mail_address', 'org_formation_date', 'custodian_name', 'custodian_address_1', 'custodian_address_2', 'custodian_address_city', 'custodian_address_state', 'custodian_address_zip_code', 'custodian_address_zip_ext', 'contact_person_name', 'contact_address_1', 'contact_address_2', 'contact_address_city', 'contact_address_state', 'contact_address_zip_code', 'contact_address_zip_ext', 'business_address_1', 'business_address_2', 'business_address_city', 'business_address_state', 'business_address_zip_code', 'business_address_zip_ext', 'qtr_indicator', 'monthly_rpt_month', 'pre_elect_type', 'pre_or_post_elect_date', 'pre_or_post_elect_state', 'sched_a_ind', 'total_sched_a', 'sched_b_ind', 'total_sched_b', 'insert_datetime']
EAIN_HEADERS = ['record_type','form_id','eain_id','election_authority_id_number', 'state_issued']
A_HEADERS = ['record_type', 'form_id_number', 'sched_a_id', 'org_name', 'ein', 'contributor_name', 'contributor_address_1', 'contributor_address_2', 'contributor_address_city', 'contributor_address_state', 'contributor_address_zip_code', 'contributor_address_zip_ext', 'contributor_employer', 'contribution_amount', 'contributor_occupation', 'agg_contribution_ytd', 'contribution_date']
B_HEADERS = ['record_type', 'form_id_number', 'sched_b_id', 'org_name', 'ein', 'recipient_name', 'recipient_address_1', 'recipient_address_2', 'recipient_address_city', 'recipient_address_st', 'recipient_address_zip_code', 'recipient_address_zip_ext', 'recipient_employer', 'expenditure_amount', 'recipient_occupation', 'expenditure_date', 'expenditure_purpose']

# A D record carries no date of its own -- a director is simply attached to a
# filing. It does carry form_id, which matches form_id_number on the Form 8871
# ('1') record, and that has insert_datetime: when the IRS recorded the filing.
# That is the right proxy for "when was this person a director", because each
# filing is a snapshot of the roster, so someone serving several years appears
# on several forms, each with its own date.
#
# Deliberately NOT established_date: that is when the *organisation* was founded,
# not when the filing happened, and joining on it yields directors in 1808.
#
# R and E records share the same form_id link and could get the same treatment,
# but neither is published, so they are left alone.
FILING_DATE_HEADERS = ['filing_date', 'filing_year']
DATE_LINKED_TYPES = ('D',)

# form_id sits at position 1 on a D record.
FORM_ID_POSITION = 1

# Positions within an 8871 record, derived rather than hardcoded so they follow
# FORM_8871_HEADERS if it is ever corrected.
FORM_8871_ID_POSITION = FORM_8871_HEADERS.index('form_id_number')
FORM_8871_DATE_POSITION = FORM_8871_HEADERS.index('insert_datetime')

writer_dict = {
    'A':{'headers':A_HEADERS},
    'B':{'headers':B_HEADERS},
    '1':{'headers':FORM_8871_HEADERS},
    '2':{'headers':FORM_8872_HEADERS},
    'D':{'headers':DIRECTOR_HEADERS},
    'R':{'headers':RELATED_HEADERS},
    'E':{'headers':EAIN_HEADERS},

}

for recordtype in writer_dict.keys():
    outfile_name = "527read_%s.csv" % recordtype
    # Explicit encoding so output doesn't depend on the machine's locale, and
    # newline='' because the csv module handles line endings itself.
    outfile =  open(outfile_name, 'w', encoding='utf-8', newline='')
    # source_headers maps the pipe-delimited fields positionally; output_headers
    # adds the joined filing date, which has no position in the source record.
    source_headers = writer_dict[recordtype]['headers']
    output_headers = list(source_headers)
    if recordtype in DATE_LINKED_TYPES:
        output_headers += FILING_DATE_HEADERS
    writer_dict[recordtype]['source_headers'] = source_headers
    dw = csv.DictWriter(outfile, fieldnames=output_headers, extrasaction='ignore')
    dw.writeheader()
    writer_dict[recordtype]['writer'] = dw
    print("Writing row type %s to file %s" % (recordtype, outfile_name))


def build_form_date_index(path):
    """Pass one: form_id_number -> insert_datetime, from the 8871 records.

    A separate pass because a D record can appear before the '1' record it
    belongs to, so the lookup has to be complete before any D row is written.
    Cheap: ~78k entries, and a scan of the file takes a few seconds.
    """
    index = {}
    with open(path, 'r', encoding='latin-1') as form_file:
        for line in form_file:
            if not line.startswith('1|'):
                continue
            values = line.rstrip('\n').split('|')
            if len(values) <= FORM_8871_DATE_POSITION:
                continue
            index[values[FORM_8871_ID_POSITION]] = values[FORM_8871_DATE_POSITION].strip()
    print("Indexed %s Form 8871 filing dates" % len(index))
    return index


FORM_DATE_INDEX = build_form_date_index(file_location)


def make_dict(headers, array):
    new_dict = {}
    for i, header in enumerate(headers):
        try:
            new_dict[header]=array[i] 
        except IndexError:
            pass
    return new_dict


def handle_row(recordtype, value_array):
    this_row = make_dict(writer_dict[recordtype]['source_headers'], value_array)

    if recordtype in DATE_LINKED_TYPES:
        form_id = value_array[FORM_ID_POSITION] if len(value_array) > FORM_ID_POSITION else ''
        filing_date = FORM_DATE_INDEX.get(form_id, '')
        this_row['filing_date'] = filing_date
        # insert_datetime looks like '2001-05-13 21:20:54', so the year is the
        # first four characters. Left blank rather than guessed when absent.
        this_row['filing_year'] = filing_date[:4] if filing_date else ''

    writer_dict[recordtype]['writer'].writerow(this_row)


count = {
    'H':0,
    'D':0,
    'R':0,
    '1':0,
    '2':0,
    'E':0,
    'B':0,
    'A':0,
    'problem':0,
}

badlines = open("bad.txt", 'w')
total_count = 0

for i, row in enumerate(infile):
    # Replace internal newlines if we encounter them
    row = row.replace("\n"," ")
    total_count = i

    # The files are bar delimited
    values = row.split("|")
    rowtype = values[0]
    
    try:
        count[rowtype] += 1
    except KeyError:
        badlines.write("%s|%s\n" % (i, row))
        count['problem'] += 1
        continue

    if rowtype in ['A', 'B', 'D', 'R', '1', '2', 'E']:
        handle_row(rowtype, values)

    # ignore the header or file end records
    elif rowtype in ['H', 'F']:
        pass

    else:
        print("illegal rowtype %s" )



print("Processed a total of %s lines. Wrote summary of unreadable lines to bad.txt." % total_count) 
print("Summary of lines by type: %s" % count)

