#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pandas as pd
from zipfile import ZipFile
import os
import math
import numpy as np
from slugify import slugify
# for printing dfs
pd.options.display.max_rows = 100
# for printing lists
pd.options.display.max_seq_items = 50


# In[2]:


# Set relative filepaths
# Missouri voter data is obtained via public records request to the Elections Division, Office of Secretary of State
# More info about data source can be found in the README

__file__ = 'os.path.abspath('')'

script_dir = os.path.dirname(__file__)
rel_path = './data/Missouri'
abs_file_path = os.path.join(script_dir, rel_path)


# In[3]:


# Show the name of the zipfile that is opened in the next step

files = os.listdir(abs_file_path)


# In[4]:


# Read the zipfile

voters = (files[1])
zf = ZipFile(abs_file_path + "/" + voters)


# In[5]:


# List files in zipfile

zf.namelist()


# In[6]:


# Load data into dataframe, first with no header for processing reasons

voters = pd.read_csv(zf.open('data\\PSR_VotersList_01032023_9-51-24 AM.txt'), sep='\t', header=None)


# In[7]:


# Now set the first row as header

voters.columns = voters.iloc[0] 


# In[8]:


# Checking the df

voters.info()


# In[9]:


# Slugifying columns

voters.columns = voters.columns.str.replace(r'\W+', '_', regex=True)
voters.columns = [x.lower() for x in voters.columns]


# In[10]:


voters.info()


# In[11]:


# There are 20 voter history columns. We'll keep the most recent and store the others in a different dataframe.
# Also get the names of column headers so we can use them to put the columns we need in another dataframe.

column_headers = list(voters.columns.values)
del_cols = column_headers[35:]
print(del_cols)


# In[12]:


# Put old voter history 2-20 into a new, separate dataframe

voters2 = pd.DataFrame()
voters2 = pd.concat([voters2,voters[del_cols]],axis=0)


# In[13]:


# Checking voter history dataframe

voters2.info()


# In[14]:


# Later on we will drop the extended voter history from the original, first df
# But for now we'll keep it, for the sake of the next step
# Check this data against previous MO voter data, and keep only voters not found in old data
# Loading 2020 data

voters20 = pd.read_csv('./data/mo_voters_2020.csv')


# In[15]:


# Slugifying columns in 2020 data

voters20.columns = voters20.columns.str.replace(r'\W+', '_', regex=True)
voters20.columns = [x.lower() for x in voters20.columns]
voters20.info()


# In[16]:


# Comparing voter ID columns
# In 2020, the TAP team received a similar file. We are going to keep any
# registered voters not found in the current file.

idx1 = pd.Index(voters.voter_id)
idx2 = pd.Index(voters20.voter_id)

diff = idx2.difference(idx1).values
print("There are " + str(len(diff)) +  " voters in the 2020 data who are not in the current data.")


# In[17]:


# Convert diff array to list

diff = list(diff)


# In[18]:


# Put those voters from 2020 data not in current data into a df, we'll need it later

keepers = voters20[voters20['voter_id'].isin(diff)]
keepers.info()


# In[19]:


# Drop voter history 2-20 from original dataframe

voters.drop(columns=['voter_history_2', 'voter_history_3', 'voter_history_4', 'voter_history_5', 'voter_history_6', 'voter_history_7', 'voter_history_8', 'voter_history_9', 'voter_history_10', 'voter_history_11', 'voter_history_12', 'voter_history_13', 'voter_history_14', 'voter_history_15', 'voter_history_16', 'voter_history_17', 'voter_history_18', 'voter_history_19', 'voter_history_20'], inplace=True)


# In[20]:


voters.info()


# In[21]:


print(voters['mailing_address'].unique())


# In[22]:


# Change names of columns to match old file 

voters.rename(columns = {'mailing_address':'address_clean', 'mailing_zipcode':'zip_clean', 'mailing_city':'city_clean', 'residential_city': 'city', 'residential_zip': 'zip', 'mailing_state': 'state', 'congressional_district_20': 'congressional', 'legislative_district_20': 'legislative', 'senate_district_20': 'senate', 'voter_history_1': 'last_election'}, inplace = True)


# In[23]:


voters.info()


# In[24]:


# For source and dupe_flag, we will create them and fill them with values to match the old file

voters['source'] = 1
voters['dupe_flag'] = 'FALSE'


# In[25]:


# Drop the residential state field because we already have a state field 

voters.drop('residential_state', axis=1, inplace=True)


# In[26]:


# Drop residential ZIP because we already have a ZIP field

voters.drop('residential_zipcode', axis=1, inplace=True)


# In[27]:


voters.info()


# In[ ]:




