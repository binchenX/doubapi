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
  #author = "李志"
  author = "窦唯"
  total, albums = Doubapi.search_albums_of(:singer=>author,:since=>"1900-05",:max_result => 20) 
  
  #release date decending
  albums.sort {|a , b| b.release_date <=> a.release_date }.each do |album|
    puts "-------------------------------"
    puts album.author	
    puts album.release_date	
    puts album.title	
    puts album.cover_thumbnail
    puts album.publisher
    puts album.link	
    puts album.mobile_site
    puts album.rating

		album.tracks.each do |track|
			puts track.title
		end

		puts album.json
  end
  
  #rating decending
  
  #release date decending
   albums.sort {|a , b| b.rating <=> a.rating }.each do |album|
     puts "-------------------------------"
     puts album.author	
     puts album.release_date	
     puts album.title	
     puts album.cover_thumbnail
     puts album.publisher
     puts album.link	
     puts album.mobile_site
     puts album.rating
   end
  puts "total #{total}"
end 



def test_get_all_events
  
  
  puts "trying to get 30 first"
  
  batch_size = 30;
  totalResults1 = Doubapi.search_events_of(:key => "all", :location => "shanghai", :start_index => 1,:max_result => batch_size) do |event|
   # puts "#{event.when} #{event.title}"
  end
  
  puts "total results #{totalResults1} ,will fetch others"
  
  return if(totalResults1 <= batch_size)
  
  (2..totalResults1/batch_size).each do |i|
    start_index = (i-1)*batch_size+1;
    max_result = batch_size;
    puts "start_index :#{start_index}"
    Doubapi.search_events_of(:key => "all", :location => "shanghai", :start_index => start_index, :max_result => max_result) do |event|
     # puts "#{event.when} #{event.title}"
    end
    
  end
  
  return if((totalResults1%batch_size)==0)
  
  last_fetch_size = totalResults1 - (totalResults1/batch_size)*batch_size;
  
  start_index = (totalResults1/batch_size)*batch_size+1;
  max_result = last_fetch_size;
  puts "start_index :#{start_index}"
  Doubapi.search_events_of(:key => "all", :location => "shanghai", :start_index => start_index, :max_result => max_result) do |event|
   # puts "#{event.when} #{event.title}"
  end
  
  
  
  
    

  
end


def test4
  
  totalResults = Doubapi.search_events_of(:key => "all", :location => "shanghai", :start_index => 1,:max_result => 1) do |event|
    puts "#{event.when} #{event.title}"
    puts event.where
    puts event.link
    puts event.poster_mobile
    puts event.bar_icon
  end
  
  puts "totalResults #{totalResults}"
  
end 

def test5
  
  totalResults ,events = Doubapi.search_events_of(:key => "all", :location => "shanghai", :start_index => 1,:max_result => 5)
  
  events.each do |event|
    puts "#{event.when} #{event.title}"
    puts event.where
    puts event.link
    puts event.poster_mobile
    puts event.bar_icon
  end
  
  puts "totalResults #{totalResults}"
  
end

#test_get_all_events
#test1
test2
#test4
#test5
