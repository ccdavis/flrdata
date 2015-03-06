$LOAD_PATH.unshift File.dirname(__FILE__)

require 'active_record'

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

  create_database
  import(data_to_import)
end


