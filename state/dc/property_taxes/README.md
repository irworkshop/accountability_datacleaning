# DC tax assessments

Retrieve the "Integrated Tax System Public Extract Facts" file from [here](https://opendata.dc.gov/datasets/integrated-tax-system-public-extract-facts). Download it to this directory. It should be named "Integrated_Tax_System_Public_Extract_Facts.csv". 

There's a script called `fix_dc_taxes.py`. It is intended to

	# Add fields for city and state of the site and distinct columns for owner city state and zip


Run the python script!

	$ python fix_dc_taxes.py 
	Writing output to dc_tax_extract_cleaned.csv