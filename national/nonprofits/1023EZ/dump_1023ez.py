import csv

infiles = {
    2014: ['f1023ez_approvals_2014.csv',],   
    2015: ['f1023ez_approvals_2015.csv',],   
    2016: ['f1023ez_approvals_2016.csv',],   
    2017: ['f1023ez_approvals_2017.csv',], 
    2018: ['f1023ez_approvals_2018.csv',], 
    2019: ['f1023ez_approvals_2019_jan_mar.csv',],
}

NON_REPEATING_ROWS = ['EIN','Case Number','Orgname1','Orgname2','Address','City','State','Zip','Zippl4','Accountingperiodend','Primarycontactname','Primarycontactphone','Primarycontactphoneext','Orgurl','Orgemail','Orgtypecorp','Orgtypeunincorp','Orgtypetrust', 'Incorporateddate','Incorporatedstate', 'Nteecode',]

# need to add row number 1-5 for these. 
REPEATING_ROWS = ["Ofcrdirtrust%sfirstname","Ofcrdirtrust%slastname","Ofcrdirtrust%stitle","Ofcrdirtrust%sstreetaddr","Ofcrdirtrust%scity","Ofcrdirtrust%sstate","Ofcrdirtrust%szip","Ofcrdirtrust%szippl4"]

# In the output file we'll use the filenames minus the number
REPEATING_ROW_NAMES = [ i % "" for i in REPEATING_ROWS]

OUTFIELDNAMES = ['year'] + NON_REPEATING_ROWS + REPEATING_ROW_NAMES
OUTFILE_NAME = '1023ez.csv'

def clean_ein(ein_raw):
    return ein_raw.replace("-", "")

def getbaserows(dict):
    newdict = {}
    for field in NON_REPEATING_ROWS:
        try:
            newdict[field] = dict[field]
        except KeyError:
            newdict[field] = ''
    return newdict

def getnumberedrows(i, dict):
    newdict = {}
    total_length = 0

    for field in REPEATING_ROWS:
        thisfieldnameraw = field % i
        outfieldname = field % ""
        try:
            newdict[outfieldname] = dict[thisfieldnameraw]
            total_length += len(dict[thisfieldnameraw])
        except KeyError:
            newdict[outfieldname] = ''

    if total_length > 4:
        return newdict
    else:
        return None


def process_infile(year, infilelocation, dictwriter):
    print("processing infile %s" % (infilelocation))
    with open(infilelocation) as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            base_row = getbaserows(row)
            for i in range(1,6):
                this_numbered_row = getnumberedrows(i, row)
                if this_numbered_row:
                    this_numbered_row.update(base_row)
                    this_numbered_row['year'] = year
                    this_numbered_row['EIN'] = clean_ein(this_numbered_row['EIN'])
                    dictwriter.writerow(this_numbered_row)



if __name__ == '__main__':

    with open(OUTFILE_NAME, 'w') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=OUTFIELDNAMES)
        writer.writeheader()

        for year in infiles.keys():
            year_files = infiles[year]
            for year_file in year_files:
                process_infile(year, year_file, writer)

        print("Output written to %s" % OUTFILE_NAME)