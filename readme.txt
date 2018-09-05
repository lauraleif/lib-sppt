Bepress2Portico transforms Bepress XML into the Portico export files.

INSTALLING 
Copy the Bepress2Portico folder with the config, Bpress, and helper files.

RUNNING
Open config.txt and edit the journal, volume, issue, date, publisher, email, depositor, urlbase, and batchid information. 
This will tell the program which issue to retrieve from Bepress. The file should be configured as follows:

journal: eip
vol: 19
iss: 2
year: 2018
publisher: Pacific University Libraries
email: test@test.edu
depositor: Pacific University Press
urlbase: https://commons.pacificu.edu/do/oai/
batchid: testbatch123

Email, depositor, and batchid are used for the CrossRef export. 
Enter this information as you would like it to appear in the XML output.

CUSTOMIZATION
This program should work for other documents following the OAI-PMH standards. However, some customization of the request url may be needed.
This program is written to support urls following the template

urlbase + '?metadataPrefix=document-export&verb=ListRecords&set=publication:' + journallabel + '/vol' + vol + '/iss' + iss + '/'

Parameters urlbase, journallabel, vol, iss, and year are read from the config file.
See https://www.openarchives.org/OAI/openarchivesprotocol.html

GEMS
This program uses net/https, uri, Nokogiri, and fileutils gems. To install a gem, type install gem name (i.e. install gem uri).
To create an executable, install ocra and and run in the command line (ocra Bpress.rb will create an exe from Bpress.rb).