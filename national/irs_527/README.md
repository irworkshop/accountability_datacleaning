# Directions for processing the 527 organizations

The data and documentation is available at [https://forms.irs.gov/app/pod/dataDownload/dataDownload](https://forms.irs.gov/app/pod/dataDownload/dataDownload).

Select the "Download form data file" and save the zip file into this directory. It will be named "PolOrgsFullData.zip". Unzip the file. It will automatically create a series of directories, specifially /var/IRS/data/scripts/pofd/Download/FullDataFile.txt. Move the FullDataFile.txt to this directory. 

`$ mv var/IRS/data/scripts/pofd/download/FullDataFile.txt  ./ `

Run the python script

`$ python read_527.py`

It will produce output like the following:

	Writing row type A to file 527read_A.csv
	Writing row type B to file 527read_B.csv
	Writing row type 1 to file 527read_1.csv
	Writing row type 2 to file 527read_2.csv
	Writing row type D to file 527read_D.csv
	Writing row type R to file 527read_R.csv
	Writing row type E to file 527read_E.csv
	Processed a total of 3557180 lines. Wrote summary of unreadable lines to bad.txt.
	Summary of lines by type: {'H': 1, 'D': 122868, 'R': 55888, '1': 48162, '2': 35578, 'E': 10084, 'B': 1101905, 'A': 2178123, 'problem': 4572}

Note that the file is slightly broken; it's supposed to be a bar-delimited text file, but incorrectly added newlines have broken it. The simplest thing is to ignore the bad lines, but a better solution would be to fix this script to deal with it. On the whole, most lines parse.


For more details on what each row type means, consult the documentation.