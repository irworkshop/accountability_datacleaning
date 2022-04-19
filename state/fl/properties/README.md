# Process Florida properties


Florida parcels are available via public FTP per county here: 

[ftp://sdrftp03.dor.state.fl.us/Tax%20Roll%20Data%20Files/2018%20Final%20NAL%20-%20SDF%20Files/](ftp://sdrftp03.dor.state.fl.us/Tax%20Roll%20Data%20Files/2018%20Final%20NAL%20-%20SDF%20Files/)

It's actually the SDF files we want. Download all of them to this directory, either by using the "download_files.py" to download and unzip them or some other means. (the download script just runs the command line commands curl and unzip on the files). 

After downloading the files, you can combine them into a single file using csvkit's csvstack:

	$ csvstack files/*.csv > fl_properties.csv
	
And then run the fix_properties.py script on the output. That script assumes the output is 'fl_propertis.csv' you'll need to update it if it is called something else. 

The script simply adds a PHY_STATE column set to Florida. This is the state that the parcel is located in, it is needed to set the site state in public accountability. 