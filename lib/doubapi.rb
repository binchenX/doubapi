require 'rubygems'  #a hack to require failure for nokogiri
require 'open-uri'
require 'nokogiri'
require 'pp'


module Doubapi
#return a Nokogiri XML  object
#use Douban API


Event =  Struct.new :title, :when, :where, :what, :link
#release_date is in the format of YY-MM-DD
Album =  Struct.new :author, :title, :release_date,  :link


#return Doubapi::Event[]
def self.search_events_of artist , after_date =  Time.now.strftime("%Y-%m")
	Douban.search_events_of artist, after_date
end



#return Doubapi::Album[]
def self.search_albums_of artist , after_date = "1900.01"
	Douban.search_albums_of artist ,after_date
end

protected 
class Douban 

#instance method
class << self
def douban_get_xml url
	puts url
	#I have forgot why i need to specify the user agend
    doc = open(url, :proxy => nil, 'User-Agent' => 'ruby')
    Nokogiri::HTML(doc,nil, "utf-8")
    #Nokogiri::HTML(open(url,:proxy => nil,'User-Agent' => 'ruby'),nil, "utf-8")
	#no network access, used to simulator 
	#doc = File.read(File.join(RAILS_ROOT, "app","controllers","event_sample.xml"))
	#Nokogiri::HTML(doc,nil, "utf-8")
    #Nokogiri::HTML(open(url,:proxy => nil,'User-Agent' => 'ruby'),nil, "utf-8")
end



#return Atom
#Douban search : will return results that does not match 
def search_event key_chinese, location = "shanghai" ,max=20

  if (key_chinese.downcase == "all")
	uri="http://api.douban.com/event/location/#{location}?type=music&start-index=1&max-results=#{max}"
  else
  keywords= "%" + key_chinese.each_byte.map {|c| c.to_s(16)}.join("%")
  uri="http://api.douban.com/events?q=#{keywords}&location=#{location}&start-index=1&max-results=#{max}"
  end

  #Let's grab it slowly to avoid being baned...	
  sleep(7) 	
  douban_get_xml(uri)
end

def search_ablum artist_chinese ,max=10
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

def search_albums_of artist , after_date = "1900.01"
	doc = search_ablum artist
	albums=[]

	doc.xpath("//entry").each do |entry|
		title = entry.at_xpath(".//title").text
		author = unless entry.at_xpath(".//name").nil?
				 entry.at_xpath(".//name").text
			     else
				 "unknown(#{artist}?)"
				 end
		release_date = unless entry.at_xpath(".//attribute[@name='pubdate']").nil?
							entry.at_xpath(".//attribute[@name='pubdate']").text
					   else
							#means unknow
							"0000-00"
					   end
    	link =  entry.at_xpath(".//link[@rel='alternate']")["href"]
    
		#make release data YY-MM-DD style
		r = release_date.scan(/\d{1,4}/)
		#if DD was not specified
		r << "01"         if r.size == 2
		r << "01" << "01" if r.size == 1
	
		y , m , d = r

		m = "01" unless (1..12).include?(m.to_i) 
		d = "01" unless (1..30).include?(d.to_i) 

		formated_release_day = "#{y}-#{m}-#{d}" 
		#check the release date
		if compare_date release_date, after_date			
			albums << Doubapi::Album.new(author, title, formated_release_day, link)
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

def search_events_of artist , after_date =  Time.now.strftime("%Y-%m")

  doc = search_event artist
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
