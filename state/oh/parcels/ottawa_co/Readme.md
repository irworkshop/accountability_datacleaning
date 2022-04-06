###Ottawa County, Ohio parcels

Land parcels in Ottawa County Ohio. From the county's [google drive](https://drive.google.com/drive/folders/0B4hTJB05icP8cjNJZnFIVEVJbmM?usp=sharing). I found it linked from the [county auditor's page](http://www.ottawacountyauditor.org/).

Get the files, and export the non-geographical fields to csv with gis software, like QGIS. The script is expecting the exported csv file to be named 'Ottawa_OH_raw.csv'.

Run `read_ottawa_parcels.py` and it should create the final version in 'Ottawa_OH.csv'.