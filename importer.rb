

require 'hflr'
require 'activerecord-import'

class Importer
  RowGroupSize = 25_000

  def initialize(model, validate,  fields = nil)
    @validate = validate
    @model = model
    @rows = []
    @fields = fields
    @input_records_type = @fields ? :array : :active_record
    @total_rows_imported = 0
  end

  def <<(record)
    @rows << record
    if @rows.size % RowGroupSize == 0
      @total_rows_imported += RowGroupSize
      import_row_group(@rows)
      @rows = []
      #puts "imported #{@total_rows_imported}"
    end
  end

  def import_row_group(rows)
    # Using predetermined field order.  Structs will also work here.
    if @input_records_type == :array
      @model.import(@fields, @rows, validate: @validate)
    else      
      # Here the order of fields was not known in advance
      # puts "Data looks like: " + rows.first.inspect
      #    $log.info("Data looks like #{rows.first.inspect}")
      if rows.first.respond_to?(:keys)
        @model.import(@rows.map { |r| @model.new(r) }, validate: @validate)
      else if  rows.first.respond_to?(:members)
      
      fields =  @rows[1].members.map{|s| s.to_s}      
        @model.import(fields,@rows.map{|r| r.to_a},:validate=>false)
        else
          raise "Record is an unhandled type #{rows.first.class}"
          end
        end
    end
  end

  def close
    import_row_group(@rows)
  end
end
