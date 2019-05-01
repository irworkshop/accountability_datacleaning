# New York Parcel data

Go to this [NY State GIS page](http://gis.ny.gov/gisdata/inventories/details.cfm?DSID=1300). Download the file "NYS Tax Parcel Centroid Points." This is the only file for the whole state; the parcel file is only from counties that cooperated. 

The summary for this file is: "Parcel centroid data for all 62 New York State counties. Parcel centroids were generated using the NYS Office of Information Technology Services GIS Program Office's (GPO) Statewide Parcel Map program data. Attribute values were populated using Assessment Roll tabular data the GPO obtained from the NYS Department of Tax and Finances Office of Real Property Tax Services (ORPTS)."

You can download it as a geodatabase or as a shapefile. Download the file, and then export the attribute data to a .csv file using your favorite GIS editor. 

Rename the .csv file to match the script; in this example we're calling it "ny\_parcels\_2018\_raw.csv" (because the file was last updated in 2018).


Run the script 'fix\_ny\_parcels.py'. (If the name of the input file is different, you'll need to edit the script to make it match). 

	$ python fix_ny_output.py 
	Writing output to outfile ny_parcels_2018_output.csv

The raw file allows multiple owners and addresses per line, but we can only index one name per row. The script breaks lines with two owners into two individual lines. 

