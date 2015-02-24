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

when importing only a few records, performance will be unacceptable as the size of the import grows to a few thousand records.

What's needed is a way to avoid:  (1) Instantiating all records as ActiveRecord objects, and (2) Issuing an insert statement to the database for each of those records. . The 'activerecord-import'  gem groups the inserts and, optionally, avoids instantiation into an ActiveRecord object altogether. In essence 'activerecord-import' allows you to pass in a large set of data as arrays or hashes or AR objects and do one insert for the lot of them. Doing this improves import time by around fifty times. The speed-up will depend on the database type, hardware, validations (they can be enabled or disabled.)  Passing data to 'import' as arrays or hashes is substantially faster than passing  ActiveRecord objects.

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

We can package up the buffering logic shown in the code snippets above, along with a way  to manage the various options for passing data to 'import'. In the file 'importer.rb' you can find the source. 


