#
# Copyright (c) 2009-2012 pierr.chen at gmail dot com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'rubygems'  #a hack to require failure for nokogiri
require 'open-uri'
require 'nokogiri'
require 'pp'

require 'json'

#useful information:
#when accessing the the Nokogiri parsed result, all the name are downcase-d
#for example : to access the totalResults element
#<openSearch:totalResults>111</openSearch:totalResults>
#you should use doc.at_xpath(".//totalresults")

#at_xpath  is to return single element and you know only there is only one element.
#xpath is to return an array of elements

class Struct
def to_map
    map = Hash.new
    self.members.each { |m| map[m] = self[m] }
    map
end

def to_json(*a)
    to_map.to_json(*a)
end

def json
    JSON.pretty_generate(self)
end
end
module Doubapi
Event =  Struct.new :title, :when, :where, :what,:link,:poster_mobile,:bar_icon
	
#release_date is in the format of YY-MM-DD
Album =  Struct.new :author, :title, :release_date, :link,:cover_thumbnail,:cover_big,:publisher,:mobile_site,:rating,:tracks

Track = Struct.new :title,:url


#input:{key => "all/singer_name", :location => "shanghai", :start_index => 16,:max_result => 15}
#return total number of events satisfying the search criterion 
#Doubapi::Event[]
def self.search_events_of h ,&block
	totalResult, returnedResult = Douban.search_events_of h 
	
	if block_given?
	  returnedResult.each {|event| block.call(event) if block_given?}
	  return totalResult;
  else
    return [totalResult, returnedResult]
  end
	
end


#input {:singer,:since}
#return total number of events satisfying the search criterion 
#return Doubapi::Album[]
def self.search_albums_of h ,&block
 totalResult, returnedResult =	Douban.search_albums_of_v2 h 
 if block_given?
   returnedResult.each {|album| block.call(album) }
   return totalResult;
 else
   return [totalResult, returnedResult]
 end
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



# use doubapi v2 where json result was returned 
def search_albums_of_v2 h

  artist_chinese = h[:singer]
  max=h[:max_result]||10
  keywords= "%" + artist_chinese.each_byte.map {|c| c.to_s(16)}.join("%")
	url="https://api.douban.com/v2/music/search?q=#{keywords}"
 	#uri="http://api.douban.com/music/subjects?tag=#{keywords}&start-index=1&max-results=#{max}"

	puts "requeset url #{url}"
	#issue http request 
  doc = open(url, :proxy => nil, 'User-Agent' => 'ruby')

	#parse result
	albums = []
	response = JSON.parse(File.read(doc))
	response["musics"].each do |item|
		#select only whose singer eqls artist_chinese
		if item["attrs"]["singer"].include?(artist_chinese)
			m = item["attrs"]
			author = artist_chinese
			title = m["title"].first
			formated_release_day = m["pubdate"].first
			link = mobile_site = item['mobile_link']
			cover_thumnail = cover_big = item['image']
			publisher = m['publisher'].first
			rating = item['rating']['average']
			tracks=[]
			m['tracks'].first.split('\n').each_with_index do |t,index|
				tracks << Doubapi::Track.new(t,nil)
			end

  		albums << Doubapi::Album.new(author, title, formated_release_day, link, 
																	 cover_thumnail,cover_big ,publisher,mobile_site,rating,
																	tracks)
		end 
	end
	[albums.size,albums]
end



#
#search albums tagged with h[:singer]. It is not quite accurate. I have seen some irrevlant result are returned.
#
#
def search_albums_of h 
  artist = h[:singer]
  after_date = h[:since]||"1900.01"
  doc = search_ablum h
 
  if(doc.nil?) 
    return [0,[]];
  end
  
  #the totalResult here trying
  #totalResults = doc.at_xpath(".//totalresults").text.to_i
   
  albums=[]
  doc.xpath("//entry").each do |entry|
  	title = entry.at_xpath(".//title").text
  	#author
  	authorItem = entry.at_xpath(".//name")
  	author = if authorItem.nil? then artist else authorItem.text end
  	#link - pc web
		link =  entry.at_xpath(".//link[@rel='alternate']")["href"]
	  cover_thumnail = entry.at_xpath(".//link[@rel='image']")["href"]
	  
	  #cover big 
	  #example:
	  #thumbnail http://img1.douban.com/spic/s1461123.jpg
	  #big       http://img1.douban.com/lpic/s1461123.jpg
	  cover_big = cover_thumnail.gsub("spic","lpic");
	  
	  #publisher
  	pubItem = entry.at_xpath(".//attribute[@name='publisher']")
  	publisher = if pubItem.nil? then "unknow" else pubItem.text end
  	  
  	#rating
  	rating = entry.at_xpath(".//rating")["average"]
    #link - mobile_site
  	mobile_site = entry.at_xpath(".//link[@rel='mobile']")["href"]
    #release_date
    pubDateItem = entry.at_xpath(".//attribute[@name='pubdate']")
    release_date = if pubDateItem.nil? then "0000-00" else pubDateItem.text end
  	formated_release_day = formate_release_date(release_date)
  	#check the release date
  	if compare_date release_date, after_date			
  		albums << Doubapi::Album.new(author, title, formated_release_day, link, cover_thumnail,cover_big ,publisher,mobile_site,rating)
  	end
  end
  #improve ME
  [albums.size,albums]
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
  artist = h[:key]
  after_date =  h[:after_date]||Time.now.strftime("%Y-%m")
  doc = search_event h
  events=[]
  
  #NOTES:all the key will be downcase-d
  totalResults = doc.at_xpath(".//totalresults").text.to_i
  doc.xpath("//entry").each do |entry|
    #pp entry
    title = entry.at_xpath(".//title").text
    #attribute is starttime NOT startTime as specified in the xml
    start_time = entry.at_xpath('.//when')["starttime"]
    #  city = entry.at_xpath('.//location').text
    where = entry.at_xpath('.//where')["valuestring"]
    link =  entry.at_xpath(".//link[@rel='alternate']")["href"]
    what = entry.at_xpath(".//content").text
    posterItem = entry.at_xpath(".//link[@rel='image-lmobile']")
    poster_mobile = if posterItem.nil? then "empty" else posterItem["href"] end
    authItem = entry.at_xpath(".//author")
    iconLink = if authItem.nil? then nil else authItem.at_xpath(".//link[@rel='icon']") end
    bar_icon = if (iconLink.nil?) then nil else iconLink["href"] end

	#check the date
	if parse_date(start_time) > parse_date(after_date)
	    events << Doubapi::Event.new(title, start_time, where, what, link, poster_mobile, bar_icon)
    end
  end
	
  #filtering of the results
  events.select!{|e| looks_like_a_live_show?(e,artist)}
  
  [totalResults, events]
end

end #self,instance method end
end #Class Douban

end #Module  
