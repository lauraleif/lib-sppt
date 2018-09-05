require 'net/https'
require 'uri'
require 'Nokogiri'
require 'fileutils'

#creates Article class
class Article
	attr_accessor :url, :journalid, :issn, :publishername, :doi, :subject, :articletitle, :datetype, :pubformat, :isodate, :day, :month, :year, :vol, :iss, :elocationid, :cstatement, :license, :cyear, :suri, :fauthor, :lauthor, :abstract
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
	#puts output
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
def porticoize(a, root_foldername)
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
	            <publisher-name>Pacific University Libraries</publisher-name>
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
	   	unless (a.lauthor.to_s.empty? && a.fauthor.to_s.empty?)
	   		xml_temp = xml_temp +
	         "<contrib-group>
	            <contrib contrib-type=\"author\">
	               <name>
	                  <surname>" + a.lauthor.to_s + "</surname>
	                  <given-names>" + a.fauthor.to_s + "</given-names>
	               </name>
	            </contrib>
	         </contrib-group>"
	     end
	     xml_temp = xml_temp +
	         "<pub-date date-type=\"pub\"
	                   publication-format=\"online\" 
	                   iso-8601-date=\"" + a.year.to_s + "-" + a.month.to_s + "-" + a.day.to_s + "\">
	            <day>" + a.day.to_s + "</day>
	            <month>" + a.month.to_s + "</month>
	            <year>" + a.year.to_s + "</year>
	         </pub-date>
	         <volume>" + a.vol.to_s + "</volume>
	         <issue>" + a.iss.to_s + "</issue>
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