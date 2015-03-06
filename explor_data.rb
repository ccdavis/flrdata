chart_data =ActiveRecord::Base.connection.select_all("select acsyr, ownershp, sum(hhwt/100) as nhouseholds, 
  	round(sum(valueh * (hhwt/100))/sum(hhwt/100))   as homevalue
	  from households 
	  where  hhtype >= 1 and hhtype <=7 and metarea = 620     	
  	group by acsyr, ownershp")
  	


def pivot(results)
(0..results.columns.size-1).map{|column_number|
	results.rows.map{|r| r[column_number]}}
end

pivot(chart_data)

# Now chart it

