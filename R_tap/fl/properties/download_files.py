
## After downloading the files, you can unzip and stack with
## csvstack files/*.csv > fl_properties.csv
## then run the fix_properties.py script (fix paths)

import os

filenames = ['Alachua 11 Final NAL 2018.zip', 'Baker 12 Final NAL 2018.zip', 'Bay 13 Final NAL 2018.zip', 'Bradford 14 Final NAL 2018.zip', 'Brevard 15 Final NAL 2018.zip', 'Broward 16 Final NAL 2018.zip', 'Calhoun 17 Final NAL 2018.zip', 'Charlotte18 Final NAL 2018.zip', 'Citrus 19 Final NAL 2018.zip', 'Clay 20 Final NAL 2018.zip', 'Collier 21 Final NAL 2018.zip', 'Columbia 22 Final NAL 2018.zip', 'Dade 23 Final NAL 2018.zip', 'Desoto 24 Final NAL 2018.zip', 'Dixie 25 Final NAL 2018.zip', 'Duval 26 Final NAL 2018.zip', 'Escambia 27 Final NAL 2018.zip', 'Flagler 28 Final NAL 2018.zip', 'Franklin 29 Final NAL 2018.zip', 'Gadsden 30 Final NAL 2018.zip', 'Gilchrist 31 Final NAL 2018.zip', 'Glades 32 Final NAL 2018.zip', 'Gulf 33 Final NAL 2018.zip', 'Hamilton 34 Final NAL 2018.zip', 'Hardee 35 Final NAL 2018.zip', 'Hendry 36 Final NAL 2018.zip', 'Hernando 37 Final NAL 2018.zip', 'Highlands 38 Final NAL 2018.zip', 'Hillsborough 39 Final NAL 2018.zip', 'Holmes 40 Final NAL 2018.zip', 'Indian River 41 Final NAL 2018.zip', 'Jackson 42 Final NAL 2018.zip', 'Jefferson 43 Final NAL 2018.zip', 'Lafayette 44 Final NAL 2018.zip', 'Lake 45 Final NAL 2018.zip', 'Lee 46 Final NAL 2018.zip', 'Leon 47 Final NAL 2018.zip', 'Levy 48 Final NAL 2018.zip', 'Liberty 49 Final NAL 2018.zip', 'Madison 50 Final NAL 2018.zip', 'Manatee 51 Final NAL 2018.zip', 'Marion 52 Final NAL 2018.zip', 'Martin 53 Final NAL 2018.zip', 'Monroe 54 Final NAL 2018.zip', 'Nassau 55 Final NAL 2018.zip', 'Okaloosa 56 Final NAL 2018.zip', 'Okeechobee 57 Final NAL 2018.zip', 'Orange 58 Final NAL 2018.zip', 'Osceola 59 Final NAL 2018.zip', 'Palm Beach 60 Final NAL 2018.zip', 'Pasco 61 Final NAL 2018.zip', 'Pinellas 62 Final NAL 2018.zip', 'Polk 63 Final NAL 2018.zip', 'Putnam 64 Final NAL 2018.zip', 'Saint Johns 65 Final NAL 2018.zip', 'Saint Lucie 66 Final NAL 2018.zip', 'Santa Rosa 67 Final NAL 2018.zip', 'Sarasota 68 Final NAL 2018.zip', 'Seminole 69 Final NAL 2018.zip', 'Sumter 70 Final NAL 2018.zip', 'Suwannee 71 Final NAL 2018.zip', 'Taylor 72 Final NAL 2018.zip', 'Union 73 Final NAL 2018.zip', 'Volusia 74 Final NAL 2018.zip', 'Wakulla 75 Final NAL 2018.zip', 'Walton 76 Final NAL 2018.zip', 'Washington 77 Final NAL 2018.zip']

url_base = "ftp://sdrftp03.dor.state.fl.us/Tax%20Roll%20Data%20Files/2018%20Final%20NAL%20-%20SDF%20Files/"

file_base = "files/"
def download_file(url, local_filename):
    cmd = "curl \"%s\" > %s" % (url, local_filename)
    print("Running: %s" % cmd)
    os.system(cmd)

max = 1
i = 0
for filename in filenames:
    i += 1
    if i > max:
        print("Done %s rows, exiting" % (i-1))
        break
    filename = filename.replace(" ", "%20")
    url = url_base + filename
    print("URL is %s" % url)
    outfile = file_base + filename
    print("Local file is %s" % outfile)

    download_file(url, outfile)

    unzip_cmd = "unzip %s -d %s" % (outfile, file_base)
    print("Running: %s" % unzip_cmd)
    os.system(unzip_cmd)


