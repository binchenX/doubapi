#encoding: utf-8

#use local lib instead of the Gem installed
require './doubapi'


def test1
  key = "许巍" 
  Doubapi.search_events_of(:key=>key).each do |event|
    event.what.should be_include(key)
    puts event.title
    puts event.when
    puts event.where
    puts event.link
  end	

end


def test2
  author = "李志"
  Doubapi.search_albums_of(:singer=>author,:since=>"2010-05").each do |album|
    puts "-------------------------------"
    puts album.author	
    puts album.release_date	
    puts album.title	
    puts album.cover_thumbnail
    puts album.publisher
    puts album.link	
    puts album.mobile_site
  end
end 



def test3
  
  puts "1-30"
  Doubapi.search_events_of(:key => "all", :location => "shanghai", :start_index => 1,:max_result => 30).each do |event|
    puts "#{event.when} #{event.title}"
    #puts event.where
    #puts event.link
  end
  
  puts "1-15"
  
  Doubapi.search_events_of(:key => "all", :location => "shanghai", :start_index => 1,:max_result => 15).each do |event|
    puts "#{event.when} #{event.title}"
    #puts event.where
    #puts event.link
  end
  
  puts "16-30"
  
  Doubapi.search_events_of(:key => "all", :location => "shanghai", :start_index => 16,:max_result => 15).each do |event|
    puts "#{event.when} #{event.title}"
    #puts event.where
    #puts event.link
  end
end


#test3
#test1
test2

