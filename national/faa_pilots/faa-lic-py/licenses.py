#!/usr/bin/env python
# coding: utf-8

# In[1]:


# Importing packages

import pandas as pd
from zipfile import ZipFile
import os
import math
import numpy as np
from slugify import slugify
import re


# In[2]:


# Set relative filepaths
# Download link: https://www.faa.gov/licenses_certificates/aircraft_certification/aircraft_registry/releasable_aircraft_download
# Docs link: https://www.faa.gov/sites/faa.gov/files/licenses_certificates/aircraft_certification/aircraft_registry/releasable_aircraft_download/ardata.pdf

__file__ = 'os.path.abspath('')'

script_dir = os.path.dirname(__file__) 
rel_path = './data/ReleasableAircraft.zip'
abs_file_path = os.path.join(script_dir, rel_path)


# In[3]:


# Read zipfile

zf = ZipFile(abs_file_path) 


# In[4]:


# Load the .csv file we need from the zipfile - MASTER.txt

master = pd.read_csv(zf.open('MASTER.txt'), low_memory=False)
ref = pd.read_csv(zf.open('ACFTREF.txt'))


# In[5]:


# Slugify columns

master.columns = master.columns.str.replace(r'\W+', '_', regex=True)
ref.columns = ref.columns.str.replace(r'\W+', '_', regex=True)


# In[6]:


# Lowercase columns

master.columns = [x.lower() for x in master.columns]
ref.columns = [x.lower() for x in ref.columns]


# In[7]:


master.info()


# In[8]:


# Strip leading and trailing underscores on some column names

master.columns = master.columns.str.rstrip('_')
master.columns = master.columns.str.lstrip('_')


# In[9]:


# Drop the empty columns at the end of each file (the 'unnamed: xx' fields)

master.drop('unnamed_34', inplace=True, axis=1)
ref.drop('unnamed_13', inplace=True, axis=1)


# In[10]:


master.info()


# In[11]:


ref.info()


# In[12]:


# Rename the code col in the ref dataframe

ref.rename(columns = {'code':'mfr_mdl_code'}, inplace = True)


# In[13]:


# Merging the two dataframes together on the common field - mfr_mdl_code in master and code in ref

joined = pd.merge(ref, master, on='mfr_mdl_code', how='inner')

# joined = pd.concat([master.set_index('mfr_mdl_code'),ref.set_index('code')], axis=1, join='inner')

# joined = pd.concat([master, ref], axis=0)


# In[14]:


# How many records are in the database?
# Are any records missing?

joined.info()


# In[15]:


# Are there duplicates?
# Putting all of the duplicate rows into a dataframe of their own

joined2 = joined[joined.duplicated()]


# In[16]:


# There are not any duplicates.

joined2.info()


# In[17]:


# To test the values, we need just the name values without the extra whitespace

joined.name = joined.name.map(str.strip)


# In[18]:


# There are a variety of name lengths incl as of 1/2023 update 487 records with no name

joined['name_len'] = joined['name'].astype(str).map(len)
joined.name_len.value_counts()


# In[19]:


# We need the following fields to concatenate for the "registrant" field in the publicaccountability.org search:
# name, street, street2, city, state
# So let's make sure those are solid
# We also need the cert_issue_date for the date field, the manufacturer field, and to add a year field (2023)


# In[20]:


# All of the fields appear to have the same num of chars, use .strip()

joined.street = joined.street.map(str.strip)


# In[21]:


# There are a variety of address lengths incl as of the 1/2023 update 490 that are blank
# Should not be longer than 33 chars

joined['street_len'] = joined['street'].astype(str).map(len)
joined.street_len.value_counts()


# In[22]:


# All of the fields appear to have the same num of chars, use .strip()

joined.street2 = joined.street2.map(str.strip)


# In[23]:


# There are a variety of name lengths incl as of 1/2023 update 277519 with no values in this field
# Should not be longer than 

joined['street2_len'] = joined['street2'].astype(str).map(len)
joined.street2_len.value_counts()


# In[24]:


# All of the fields appear to have the same num of chars, use .strip()

joined.city = joined.city.map(str.strip)


# In[25]:


# There are a variety of name lengths incl as of 1/2023 update 277519 with no values in this field
# Should not be longer than 18 chars

joined['city_len'] = joined['city'].astype(str).map(len)
joined.city_len.value_counts()


# In[26]:


# All of the fields appear to have the same num of chars, use .strip()

joined.state = joined.state.map(str.strip)


# In[27]:


# There are a variety of name lengths incl as of 1/2023 update 1936 with no values in this field
# Should not be longer than 2 chars

joined['state_len'] = joined['state'].astype(str).map(len)
joined.state_len.value_counts()


# In[28]:


# All of the fields appear to have the same num of chars, use .strip()

joined.mfr = joined.mfr.map(str.strip)


# In[29]:


# There are a variety of mfr lengths
# Should not be longer than 30 chars

joined['mfr_len'] = joined['mfr'].astype(str).map(len)
joined.mfr_len.value_counts()


# In[30]:


joined.info()


# In[31]:


joined.drop(['name_len', 'street_len', 'street2_len', 'city_len', 'state_len', 'mfr_len'], axis=1, inplace=True)


# In[32]:


# Creating a US 5-digit ZIP code field
# This will fill the uszip5 field with ZEROES where the country is not USA

joined['uszip5'] = np.where(joined['country'] == 'US', joined['zip_code'].astype(str).str[:5], '')


# In[35]:


# This is to be sure the 5-digit ZIPs that begin with leading 0s do have the leading 0s -
# Python strips them, and, when we export to .csv, they will not show up in Excel - so the ZIP 01234 would appear as 1234
# However, if you open the file in Sublime Text, the 0s are there

joined['uszip5'] = joined['uszip5'].str.zfill(5)


# In[33]:


# Add year field

joined['year'] = 2023


# In[36]:


# Export
# Per the note here: https://registry.faa.gov/aircraftinquiry:
# The duration of aircraft registration certificates has been extended up to 7 years. 
# The Registry will be issuing revised certificates in batches based on the former expiration date. 
# For verification purposes, even though the expiration date on the registration certificate may not match the expiration 
# date in the FAA Aircraft Registration database, any registration certificate displaying an expiration date of January 31, 2023 
# or later is still valid. This applies to all foreign Civil Aviation Authorities or anyone else with a verification need.

joined.to_csv('aircraft_2023.csv', index=False)


# In[ ]:


# Here's a bunch of code I wrote before I realized we didn't need it 

# Check numeric date ranges. Anything too high or too low?
# There are a lot of numerical fields in this dataset. We'll check the ones with numbers only - 
# There are some fields with a combination of letters and numbers
# Fields with numerical values to check:
# type_eng, ac_cat, build_cert_ind, no_eng, no_seats, speed, last_action_date, type_engine, mode_s_code 
# Similar to what I did with the pilots data, I'll use value_counts


# In[18]:


# The type_eng values should be between or equal to 1 and 11, per docs

joined.type_eng.value_counts()


# In[19]:


# The ac_cat values should be 1, 2 or 3, per docs

joined.ac_cat.value_counts()


# In[20]:


# The build_cert_ind values should be 1, 2 or 3, per docs

joined.build_cert_ind.value_counts()


# In[21]:


# The no_eng values can vary. This field is the number of engines in the registered aircraft.

joined.no_eng.value_counts()


# In[22]:


# The no_seats values can vary. This field is the number of seats in the registered aircraft.

joined.no_seats.value_counts()


# In[23]:


# The speed values can vary. This field is the registered aircraft's cruising speed.
# As of the January update, one plane is listed with a cruising speed of 1,125
# Upon further inspection, the plane is a single-engine and weighs less than 12,500 pounds, so I think this is an error.

joined.speed.value_counts()


# In[24]:


# The last_action_date values will be dates formatted as YYYYMMDD
# To really investigate the integrity of this field, we would need to look separately at YYYY, MM, DD
# But we'll just leave that instruction here for anyone working with this data, and for this script
# I will just make sure that the values are the proper length
# To do that we will need to convert it to a string first

joined['last_action_date'] = joined['last_action_date'].astype(str)


# In[25]:


# Now check if it's too short or too long
# Create a new column of lengths for each value in last_action_date

joined['last_action_datelen'] = joined['last_action_date'].astype(str).map(len)


# In[26]:


# Check values in created col
# Should be 8

joined.last_action_datelen.value_counts()


# In[27]:


# Type engine should be int values 0 through 11

joined.type_engine.value_counts()


# In[28]:


# The values of mode_s_code vary but should be 8 characters in length 
# Change to string first

joined['mode_s_code'] = joined['mode_s_code'].astype(str)


# In[29]:


# Now check if it's too short or too long
# Create a new column of lengths for each value

joined['mode_s_codelen'] = joined['mode_s_code'].astype(str).map(len)


# In[30]:


# Check values in created col
# Should be 8

joined.mode_s_codelen.value_counts()


# In[31]:


# Now drop the len cols created 

joined = joined.drop(['last_action_datelen', 'mode_s_codelen'], axis=1)


# In[32]:


# Is there anything blank or missing?

joined.info()


# In[33]:


# Is there information in the wrong field?
# Let's look at all of the fields and what's supposed to be in them:
# The following fields are in the documents downloaded from the FAA website but they do not appear in the files as of Jan. 2023
# Aircraft Mfr Model Code - this is missing from the MASTER.txt file
# Now we'll actually check what values should be in each field and if the values in the data match the prescribed values
# It is worth noting that all fields appear to be all the same length


# In[34]:


# The n-number field should not be longer than 5 chars
# Create a new column for any values that are longer than 5 chars (we will delete this col later)
# Print it, and if there are 0 rows, we're good to go

mask = ((joined['n_number'].str.len()) > 5)
test_df = joined.loc[mask]
print(test_df)


# In[35]:


# Serial numbers can be as short as three characters or as long as 30

mask = ((joined['serial_number'].str.len()) > 30)
test_df = joined.loc[mask]
print(test_df)


# In[36]:


# Engine manufacturer mode code should be 5 chars 

mask = ((joined['eng_mfr_mdl'].str.len()) != 5)
test_df = joined.loc[mask]
print(test_df)


# In[37]:


# Year should be 4 chars

mask = ((joined['year_mfr'].str.len()) != 4)
test_df = joined.loc[mask]
print(test_df)


# In[38]:


# Type registrant can be any value from 1 to 9

mask = ((joined['type_registrant'].str.len()) < 1 & (joined['type_registrant'].str.len() > 9))
test_df = joined.loc[mask]
print(test_df)


# In[39]:


# The next few fields are long-text fields; registrant's name, address (street and street 2), city, state
# This line checks to make sure none of these fields have numbers
# There are no numbers

x = joined.name.str.isalpha()
print(x.value_counts())

