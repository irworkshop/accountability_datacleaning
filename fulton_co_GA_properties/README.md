## Fulton County, GA properties

Go to http://gisdata.fultoncountyga.gov/ and download the "property profile" file. A hard link to the data is [here](share.myfultoncountyga.us/datashare/fultoncounty/data/PropertyProfile/TXT/PropertyProfile.zip) as of this writing. 

The script assumes the raw data file is at "Output/PropertyProfile.txt" which is probably where it will be if you download it to this directory and unzip it. 

Run the script `fix_output.py`. It adds a column called 'situs_state' to the file, which is the state for the property location. (By definition it is Georgia, which is probably why it was left out of the original, but is needed for the public accountability address). 

	$ python fix_output.py 
	Writing output to fulton_co_ga_properties.csv

