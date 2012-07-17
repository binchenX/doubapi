require 'RUBYgems'  #a hack to require failure for nokogiri
require 'open-uri'
require 'nokogiri'
require 'pp'


module Doubapi
#return a Nokogiri XML  object
#use Douban API


Event =  Struct.new :title, :when, :where, :what, :link
#release_date is in the format of YY-MM-DD
Album =  Struct.new :author, :title, :release_date, :link,:cover_thumbnail,:publisher,:mobile_site

#input:{key => "all/singer_name", :location => "shanghai", :start_index => 16,:max_result => 15}
#return Doubapi::Event[]
def self.search_events_of h
	Douban.search_events_of h
end


#input {:singer,:since}
#return Doubapi::Album[]
def self.search_albums_of h 
 	Douban.search_albums_of h 
end

protected 
class Douban 

#instance method
class << self
def douban_get_xml url
	puts url
	#I have forgot why i need to specify the user agend
  doc = open(url, :proxy => nil, 'User-Agent' => 'ruby')
  if doc.nil?
    puts "error:failed to open #{url}"
    return nil;
  end
  
  Nokogiri::HTML(doc,nil, "utf-8")
  
  #Nokogiri::HTML(open(url,:proxy => nil,'User-Agent' => 'ruby'),nil, "utf-8")
	#no network access, used to simulator 
	#doc = File.read(File.join(RAILS_ROOT, "app","controllers","event_sample.xml"))
	#Nokogiri::HTML(doc,nil, "utf-8")
  #Nokogiri::HTML(open(url,:proxy => nil,'User-Agent' => 'ruby'),nil, "utf-8")
end



#return Atom
#Douban search : will return results that does not match 
def search_event h
  puts h.inspect

  key_chinese = h[:key]
  location    = h[:location] || "shanghai"
  start_index = h[:start_index] || 1
  max         = h[:max_result]|| 20

  if (key_chinese.downcase == "all")
	uri="http://api.douban.com/event/location/#{location}?type=music&start-index=#{start_index}&max-results=#{max}"
  else
  keywords= "%" + key_chinese.each_byte.map {|c| c.to_s(16)}.join("%")
  uri="http://api.douban.com/events?q=#{keywords}&location=#{location}&start-index=#{start_index}&max-results=#{max}"
  end

  #Let's grab it slowly to avoid being baned...	
  sleep(7) 	
  douban_get_xml(uri)
end

def search_ablum h
  artist_chinese = h[:singer]
  max=h[:max_result]||10
  keywords= "%" + artist_chinese.each_byte.map {|c| c.to_s(16)}.join("%")
  uri="http://api.douban.com/music/subjects?tag=#{keywords}&start-index=1&max-results=#{max}"
  #Let's grab it slowly to avoid being baned...	
  sleep(7) 	
  douban_get_xml(uri)
end


#TODO
def looks_like_a_live_show? e, artist

	#check e.when should happen
	#2010-08-13F21:30:00+08:00
	_,_,_,hour = e.when.scan(/\d{1,4}/);

	if artist.downcase == "all"
		return true if hour.to_i > 18
	else
		return true if hour.to_i > 18 and e.what.include?(artist) 
	end

	return false
end

#return true if a >= b
#a,b could be one of the following format
#2010.01
#2010.1
#2010#1
#2010-1
#2010年1
def compare_date a , b
	ya, ma = a.scan(/\d{1,4}/)
	yb, mb = b.scan(/\d{1,4}/)
	return true if (ya.to_i * 12 + ma.to_i ) >= (yb.to_i*12+mb.to_i)
end


def formate_release_date release_date
   	#make release data YY-MM-DD style
  	r = release_date.scan(/\d{1,4}/)
  	#if DD was not specified
  	r << "01"         if r.size == 2
  	r << "01" << "01" if r.size == 1

  	y , m , d = r

  	m = "01" unless (1..12).include?(m.to_i) 
  	d = "01" unless (1..30).include?(d.to_i)
  	
  	"#{y}-#{m}-#{d}" 
end

def search_albums_of h 
  artist = h[:singer]
  after_date = h[:since]||"1900.01"
  doc = search_ablum h
 
  if(doc.nil?) 
    return [];
  end
  
  albums=[]
  doc.xpath("//entry").each do |entry|
  	title = entry.at_xpath(".//title").text
  	#author
  	authorItem = entry.at_xpath(".//name")
  	author = if authorItem.nil? then artist else authorItem.text end
  	#link - pc web
		link =  entry.at_xpath(".//link[@rel='alternate']")["href"]
	  cover_thumnail = entry.at_xpath(".//link[@rel='image']")["href"]
	  #publisher
  	pubItem = entry.at_xpath(".//attribute[@name='publisher']")
  	publisher = if pubItem.nil? then "unknow" else pubItem.text end
    #link - mobile_site
  	mobile_site = entry.at_xpath(".//link[@rel='mobile']")["href"]
    #release_date
    pubDateItem = entry.at_xpath(".//attribute[@name='pubdate']")
    release_date = if pubDateItem.nil? then "0000-00" else pubDateItem.text end
  	formated_release_day = formate_release_date(release_date)
  	#check the release date
  	if compare_date release_date, after_date			
  		albums << Doubapi::Album.new(author, title, formated_release_day, link, cover_thumnail,publisher,mobile_site)
  	end
  end
  albums
end


  #return Time object
  #date format is
  #"时间：2010年8月13日 周五 21:30 -  23:55"
  #or
  #2010-08-13F21:30:00+08:00
  def parse_date date
    year, month , day = date.scan(/\d{1,4}/)
    Time.local(year,month,day)
  end

def search_events_of(h={})
  
  puts h.inspect
  artist = h[:key]
  after_date =  h[:after_date]||Time.now.strftime("%Y-%m")
  doc = search_event h
  events=[]
  doc.xpath("//entry").each do |entry|
    #pp entry
    title = entry.at_xpath(".//title").text
    #attribute is starttime NOT startTime as specified in the xml
    start_time = entry.at_xpath('.//when')["starttime"]
    #  city = entry.at_xpath('.//location').text
    where = entry.at_xpath('.//where')["valuestring"]
    link =  entry.at_xpath(".//link[@rel='alternate']")["href"]
    what = entry.at_xpath(".//content").text

	#check the date
	if parse_date(start_time) > parse_date(after_date)
	    events << Doubapi::Event.new(title, start_time, where, what, link)
    end
  end
	
  #filtering of the results
  events.select{|e| looks_like_a_live_show?(e,artist)}
end

end #self,instance method end
end #Class Douban

end #Module  
