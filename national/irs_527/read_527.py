import csv

file_location = "FullDataFile.txt"

infile = open(file_location, 'r')

DIRECTOR_HEADERS = ['record_type', 'form_id', 'director_id', 'org_name', 'ein', 'entity_name', 'entity_title', 'entity_address_1', 'entity_address_2', 'entity_address_city', 'entity_address_st', 'entity_address_zip_code', 'entity_address_zip_code_ext']
RELATED_HEADERS = ['record_type', 'form_id_number', 'entity_id', 'org_name', 'ein', 'entity_name', 'entity_relationship', 'entity_address_1', 'entity_address_2', 'entity_address_city', 'entity_address_st', 'entity_address_zip_code', 'entity_address_zip_ext']
FORM_8871_HEADERS = ['record_type', 'form_type', 'form_id_number', 'initial_report_indicator', 'amended_report_indicator', 'final_report_indicator', 'ein', 'organization_name', 'mailing_address_1', 'mailing_address_2', 'mailing_address_city', 'mailing_address_state', 'mailing_address_zip_code', 'mailing_address_zip_ext', 'e_mail_address', 'established_date', 'custodian_name', 'custodian_address_1', 'custodian_address_2', 'custodian_address_city', 'custodian_address_state', 'custodian_address_zip_code', 'custodian_address_zip_ext', 'contact_person_name', 'contact_address_1', 'contact_address_2', 'contact_address_city', 'contact_address_state', 'contact_address_zip_code', 'contact_address_zip_ext', 'business_address_1', 'business_address_2', 'business_address_city', 'business_address_state', 'business_address_zip_code', 'business_address_zip_ext', 'exempt_8872_indicator', 'exempt_state', 'exempt_990_indicator', 'purpose', 'material_change_date', 'insert_datetime', 'related_entity_bypass', 'eain_bypass']
FORM_8872_HEADERS = ['record_type', 'form_type', 'form_id_number', 'period_begin_date', 'period_end_date', 'initial_report_indicator', 'amended_report_indicator', 'final_report_indicator', 'change_of_address_indicator', 'organization_name', 'ein', 'mailing_address_1', 'mailing_address_2', 'mailing_address_city', 'mailing_address_state', 'mailing_address_zip_code', 'mailing_address_zip_ext', 'e_mail_address', 'org_formation_date', 'custodian_name', 'custodian_address_1', 'custodian_address_2', 'custodian_address_city', 'custodian_address_state', 'custodian_address_zip_code', 'custodian_address_zip_ext', 'contact_person_name', 'contact_address_1', 'contact_address_2', 'contact_address_city', 'contact_address_state', 'contact_address_zip_code', 'contact_address_zip_ext', 'business_address_1', 'business_address_2', 'business_address_city', 'business_address_state', 'business_address_zip_code', 'business_address_zip_ext', 'qtr_indicator', 'monthly_rpt_month', 'pre_elect_type', 'pre_or_post_elect_date', 'pre_or_post_elect_state', 'sched_a_ind', 'total_sched_a', 'sched_b_ind', 'total_sched_b', 'insert_datetime']
EAIN_HEADERS = ['record_type','form_id','eain_id','election_authority_id_number', 'state_issued']
A_HEADERS = ['record_type', 'form_id_number', 'sched_a_id', 'org_name', 'ein', 'contributor_name', 'contributor_address_1', 'contributor_address_2', 'contributor_address_city', 'contributor_address_state', 'contributor_address_zip_code', 'contributor_address_zip_ext', 'contributor_employer', 'contribution_amount', 'contributor_occupation', 'agg_contribution_ytd', 'contribution_date']
B_HEADERS = ['record_type', 'form_id_number', 'sched_b_id', 'org_name', 'ein', 'recipient_name', 'recipient_address_1', 'recipient_address_2', 'recipient_address_city', 'recipient_address_st', 'recipient_address_zip_code', 'recipient_address_zip_ext', 'recipient_employer', 'expenditure_amount', 'recipient_occupation', 'expenditure_date', 'expenditure_purpose']

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
    outfile =  open(outfile_name, 'w')
    dw = csv.DictWriter(outfile, fieldnames=writer_dict[recordtype]['headers'], extrasaction='ignore')
    dw.writeheader()
    writer_dict[recordtype]['writer'] = dw
    print("Writing row type %s to file %s" % (recordtype, outfile_name))


def make_dict(headers, array):
    new_dict = {}
    for i, header in enumerate(headers):
        try:
            new_dict[header]=array[i] 
        except IndexError:
            pass
    return new_dict


def handle_row(recordtype, value_array):
    this_row = make_dict(writer_dict[recordtype]['headers'], value_array)
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

