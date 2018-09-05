#Program reads parameters from config.txt, pulls xml from bepress site, then packages for Portico backup 
require 'net/https'
require 'uri'
require 'Nokogiri'
require 'fileutils'
require_relative 'articlehelper'

#Sets parameters for download
config = File.read('config.txt').to_s
journallabel = readParam(config, config.index('journal: ') + 9)
vol = readParam(config, config.index('vol: ') + 5)
iss = readParam(config, config.index('iss: ') + 5)
year = readParam(config, config.index('year: ') + 6)

url = 'https://commons.pacificu.edu/do/oai/?metadataPrefix=document-export&verb=ListRecords&set=publication:' + journallabel + '/vol' + vol + '/iss' + iss + '/'
root_foldername = journallabel + '_' + vol + '_' + iss + '_' + year 
puts "Creating folder: " + root_foldername
root_filename = root_foldername + '.xml'

#Makes issue folder for files
FileUtils.mkdir_p root_foldername 

#Transforms and writes xml
getFile(journallabel, vol, iss, url, root_filename)
direct = File.open('direct_' + root_filename, 'r')
output = ''
while !direct.eof?
	line = direct.readline
	output = clean_xml(line, output)
end
File.open(root_filename, 'w'){|f| f.write(output)}
@doc  = Nokogiri::XML(File.open(root_filename))

#Constructs an array to store articles and grab the articles from the document
no_articles = @doc.xpath("//record//metadata").size
arr = Array.new
articles = @doc.xpath("//record//metadata//document-export//documents//document")
puts "Number of articles detected: " + no_articles.to_s

#Gets article data to fill array 
for i in 0..no_articles do
	arr[i] = Article.new
	i_article = articles[i]
	if articles[i] 
	 	title = i_article.xpath("title")
	 	arr[i].articletitle = format(title.text)
	 	

	 	url = i_article.xpath("fulltext-url")
	 	arr[i].url = format(url.text)

	 	journalid = i_article.css("field[name='journal_id']") #works
		arr[i].journalid = format(journalid.text)

		issn = i_article.css("field[name='issn']") 
		arr[i].issn = format(issn.text)

		publishername = @doc.css("field[name='publisher']") 
		arr[i].publishername = format(publishername.text)

		doi = i_article.css("field[name='doi']") 
		arr[i].doi = format(doi.text).gsub("https://doi.org", "").gsub("http://doi.org", "").gsub("http://dx.doi.org", "").gsub("https://dx.doi.org", "") 

		subject = i_article.xpath("document-type")
		arr[i].subject = format(subject.text)

		#Extracts the day, month, and year from the source date string
		date = i_article.xpath("publication-date").text.to_s
		arr[i].day = format(parseDate(date, 'day'))
		arr[i].month = format(parseDate(date, 'month'))
		arr[i].year = format(parseDate(date, 'year'))

		vol = i_article.css("field[name='volnum']") 
		arr[i].vol = format(vol.text)

		iss = i_article.css("field[name='issnum']") 
		arr[i].iss = format(iss.text)

		elocationid = i_article.xpath("articleid")
		arr[i].elocationid = format(elocationid.text)

		cstatement = i_article.css("field[name='rights']") 
		arr[i].cstatement = format(cstatement.text)
		unless arr[i].cstatement.to_s[0] == 'C'
			arr[i].cstatement = arr[i].cstatement[1..arr[i].cstatement.length-1].insert(0, 'Copyright')
		end

		arr[i].suri = arr[i].journalid.to_s + arr[i].elocationid.to_s + ""

		fauthor = i_article.xpath("authors//author//fname")
		arr[i].fauthor = format(fauthor.text)

		lauthor = i_article.xpath("authors//author//lname")
		arr[i].lauthor = format(lauthor.text)

		abstract = i_article.xpath("abstract")
		arr[i].abstract = format(abstract.text)
	end
end

arr.each do |item|
	unless (item.suri.to_s.empty?) 
		puts "Formatting for Portico ... " + item.suri
		porticoize(item, root_foldername)
	end
end

puts "Done! Process complete."
