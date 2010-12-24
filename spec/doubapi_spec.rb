require 'lib/doubapi'
describe Doubapi do 

	it "should be able to search " do 
		Doubapi.search_events_of("eagles").each do |event|
				event.what.should include?("eagles")
		end	
	end



end
