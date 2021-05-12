# Lobbyist Contributions (LD-203) 

Retrieve the raw zipped xml files from http://disclosures.house.gov/lc/lcsearch.aspx . (You'll have to click on the "Download past filings in xml format" button, and then download all of the files that are not already present).


If you download the zipfiles to this directory, when you unzip them they should contain many individual xml files in directories named like 2009\_MidYear\_XML (where the format is YYYY\_{MidYear|YearEnd}\_XML. That directory structure is assumed by the script. 

Note that the periodic zipfiles appear as soon as there are some reports recieved during that period. In other words, a midyear file is present before the year is halfway over, but it will grow as more .xml files are added.


Then run the script. Modify the script to only run over the current year if you just need an update. 



	$ python read_file.py 
	Writing 2008 data out to lobbyist_contributions_ld203_2008.csv
	Read 39557 files for 2008
	Writing 2009 data out to lobbyist_contributions_ld203_2009.csv
	Read 38605 files for 2009
	Writing 2010 data out to lobbyist_contributions_ld203_2010.csv
	Contributions unparseable in 2010_YearEnd_XML/700883180.xml, skipping
	Read 37862 files for 2010
	Writing 2011 data out to lobbyist_contributions_ld203_2011.csv
	Read 36821 files for 2011
	....


Note that there are a few unparseable files. These might be from testing e.g. 700883180.xml:   `<contactName>Dec 2010 Testingsss</contactName>` or from files where noContributions is mistakenly set to false and yet no contributions occur, see 700875349.xml.



