# NJ Parcels

NJ parcels were obtained by NJ.com and uploaded [to Data.World here](https://data.world/njdotcom/nj-property-tax-rolls-2017). Thanks [@sstirling](https://github.com/sstirling)! The documentation is also available at that page. 


The raw files leave out the municipality of the parcel. In other words, the mailing address of the owner is present, but the tax jurisdiction where the parcel is included is only given by municipality code. We've dug up the correct codes, the script below will add them. 

The script assumes that the downloaded file is named "ModIVNJ17.csv". 

	$ python fix_nj_rolls.py 
	Writing output to nj_rolls_2017.csv
	Total of 3156208 lines written
	City, state extraction using regex failed in 10499 lines


Note that it uses a simplish regex to parse the city and state out of a city/state field, this fails occasionally. 