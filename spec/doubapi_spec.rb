#encoding: utf-8
require 'doubapi'
describe Doubapi do 

	it "should be able to search 许巍 " do 
		key = "许巍"
		Doubapi.search_events_of(key).each do |event|
				event.what.should be_include(key)
				puts event.title
				puts event.when
				puts event.where
				puts event.link
		end	
	end

	it "should be able to search albums of 李志 " do 
		author = "李志"
		Doubapi.search_albums_of(author).each do |album|
			puts album.author	
			puts album.release_date	
			puts album.title	
			puts album.link	
		end
	end

	it "should be able to search albums of 李志 that released after 2010 " do 
		author = "李志"
		Doubapi.search_albums_of(author, "2010-05").each do |album|
			puts album.author	
			puts album.release_date	
			puts album.title	
			puts album.link	

		   album.release_date.should >= "2010-05"
		end
	end


	it "should be handle the search results that have no author node" do 
		author = "何勇"
		Doubapi.search_albums_of(author, "2010/01").each do |album|
			puts album.author	
			puts album.release_date	
			puts album.title	
			puts album.link	
		end

	end


	it "should not return NULL release_date " do 
        author = "小河"
		Doubapi.search_albums_of(author, "2010/01").each do |album|
			puts album.author	
			puts album.release_date	
			puts album.title	
			puts album.link	
		end

	end


   it "should be able to search all the shows in 育音堂 and the event.when should later than the time when the search happened if after_date has not specified" do
		key = "育音堂"
		Doubapi.search_events_of(key).each do |event|
				event.what.should be_include(key)
				puts event.title
				puts event.when
				puts event.where
				puts event.link
		end	
   end

	it "should search all the music events if no artist is specified" do 

		Doubapi.search_events_of("all").each do |event|
				puts event.title
				puts event.when
				puts event.where
				puts event.link
		end	

    end

end
