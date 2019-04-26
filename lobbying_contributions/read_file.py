import os
import xmltodict
import pprint
import csv

from xml.parsers.expat import ExpatError

YEAR_LIST = [2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019]
#YEAR_LIST = [2019,]

headers = ['type','contributorName','payeeName','recipientName','amount','date','filenum','source','filerType','organizationName','lobbyistPrefix','lobbyistFirstName','lobbyistMiddleName','lobbyistLastName','lobbyistSuffix','senateRegID','houseRegID','reportYear','reportType','amendment','signedDate','noContributions']

def readfile(filepath):
    infile = open(filepath, 'rb')
    try:
        parsed_file = xmltodict.parse(infile)
        return parsed_file

    except ExpatError:
        print("Parsing error in %s, ignoring" % filepath)
        return None


root_keys = {}
varlist = ['filerType', 'organizationName', 'lobbyistPrefix', 'lobbyistFirstName', 'lobbyistMiddleName', 'lobbyistLastName', 'lobbyistSuffix', 'senateRegID', 'houseRegID', 'reportYear', 'reportType', 'amendment', 'signedDate', 'noContributions']
contribvars = ['type','contributorName','payeeName','recipientName','amount','date']

arraytype = type([])



for YEAR in YEAR_LIST:

    OUTFILE_NAME = "lobbyist_contributions_ld-203_%s.csv" % YEAR
    outfile =  open(OUTFILE_NAME, 'w')
    print("Writing %s data out to %s" % (YEAR, OUTFILE_NAME))
    dw = csv.DictWriter(outfile, fieldnames=headers, extrasaction='ignore')
    dw.writeheader()
    total_files_parsed = 0

    for DIRNAME in ["%s_MidYear_XML" % YEAR, "%s_YearEnd_XML" % YEAR]:

        # traverse root directory, and list directories as dirs and files as files
        for root, dirs, files in os.walk(DIRNAME):
            path = root.split(os.sep)
            for file in files:
                filepath = os.path.join(root, file)
                parsed_file = readfile(filepath)
                total_files_parsed += 1
                if not parsed_file:
                    # a very small number of files break the xml parser, skip them
                    print("Couldn't parse file at %s" % filepath)
                    continue
                filenum = file.replace(".xml", "")

                this_row = {'filenum':filenum, 'source':root}
                for var in varlist:
                    this_row[var] = parsed_file['CONTRIBUTIONDISCLOSURE'][var]


                try:
                    nocontribs = parsed_file['CONTRIBUTIONDISCLOSURE']['noContributions']
                    if nocontribs == 'true':
                        continue
                except KeyError:
                    pass

                contributions = None
                try:
                    contributions = parsed_file['CONTRIBUTIONDISCLOSURE']['contributions']['contribution']
                except TypeError:
                    print("Contributions unparseable in %s, skipping" % filepath)
                    continue

                if type(contributions)!=arraytype:
                    contributions = [contributions]
                numcontribs = len(contributions)
                for i, tc in enumerate(contributions):

                    this_contrib = {}
                    nonecount = 0
                    for contribvar in contribvars:
                        this_contrib[contribvar] = tc[contribvar]
                        if tc[contribvar] == None:
                            nonecount += 1

                    if nonecount < 6:
                        this_contrib.update(this_row)
                        dw.writerow(this_contrib)

    print("Read %s files for %s" % (total_files_parsed, YEAR))
    outfile.close()




