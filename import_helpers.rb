$LOAD_PATH.unshift File.dirname(__FILE__)

require 'active_record'
require 'builder'

require 'household'
require 'person'
require 'schema'
require 'extract_layout'

if defined?(JRUBY_VERSION)
  require 'activerecord-jdbcsqlite3-adapter'
else
  require 'sqlite3'
end

require 'importer'
require 'hflr'

def connect_to_database
  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: 'database.sqlite3'
  )
end

# Take a result set from ActiveRecord::Base.connection.select_all()
def pivot(results)
  (0..results.columns.size - 1).map{|column_number|
    results.rows.map { |r| r[column_number] }
  }
end

def pivot_named_fields(results)
  # Get 'row names' from the column names
  names = results.columns
  pivoted_table = pivot(results)
  table_with_row_names = (0..pivoted_table.size - 1).map{|row_number|
    [names[row_number]] + pivoted_table[row_number]
  }
end

def html_table(data)
  xm = Builder::XmlMarkup.new(indent: 2)
  xm.table {
    xm.tr { data[0].keys.each { |key| xm.th(key) } }
    data.each { |row| xm.tr { row.values.each { |value| xm.td(value) } } }
  }
  xm
end

def pivoted_html_table(data)
  data = pivot_named_fields(data)
  xm = Builder::XmlMarkup.new(indent: 2)
  xm.table {
    xm.tr { data[0].each { |value| xm.th(value) } }
    (1..data.size - 1).map { |row_number| xm.tr { data[row_number].each { |value| xm.td(value) } } }
  }
  xm
end

def create_schema
  CreatePerson.up
  CreateHousehold.up
end

def default_data_to_import
  File.join(File.dirname(__FILE__), 'input_data', 'usa_0001.dat')
end

def import(data_filename)
  puts "Importing data from #{data_filename}"
  household_importer = Importer.new(Household, false)
  person_importer = Importer.new(Person, false)
  input_file = FLRFile.new(
    File.new(data_filename),
    { 'H' => :household, 'P' => :person },
    extract_layout,
    1, # All layout columns are shifted one to the right
    household: [:line_number, :record_type],
    person: [:line_number, :record_type]) # Add these columns to the indicated record types post read

  puts 'Beginning import ...'
  people_imported = 0

  input_file.each do |record|
    household_importer << record if record.record_type == :household
    person_importer << record if record.record_type == :person
    if record.record_type == :person
      people_imported += 1
      if people_imported % 25_000 == 0
        puts "Imported #{people_imported} people so far."
        end
    end
  end

  household_importer.close
  person_importer.close
end

def run_import
  connect_to_database
  create_schema
  data_to_import = ARGV.size > 0 ? ARGV[0] : default_data_to_import

  import(data_to_import)
end
