require 'net/https'
require 'uri'
require 'Nokogiri'
require 'fileutils'

#Creates Article class
class Article
	attr_accessor :jtitle, :url, :journalid, :issn, :publishername, :doi, :subject, :articletitle, :datetype, :pubformat, :isodate, :day, :month, :year, :vol, :iss, :elocationid, :cstatement, :license, :cyear, :suri, :authors, :abstract
end

#Creates Author class
class Author
	attr_accessor :fname, :lname
end

#Formats configurations from config.txt
def readParam (phrase, index)
	if phrase.include?("\n") then
	 	last = phrase.index("\n") - 1	
		phrase.sub!("\n", "")
	else 
		last = phrase.size - 1
	end
	param = phrase[index..last]
	return param
end

#Cleans up the XML from html format
def clean_xml(line, output)
	#Remove OAI header
	oaiheader = '<OAI-PMH'
	o1 = 'xmlns="http://www.openarchives.org/OAI/2.0/"'
	o2 = 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
	o3 = 'xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/'
	o4 = 'http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">'
	line = line.gsub(oaiheader, '<OAI-PMH>') 
	line = line.gsub(o1, '').gsub(o2, '').gsub(o3, '').gsub(o4, '')
	#Remove HTML elements
	line = line.gsub('&lt;strong&gt;', '&lt;/bold&gt;')
	line = line.gsub('&lt;/strong&gt;', 'lt;/bold&gt;')
	line = line.gsub('&lt;em&gt;', '&lt;italic&gt;')
	line = line.gsub('&lt;/em&gt;', '&lt;/italic&gt;')
	output = output + line
	return output
end

# Fetches the contents of a https URL without requiring SSL certificate
# http://notetoself.vrensk.com/2008/09/verified-https-in-ruby/
def getFile(journallabel, vol, iss, url, root_filename)

	uri = URI.parse(url)
	http = Net::HTTP.new(uri.host, uri.port)
	if uri.scheme == "https"  # enable SSL/TLS
	  http.use_ssl = true
	  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	end
	http.start {
	  http.request_get(url) {|res|
	    response = res.body
	    #Outputs to file
	    File.open('direct_' + root_filename, 'w'){|f| f.write(response)}
	  }
	}
end

#Parses string to give date
def parseDate (date, type)
	case type
	when "day" 
		date[8,2]
	when "month" 
		date[5,2]
	when "year"
		date[0,4]
	end
end

#Formats the Nokogiri output for text
def format (input)
	output = input.to_s.gsub("\n", "")
	return output
end

#Creates an XML file from an article obj
def porticoize(a, root_foldername, vol, iss, publisher)
	puts "Creating xml " + a.suri
	xml_temp = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE article
  PUBLIC \"-//NLM//DTD JATS (Z39.96) Journal Publishing DTD v1.1d2 20140930//EN\" \"http://jats.nlm.nih.gov/publishing/1.1d2/JATS-journalpublishing1.dtd\">
<article xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
         xmlns:xlink=\"http://www.w3.org/1999/xlink\"
         dtd-version=\"1.1d2\"
         xml:lang=\"en\">
   <front>
      <journal-meta>
         <journal-id journal-id-type=\"publisher-id\">" + a.journalid.to_s + "</journal-id>
	     <issn pub-type=\"epub\">"+ a.issn.to_s + "</issn>
	         <publisher>
	            <publisher-name>" + publisher + "</publisher-name>
	         </publisher>
	      </journal-meta>
	      <article-meta>
	         <article-id pub-id-type=\"doi\">" + a.doi.to_s + "</article-id>
	         <article-categories>
	            <subj-group subj-group-type=\"article-section\">
	               <subject>" + a.subject.to_s + "</subject>
	            </subj-group>
	         </article-categories>
	         <title-group>
	            <article-title>" + a.articletitle.to_s + "</article-title>
	         </title-group>"
	   	unless (a.authors.to_s.empty?)
	   		xml_temp = xml_temp +
	         "<contrib-group>" 
	         	for j in 0..(a.authors.size-1) do
		            xml_temp = xml_temp + "<contrib contrib-type=\"author\">
		               <name>
		                  <surname>" + a.authors[j].lname + "</surname>
		                  <given-names>" + a.authors[j].fname + "</given-names>
		               </name>
		            </contrib>"
		        end
		    xml_temp = xml_temp +
	        "</contrib-group>"
	     end
	     xml_temp = xml_temp +
	         "<pub-date date-type=\"pub\"
	                   publication-format=\"online\" 
	                   iso-8601-date=\"" + a.year.to_s + "-" + a.month.to_s + "-" + a.day.to_s + "\">
	            <day>" + a.day.to_s + "</day>
	            <month>" + a.month.to_s + "</month>
	            <year>" + a.year.to_s + "</year>
	         </pub-date>
	         <volume>" + vol.to_s + "</volume>
	         <issue>" + iss.to_s + "</issue>
	         <elocation-id>" + a.elocationid.to_s + "</elocation-id>
	         <permissions>
	            <copyright-statement>" + a.cstatement.to_s + "</copyright-statement>
	            <copyright-year>" + a.year.to_s + "</copyright-year>
	            <license license-type=\"open-access\" xlink:href=\"\">
	               <license-p/>
	            </license>
	         </permissions>
	         <self-uri xlink:title=\"local_file\" xlink:href=\"" + a.suri.to_s + ".pdf\">" + a.suri.to_s + "</self-uri>"
	        unless (a.abstract.to_s.empty?)
	        	xml_temp = xml_temp + "<abstract>" + a.abstract.to_s + "</abstract>"
	     	end
	     	xml_temp = xml_temp + 
	      "</article-meta>
	   </front>
	</article>"

	#Writes xml to file in folder
	article_filename = a.suri.to_s.gsub("\n", '')
	article_filepath = root_foldername.gsub("\n", '') + "/" + article_filename
	#Creates article folder
	FileUtils.mkdir_p article_filepath
	#Writes to file in folder
	File.open(article_filepath + '/' + article_filename + '.xml' , 'w'){|f| f.write(xml_temp)}

	#Gets files from the web
	#Toggle off to prevent robot block
	sleep(10)
	pdfname = article_filepath + "/" + article_filename + ".pdf"
	uri = URI.parse(a.url)
	http = Net::HTTP.new(uri.host, uri.port)
	if uri.scheme == "https"  # enable SSL/TLS
  		http.use_ssl = true
  		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	end
	http.start { 
  		resp = http.get(a.url)
    	open(pdfname, "wb") do |file|
        	file.write(resp.body)
    	end
	}
end

#Creates an XML file from an article obj
def crossref(a, root_foldername, vol, iss, publisher, email, depositor, batchid)
	puts "Creating xml " + a.suri
	xml_temp = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<doi_batch xmlns=\"http://www.crossref.org/schema/4.3.0\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" version=\"4.3.0\" xsi:schemaLocation=\"http://www.crossref.org/schema/4.3.0 http://www.crossref.org/schema/deposit/crossref4.3.0.xsd\">
	<head>
		<doi_batch_id>" + batchid + "</doi_batch_id>
		<timestamp>" + Time.now.strftime("%y%m%d%H%M%S").to_s + "</timestamp>
		<depositor>
			<name>" + depositor + "</name>
			<email_address>" + email + "</email_address>
		</depositor>
		<registrant>" + publisher + "</registrant>
	</head>"
	xml_temp = xml_temp + 
	"<body>
		<journal>
			<journal_metadata>
				<full_title>" + a.jtitle + "</full_title>
				<issn media_type=\"electronic\">" + a.issn + "</issn>
			</journal_metadata>
			<journal_issue>
				<publication_date media_type=\"online\">
					<month>" + a.month + "</month>
					<day>" + a.day + "</day>
					<year>" + a.year + "</year>
				</publication_date>
				<journal_volume>
					<volume>" + vol.to_s + "</volume>
				</journal_volume>
				<issue>" + iss.to_s + "</issue>
			</journal_issue>
			<journal_article publication_type=\"full_text\">
				<titles>
					<title>" + a.articletitle + "</title>
				</titles>
				<contributors>"
					for j in 0..(a.authors.size-1) do
		            xml_temp = xml_temp + "<person_name contributor_role=\"author\">
		                  <given-name>" + a.authors[j].fname + "</given-name>
		                  <surname>" + a.authors[j].lname + "</surname>
					</person_name>"
		        	end
		        xml_temp = xml_temp + 
				"</contributors>
				<publication_date media_type=\"online\">
					<month>" + a.month + "</month>
					<day>" + a.day + "</day>
					<year>" + a.year + "</year>
				</publication_date>
				<doi_data>
					<doi>" + a.doi + "</doi>
					<resource>" + a.url + "</resource>
				</doi_data>
			</journal_article>
		</journal>
	</body>
</doi_batch>"

	#Writes xml to file in folder
	article_filename = a.suri.to_s.gsub("\n", '')
	article_filepath = root_foldername.gsub("\n", '')
	#Writes to file in folder
	File.open(article_filepath + '/' + article_filename + '.xml' , 'w'){|f| f.write(xml_temp)}
end