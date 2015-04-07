require './import.rb'
require 'builder'


connect_to_database



chart_data =ActiveRecord::Base.connection.select_all("
  select acsyr, ownershp, sum(hhwt/100) 
	from households 
	where  hhtype between 1 and 7 
	group by acsyr, ownershp"
  	)
  	
  	f = File.open("national_own_to_rent.html","w")
f.puts   html_table(chart_data.to_hash).to_s
f.close

chart_data =ActiveRecord::Base.connection.select_all("select acsyr, ownershp, sum(hhwt/100) as nhouseholds, 
  	round(sum(valueh * (hhwt/100))/sum(hhwt/100))   as homevalue
	  from households 
	  where  hhtype >= 1 and hhtype <=7 and city = 5350     	
  	group by acsyr, ownershp")
  	


f = File.open("phoenix_own_to_rent_and_home_value.html","w")
f.puts  html_table(chart_data.to_hash).to_s
f.close


# Now chart it

