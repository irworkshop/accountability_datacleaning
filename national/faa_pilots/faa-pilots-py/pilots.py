#!/usr/bin/env python
# coding: utf-8

# In[161]:


# Importing packages

import pandas as pd
from zipfile import ZipFile
import os
import math
import numpy as np


# In[162]:


# Set relative filepaths

__file__ = 'os.path.abspath('')'

script_dir = os.path.dirname(__file__) 
rel_path = './data/faa/pilots/CS122022.zip'
abs_file_path = os.path.join(script_dir, rel_path)


# In[163]:


# Read zipfile

zf = ZipFile(abs_file_path) 


# In[164]:


# Load the .csv files we need from the zipfile - PILOT_BASIC and NONPILOT_BASIC

pilot = pd.read_csv(zf.open('PILOT_BASIC.csv'))
nonpilot = pd.read_csv(zf.open('NONPILOT_BASIC.csv'))


# In[165]:


# Make sure the data loaded into dataframes properly (if working in Jupyter)

# pilot.info()


# In[166]:


# Check to make sure the data loaded into dataframes properly (if working in Jupyter)

# nonpilot.info()


# In[167]:


# Drop the empty columns at the end of each file (the 'Unnamed: 15' fields)

pilot.drop('Unnamed: 15', inplace=True, axis=1)
nonpilot.drop('Unnamed: 15', inplace=True, axis=1)


# In[168]:


# Merging the two dataframes together 

joined = pd.concat([pilot, nonpilot], axis=0)


# In[169]:


# How many records are in the database?
# Are any records missing?

# More than half of the rows do not have med_class, med_date, med_exp_date
# Less than 100k rows have basic_med_course_date and basic_med_cmec_date
# The FAA website states explicitly that this database is not the authoritative source for medical data

# joined.info() 


# In[170]:


# Rename columns — all but UNIQUE ID have a space before the text begins, in the raw data

joined.rename(columns={"UNIQUE ID": "uniqueid", " FIRST NAME": "first_name", " LAST NAME": "last_name", " STREET 1": "street_1", " STREET 2": "street_2", " CITY": "city", " STATE": "state", " ZIP CODE": "zip_code", " COUNTRY": "country", " REGION": "region", " MED CLASS": "med_class", " MED DATE": "med_date", " MED EXP DATE": "med_exp_date", " BASIC MED COURSE DATE": "basic_med_course_date", " BASIC MED CMEC DATE": "basic_med_cmec_date"},inplace=True)


# In[180]:


# Putting all of the duplicate rows into a dataframe of their own

joined2 = joined[joined.duplicated()]


# In[181]:


# As of 12/19/22, there were 954,997 total records in the joined dataframe and 887,356 unique unique-ids
# There are 67,641 records in this dataframe, which shows the duplicate rows
# 954,997 - 887,356 = 67,641

print(joined2.info())


# In[182]:


# Drops duplicate rows from the dataframe
# If not done, there are duplicate records

# joined = joined.drop_duplicates()


# In[171]:


# Does it seem to be in the correct range?
# Let's check each column to see what the values look lik

# For the first field, uniqueid, these values should appear twice at the most — if the pilot is listed in both files
# It appears no uniqueid is listed more than twice

joined.uniqueid.value_counts()


# In[172]:


# For the rest of the fields, look at field.value_counts() only if performing operations on field
# Doing that on fields such as first_name and last_name would result in lots of different groupings that don't make sense
# Operations need done on the zip_code field though, so we'll check that out here

pd.set_option('display.max_rows', 800000) # this is so I can see full outputs printed in Jupyter
joined.zip_code.value_counts()

# Okay, there are clearly lots of US 9-digit ZIPs, as well as some 5-digit ZIPs (it seems)
# But the shorter ZIPs could be accurate, because the pilot's address is in a country other than the US (see next cell)


# In[173]:


# Checking the country column to see if there are countries other than the US

pd.set_option('display.max_rows', 300) # there are 195 countries in the world so if it's more than 200, take a second look
joined.country.value_counts()

# I first had the max_rows set to 200, but there were more than that. It's because in some cases, there are multiple
# islands or territories or other type of land, contained within one country
# For example: There are entries for the "Channel Isles" which are the Channel Islands - they're a part of the state of CA
# Another example is Saipan, which is the largest island in the Northern Mariana Islands, a US commonwealth
# There are a variety of different formats that non-US ZIPs come in


# In[174]:


# Creating a US 5-digit ZIP code field

joined['uszip5'] = np.where(joined['country'] == 'USA', joined['zip_code'].astype(str).str[:5], '')


# In[175]:


# Creating a non-US ZIP code field

joined['nonuszip'] = np.where(joined['country'] != 'USA', joined['zip_code'], '')


# In[178]:


# This is to be sure the 5-digit ZIPs that begin with leading 0s do have the leading 0s -
# Python strips them, and, when we export to .csv, they will not show up in Excel - so the ZIP 01234 would appear as 1234
# However, if you open the file in Sublime Text, the 0s are there

joined['uszip5'] = joined['uszip5'].str.zfill(5)


# In[184]:


# Check ranges: Are numeric fields in ranges that make sense. Anything too high or too low? 
# (For example: In voter registration data are the dates of birth too recent or too long ago?)

# The only numeric fields in this dataset are the med_class, med_date, med_exp_date, basic_med_course_date and basic_med_cmec_date
# For med_class, the values should be either 1, 2 or 3, which reflect the three classes of medical licenses pilots can have

# After running the below command, you'll notice one row (2, when deduping isn't done) has the value of 8.

joined.med_class.value_counts()


# In[185]:


# Check ranges: Are numeric fields in ranges that make sense. Anything too high or too low? 
# For two of the remaining numeric fields, med_date and med_exp_date, the format is MYYYY or MMYYYY, depending
# We will need to split the month-year into their own columns for each field (month, year columns for both variables)

pd.set_option('display.max_rows', 500) # this is so I can see the full list printed in Jupyter
joined.med_date.value_counts()

# This range, and the numbers within it, look reasonable


# In[186]:


# We need to approach these two fields differently based on if the month is a one- or two-digit month:
# To do that, we need to change the ints into strings 

joined = joined.astype({'med_date':'string','med_exp_date':'string'})


# In[187]:


joined.info()


# In[188]:


# When changing med_date to string, undesired string characters come along
# Let's remove them
# But first, to do that, fill the nan values with empty strings because otherwise errors will throw

joined['med_date'].fillna("", inplace=True)


# In[189]:


# Stripping undesirable characters

joined['med_date'] = joined['med_date'].map(lambda x: x.lstrip('b\'').rstrip('.0\''))


# In[190]:


# List comprehension to get the med_date_month out of the med_date field

joined['med_date_month'] = [x[:1] if len(x)<6 else x[:2] for x in joined['med_date']]


# In[191]:


# Create the med_date_year field out of med_date

joined['med_date_year'] = joined.med_date.str[-4:]


# In[192]:


# Do the same for med_exp_date, which for some reason did not get the undesired chars attached
# But it's still a good idea to check if these values are in an appropriate range

pd.set_option('display.max_rows', 500) # this is so I can see the full list printed in Jupyter
joined.med_exp_date.value_counts()


# In[193]:


# Fill the nan values with empty strings because otherwise errors will throw

joined['med_exp_date'].fillna("", inplace=True)


# In[194]:


# Because float-string conversion, we need to strip the .0

joined['med_exp_date'] = joined['med_exp_date'].map(lambda x: x.rstrip('.0\''))


# In[195]:


# List comprehension to get the med_exp_date_month out of the med_exp_date field

joined['med_exp_date_month'] = [x[:1] if len(x)<6 else x[:2] for x in joined['med_exp_date']]


# In[196]:


# Create the med_exp_date_year field out of med_exp_date

joined['med_date_exp_year'] = joined.med_exp_date.str[-4:]


# In[197]:


# For the other two remaining date fields, basic_med_course_date and basic_med_cmec_date the format is YYYYMMDD consistently
# Change these into strings to slice and get year, month, date into separate fields

joined = joined.astype({'basic_med_course_date':'string','basic_med_cmec_date':'string'})


# In[198]:


# Now creating the year, month, date fields using slicing

joined['basic_med_course_date_year'] = joined.basic_med_course_date.str[:4]
joined['basic_med_course_date_month'] = joined.basic_med_course_date.str[4:6]
joined['basic_med_course_date_day'] = joined.basic_med_course_date.str[6:8]

joined['basic_med_cmec_date_year'] = joined.basic_med_cmec_date.str[:4]
joined['basic_med_cmec_date_month'] = joined.basic_med_cmec_date.str[4:6]
joined['basic_med_cmec_date_day'] = joined.basic_med_cmec_date.str[6:8]


# In[199]:


# That's all, folks!

joined.to_csv('pilots.csv')


# In[ ]:


# As of 1/6/23, this script combines and cleans the PILOT_BASIC.csv and NONPILOT_BASIC.csv files
# With further work, the script could also combine those two files with the PILOT_CERT.csv and NONPILOT_CERT.csv files
# (likely, a join/concat on uniqueid - Janelle will do this week of 1/9/23)

