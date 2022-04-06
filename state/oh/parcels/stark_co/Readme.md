###Ottawa County, Ohio parcels

Land parcels in Stark County Ohio. Originally dowloaded June 25 2019 from [here](https://portal-starkcountyohio.opendata.arcgis.com/datasets/parcel-data).

Get the file, and export the non-geographical fields to csv with gis software, like QGIS. The script is expecting the exported csv file to be named 'Stark_OH_raw.csv'.

Run `read_stark_parcels.py` and it should create the final version in 'Stark_OH.csv'.