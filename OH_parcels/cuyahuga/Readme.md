###Cuyahoga parcels

Land parcel ownership for Cuyahoga County comes in two files available for the section of the county [in Cleveland](https://data-cuyahoga.opendata.arcgis.com/datasets/combined-parcels-cleveland-only) and [outside of it](https://data-cuyahoga.opendata.arcgis.com/datasets/combined-parcels-non-cleveland-only).

Get the files, and export the non-geographical fields to csv with gis software, like QGIS. The script is expecting the exported csv files to be named 'Cleveland_OH.csv' and 'Cuyahoga_nonCleveland_OH.csv'.

Run `read_cuyahoga_parcels.py`