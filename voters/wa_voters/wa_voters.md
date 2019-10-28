## Washington State voter registration processing

**Here's to Washington! Thanks for the clean data!**  

Number of records: 4,839,859  

See documentation in this folder for more information  

Processed with SPSS for efficiency - will convert to R later  

*Import data.
GET DATA  /TYPE=TXT
  /FILE="C:\JENDATAxps\accountability_data\voters\WA\201810_VRDB_Extract.txt"
  /ENCODING='Locale'
  /DELCASE=LINE
  /DELIMITERS="\t"
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES=
  StateVoterID A11
  CountyVoterID A9
  Title A2
  FName A11
  MName A16
  LName A15
  NameSuffix A2
  Birthdate A10
  Gender A1
  RegStNum A5
  RegStFrac A1
  RegStName A21
  RegStType A4
  RegUnitType A4
  RegStPreDirection A2
  RegStPostDirection A2
  RegUnitNum A7
  RegCity A13
  RegState A2
  RegZipCode A5
  CountyCode A2
  PrecinctCode A8
  PrecinctPart A10
  LegislativeDistrict A2
  CongressionalDistrict A2
  Mail1 A27
  Mail2 A1
  Mail3 A1
  Mail4 A1
  MailCity A10
  MailZip A5
  MailState A2
  MailCountry A1
  Registrationdate A10
  AbsenteeType A1
  LastVoted A10
  StatusCode A1.
CACHE.
EXECUTE.
DATASET NAME DataSet1 WINDOW=FRONT.

*CREATE AND UPDATE NEW FIELDS.
DATASET ACTIVATE DataSet1.
STRING  CITY_CLEAN (A15).
COMPUTE CITY_CLEAN=RegCity.
STRING  YEAR (A15).
COMPUTE YEAR=CHAR.SUBSTR(Registrationdate,7,4).
STRING  BIRTHYEAR (A15).
COMPUTE YEAR=CHAR.SUBSTR(Registrationdate,7,4).
EXECUTE.

Known issues:  
Four cities had two spellings  
One voter had a registration date of 2218  
