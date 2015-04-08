
class CreatePerson < ActiveRecord::Migration
  def self.up
    drop_table(:people) if Person.table_exists?
    create_table :people do |t|
      t.integer :ACSYR
      t.integer :SERIALP
      t.integer :PERNUM
      t.integer :PERWT
      t.integer :RELATE
      t.integer :SEX
      t.integer :AGE
      t.integer :MARST
      t.integer :RACE
      t.integer :HISPAN
      t.integer :BPL
      t.integer :YRIMMIG
      t.integer :SPEAKENG
      t.integer :RACESING
      t.integer :TOTINC
      t.integer :INCINVST
      t.integer :line_number
      t.string :record_type
    end

    add_index :people, :serialp
  end
end

class CreateHousehold < ActiveRecord::Migration
  def self.up
    drop_table(:households) if Household.table_exists?
    create_table :households do |t|
      t.integer :ACSYR
      t.integer :SERIAL
      t.integer :HHWT
      t.integer :HHTYPE
      t.integer :STATEICP
      t.integer :METAREA
      t.integer :METAREAD
      t.integer :CITY
      t.integer :CITYPOP
      t.integer :GQ
      t.integer :OWNERSHP
      t.integer :OWNERSHPD
      t.integer :MORTGAGE
      t.integer :MORTGAG2
      t.integer :ACREHOUS
      t.integer :MORTAMT1
      t.integer :MORTAMT2
      t.integer :TAXINCL
      t.integer :INSINCL
      t.integer :PROPINSR
      t.integer :OWNCOST
      t.integer :RENT
      t.integer :RENTGRS
      t.integer :CONDOFEE
      t.integer :HHINCOME
      t.integer :VALUEH
      t.integer :line_number
      t.string :record_type
    end
    add_index :households, :serial
  end
end
