## Fixed Length Record Data (Part Two)

Last time I discussed the FLR format and showed how  to use the 'hflr' gem to read in this format and produce Ruby structs.

In this post I'll demonstrate how to combine 'hflr' with a simple importer class to load a database with the FLR data. Then I'll show you how to get some real-world FLR data to import.

####  Efficiently Import Data

While one could simply write code such as
```ruby

flr_file.each_record do |record|
  customer = Customer.new
  customer.name = record.name
  customer.street = record.street
  customer.zip = record.zip
  customer.save
  
end
```

when importing only a few records, performance will degrade unacceptable as the size of the import grows to a few thousand records.

What's needed is a way to avoid:  (1) Instantiating all records as ActiveRecord objects, and (2) Issuing an insert statement to the database for each of those records. . The 'activerecord-import'  gem groups the inserts and, optionally, avoids instantiation into ActiveRecord objects altogether. In essence 'activerecord-import' allows you to pass in a large set of data as arrays or hashes or AR objects and do one insert for the lot of them. Doing this improves import time by around fifty times. The speed-up will depend on the database type, hardware, validations (they can be enabled or disabled.)  Passing data to 'import' as arrays or hashes is substantially faster than passing  ActiveRecord objects.

Using activerecord -import, Your code would look like

```ruby

  records_to_import = []
  batch_size = 20_000
  fields = [:name, :street, :zip]
  
   flr_file.each_record do |record|
     records_to_import << record.to_a
     if records_to_import % batch_size == 0
       Customer.import(records_to_import,fields)
       records_to_import = []
     end
   end
   
   Customer.import(records_to_import,fields)

```

The 'import' method can take an array of arrays, and a 'fields' argument giving the order of fields in each inner array. Alternatively 'import' may take an array of hashes, removing the necessity for the 'fields' argument as the names of fields and their values are linked in the hashes.

You may instead pass in already instantiated Active Record models, but this will be slower than the first two options.

We can package up the buffering logic shown in the code snippets above, along with a way  to manage the various options for passing data to 'import'. In the file 'importer.rb' you can find the full source. <a href="https://github.com/ccdavis/flrdata"> flrdata example code on github.com</a>. 

#### Example Data

In the Git repository there's an 'input_data' directory with a sample data file 'usa_00001.dat'.  This is a slice of a much larger data file created with the IPUMS-USA data extraction service. The dataset will let us study the housing boom, bust and recovery. The data comes from the American Community Survey, covering the years 2001 to 2013. We have both household records and person records in this dataset. We can create some interesting tables using just the household records, but some tabulations will require the people associated with those households. 

To learn more about the IPUMS and to recreate the full 3.3 GB dataset in our example, See <a href="http://usa.ipums.org"> usa.ipums.org</a>. You may browse the system  and begin requesting data without signing in, but to get your data you must create a free account. 

The 'codebook.txt' and 'usa_0001.sps' files were created by the data extract system and were downloaded with the data file. The 'codebook.txt' is a human readable description of the data file, and the .sps file is for the SPSS statistics analysis software to read, to help you to use the data in SP SS. The extract system also produces files for SAS and Stata. For extracts with only one record type, the extraction service offers CSV and native binary formats of all three stats  applications.

To figure out what to pass to the FLRFile class initializer, you'd look at the code book or possibly the SPSS file supplied with the dataset:

```

record type "H".
data list /
  RECTYPE    1-1 (a)
  YEAR       2-5
  DATANUM    6-7
  SERIAL     8-15
  HHWT       16-25 (2)
  HHTYPE     26-26
  STATEICP   27-28
  METAREA    29-31
  METAREAD   32-35
  CITY       36-39
  CITYPOP    40-44
  GQ         45-45
  OWNERSHP   46-46
  OWNERSHPD  47-48
  MORTGAGE   49-49
  MORTGAG2   50-50
  ACREHOUS   51-51
  MORTAMT1   52-56
  MORTAMT2   57-60
  TAXINCL    61-61
  INSINCL    62-62
  PROPINSR   63-66
  OWNCOST    67-71
  RENT       72-75
  RENTGRS    76-79
  CONDOFEE   80-83
  HHINCOME   84-90
  VALUEH     91-97
.

record type "P".
data list /
  RECTYPE    1-1 (a)
  YEAR       2-5
  DATANUM    6-7
  SERIAL     8-15
  PERNUM     16-19
  PERWT      20-29 (2)
  RELATE     30-31
  RELATED    32-35
  SEX        36-36
  AGE        37-39
  MARST      40-40
  RACE       41-41
  RACED      42-44
  HISPAN     45-45
  HISPAND    46-48
  BPL        49-51
  BPLD       52-56
  YRIMMIG    57-60
  SPEAKENG   61-61
  RACESING   62-62
  RACESINGD  63-64
  INCTOT     65-71
  INCINVST   72-77
.

end file type.

```

This is fairly convenient, and if you regularly needed to        import IPUMS data you might write a simple script to parse this sort of code book. Whatever the source of your FLR data you'll need a description with  comparable information.

To run the example, just do
	
ruby import.rb
	
You may use JRuby instead. The required gems are given at the top of the 'import.rb' file.  

The import process should take a few seconds on the example data included with the example code. The full dataset referenced in the 'codebook.txt' file has approximately thirty-one million person records and fourteen million household records. It will take between one and five hours to import depending on your storage hardware, CPU and  Ruby version.

Once the data has imported we can do a few simple queries. To make effective use of this data you'd need to read documentation at <a href="http://usa.ipums.org"> usa.ipums.org</a>. For now, you just need to know that each household record has a weight variable and each person record has a person weight variable. The value of these variables, in the 'households.HHWT' and 'people.PERWT' columns respectively, indicates the number of people or households the record represents from the larger population, as this dataset is only a sample of the entire United States population. Divide the weight values by 100 (the two least significant digits are fractional amounts) to get a useful whole number version of the weight. For instance, the value 10100 really means "this record represents 101.00 records like it."

So, to see how many people  the U.S. Census estimated were in the country in 2013, you would do:

	sqlite> select sum(PERWT/100) from people where  acsyr =2013;	
	316128839
	sqlite>


With that in mind we can look at a simple but (possibly) revealing statistic, the number of households owned and the number of family (HHTYPE 1..7) households rented by year, OWNERSHP 1 = owned, 2 = rented:

	sqlite> 
	>select acsyr, ownershp, sum(hhwt/100) 
	>from households 
	>where  hhtype between 1 and 7 
	>group by acsyr, ownershp;

This produces a simple set of results for each year in our data extract counting rented and owned households. The table is rather narrow and tall; for easier reading we might like to pivot  the table. Sqlite doesn't have a pivot function but we can do it in Ruby easily enough:

```ruby

chart_data =ActiveRecord::Base.connection.select_all("
  select acsyr, ownershp, sum(hhwt/100) 
	from households 
	where  hhtype between 1 and 7 
	group by acsyr, ownershp"
  	)
  	
def pivot(results)
    (0..results.columns.size-1).map{|column_number|
	results.rows.map{|r| r[column_number]}}
end

# Or, to get names for the new columns...
def pivot_named_fields(results)
  results_hash = results.to_hash
  results_hash
end

# And to format the output nicely for this post... (from SO
def html_table(data)
    xm = Builder::XmlMarkup.new(:indent => 2)
    xm.table {
    xm.tr { data[0].keys.each { |key| xm.th(key)}}
    data.each { |row| xm.tr { row.values.each { |value| xm.td(value)}}}
  }
  xm
end

table_data = html_table(pivot_named_fields(chart_data))

```

<table>
  <tr>
    <th>ACSYR</th>
    <th>OWNERSHP</th>
    <th>sum(hhwt/100)</th>
  </tr>
  <tr>
    <td>2001</td>
    <td>1</td>
    <td>69986392</td>
  </tr>
  <tr>
    <td>2001</td>
    <td>2</td>
    <td>36449626</td>
  </tr>
  <tr>
    <td>2002</td>
    <td>1</td>
    <td>71308121</td>
  </tr>
  <tr>
    <td>2002</td>
    <td>2</td>
    <td>36066963</td>
  </tr>
  <tr>
    <td>2003</td>
    <td>1</td>
    <td>72423984</td>
  </tr>
  <tr>
    <td>2003</td>
    <td>2</td>
    <td>36004362</td>
  </tr>
  <tr>
    <td>2004</td>
    <td>1</td>
    <td>73752623</td>
  </tr>
  <tr>
    <td>2004</td>
    <td>2</td>
    <td>36152252</td>
  </tr>
  <tr>
    <td>2005</td>
    <td>1</td>
    <td>74292694</td>
  </tr>
  <tr>
    <td>2005</td>
    <td>2</td>
    <td>36776465</td>
  </tr>
  <tr>
    <td>2006</td>
    <td>1</td>
    <td>75074799</td>
  </tr>
  <tr>
    <td>2006</td>
    <td>2</td>
    <td>36542589</td>
  </tr>
  <tr>
    <td>2007</td>
    <td>1</td>
    <td>75511557</td>
  </tr>
  <tr>
    <td>2007</td>
    <td>2</td>
    <td>36866406</td>
  </tr>
  <tr>
    <td>2008</td>
    <td>1</td>
    <td>75341616</td>
  </tr>
  <tr>
    <td>2008</td>
    <td>2</td>
    <td>37759745</td>
  </tr>
  <tr>
    <td>2009</td>
    <td>1</td>
    <td>74929333</td>
  </tr>
  <tr>
    <td>2009</td>
    <td>2</td>
    <td>38686859</td>
  </tr>
  <tr>
    <td>2010</td>
    <td>1</td>
    <td>74947705</td>
  </tr>
  <tr>
    <td>2010</td>
    <td>2</td>
    <td>39619744</td>
  </tr>
  <tr>
    <td>2011</td>
    <td>1</td>
    <td>74376307</td>
  </tr>
  <tr>
    <td>2011</td>
    <td>2</td>
    <td>40615408</td>
  </tr>
  <tr>
    <td>2012</td>
    <td>1</td>
    <td>74227189</td>
  </tr>
  <tr>
    <td>2012</td>
    <td>2</td>
    <td>41742391</td>
  </tr>
  <tr>
    <td>2013</td>
    <td>1</td>
    <td>73933462</td>
  </tr>
  <tr>
    <td>2013</td>
    <td>2</td>
    <td>42357512</td>
  </tr>
</table>




Looking at the ratio of rented to owned family households, there's a trend but not, perhaps, as large as one might expect. Let's focus on a particular metro area that got hit hard in the housing bubble. We can select Phoenix (CITY = 5350, or METAREA = 620). The CITY variable is better for comparisons across time, but the METAREA variable will give us the surrounding suburbs. Both are worth looking at. Also, let's
add in the home value for fun. If we want correct values we need to produce our own average, because we need to take the household weights into account. Note that the OWNERSHIP=2  (rented) 
rows have home values of 9999999.0. That's due to the rented householders not being asked their home's value.
  	

```ruby
chart_data = ActiveRecord::Base.connection.select_all("
	select acsyr, ownershp, sum(hhwt/100) as nhouseholds, 
  	round(sum(valueh * (hhwt/100))/sum(hhwt/100))   as homevalue
	  from households 
	  where  hhtype >= 1 and hhtype <=7 and city = 5350     	
  	group by acsyr, ownershp"
  	)
  	
	html_table(pivot_named_fields(chart_data))

```


<table>
  <tr>
    <th>ACSYR</th>
    <th>OWNERSHP</th>
    <th>nhouseholds</th>
    <th>homevalue</th>
  </tr>
  <tr>
    <td>2005</td>
    <td>1</td>
    <td>312952</td>
    <td>250922.0</td>
  </tr>
  <tr>
    <td>2005</td>
    <td>2</td>
    <td>207445</td>
    <td>9999999.0</td>
  </tr>
  <tr>
    <td>2006</td>
    <td>1</td>
    <td>304542</td>
    <td>320586.0</td>
  </tr>
  <tr>
    <td>2006</td>
    <td>2</td>
    <td>191168</td>
    <td>9999999.0</td>
  </tr>
  <tr>
    <td>2007</td>
    <td>1</td>
    <td>319876</td>
    <td>328315.0</td>
  </tr>
  <tr>
    <td>2007</td>
    <td>2</td>
    <td>189989</td>
    <td>9999999.0</td>
  </tr>
  <tr>
    <td>2008</td>
    <td>1</td>
    <td>313865</td>
    <td>312918.0</td>
  </tr>
  <tr>
    <td>2008</td>
    <td>2</td>
    <td>191682</td>
    <td>9999999.0</td>
  </tr>
  <tr>
    <td>2009</td>
    <td>1</td>
    <td>315137</td>
    <td>248589.0</td>
  </tr>
  <tr>
    <td>2009</td>
    <td>2</td>
    <td>212702</td>
    <td>9999999.0</td>
  </tr>
  <tr>
    <td>2010</td>
    <td>1</td>
    <td>295378</td>
    <td>218943.0</td>
  </tr>
  <tr>
    <td>2010</td>
    <td>2</td>
    <td>229112</td>
    <td>9999999.0</td>
  </tr>
  <tr>
    <td>2011</td>
    <td>1</td>
    <td>303044</td>
    <td>205407.0</td>
  </tr>
  <tr>
    <td>2011</td>
    <td>2</td>
    <td>235229</td>
    <td>9999999.0</td>
  </tr>
  <tr>
    <td>2012</td>
    <td>1</td>
    <td>255962</td>
    <td>183820.0</td>
  </tr>
  <tr>
    <td>2012</td>
    <td>2</td>
    <td>232793</td>
    <td>9999999.0</td>
  </tr>
  <tr>
    <td>2013</td>
    <td>1</td>
    <td>247993</td>
    <td>212643.0</td>
  </tr>
  <tr>
    <td>2013</td>
    <td>2</td>
    <td>233793</td>
    <td>9999999.0</td>
  </tr>
</table>


Now that's interesting. 

Notice that we only got results for 2005-2013, because the CITY data wasn't available in the earlier years of the ACS. If you want  data going back earlier you might look at the U.S. Census data aalso available on the IPUMS site.

There's a lot more to uncover in this dataset. For example one might hypothesize that home equity loans drove the swing in home values. WE could look at only those households with second mortgages (variable MORT2.) 
Another trend noticed in some regions was the over-representation of  minorities and recent immigrants in foreclosures. We can't study foreclosures directly with this dataset, but we could look at second mortgages, home values, ethnicity, income and other variables to learn more.  To study this last question you'd need to join the people and households tables, in order to associate characteristics of the head of the household  with the household information we've already used.





