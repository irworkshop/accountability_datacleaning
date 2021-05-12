## Processing the IRS 1023 EZ

The raw excel files can be obtained as annual excel files from here: 
https://www.irs.gov/charities-non-profits/exempt-organizations-form-1023ez-approvals

Documentation about the files themselves is available here: https://www.irs.gov/pub/irs-tege/f1023ez_infosheet.pdf

Convert them to .csv files with csvkit:

	$ in2csv f1023ez_approvals_2014.xlsx > f1023ez_approvals_2014.csv
	$ in2csv f1023ez_approvals_2015.xlsx > f1023ez_approvals_2015.csv
	$ in2csv f1023ez_approvals_2016.xlsx > f1023ez_approvals_2016.csv
	$ in2csv f1023ez_approvals_2017.xlsx > f1023ez_approvals_2017.csv
	$ in2csv f1023ez_approvals_2018.xlsx > f1023ez_approvals_2018.csv
	$ in2csv f1023ez_approvals_2019_jan_mar.xlsx  > f1023ez_approvals_2019_jan_mar.csv
	
Note that these files sometimes have problems: 

	agate/utils.py:292: DuplicateColumnWarning: Column name "Gamingactyno" already exists in Table. Column will be renamed to "Gamingactyno_2".
	
	agate/utils.py:292: DuplicateColumnWarning: Column name "Gamingactyyes" already exists in Table. Column will be renamed to "Gamingactyyes_2".


We're gonna ignore them since we don't care about this column and remove it, but would be nice if they got this stuff right...

Now modify the dump_1023ez.py script to specify which files to process by naming them in the list of infiles near the top. It should be a dictionary with keys being the numeric year that file should be associated with. 


	infiles = {
	    2014: ['f1023ez_approvals_2014.csv',],   
	    2015: ['f1023ez_approvals_2015.csv',],   
	    2016: ['f1023ez_approvals_2016.csv',],   
	    2017: ['f1023ez_approvals_2017.csv',], 
	    2018: ['f1023ez_approvals_2018.csv',], 
	    2019: ['f1023ez_approvals_2019_jan_mar.csv',],
	}

Then run the script:

	$ python dump_1023ez.py 
	processing infile f1023ez_approvals_2014.csv
	processing infile f1023ez_approvals_2015.csv
	processing infile f1023ez_approvals_2016.csv
	processing infile f1023ez_approvals_2017.csv
	processing infile f1023ez_approvals_2018.csv
	processing infile f1023ez_approvals_2019_jan_mar.csv
	Output written to 1023ez.csv

