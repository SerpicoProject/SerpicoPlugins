require 'data_mapper'
require 'dm-migrations'

# /plugins/UDV_Worksheet/udv.db

# Initialize the Master DB
DataMapper.setup(:udv, "sqlite://#{Dir.pwd}/plugins/UDV_Worksheet/udv.db")

class Questions
    include DataMapper::Resource

    property :id, Serial
    property :udv_name, String, :required => true, :length => 200
    property :question, String, :required => true, :length => 200
    property :question_answer, String, :required => false, :length => 200
    property :report_id, Integer, :required => false

end

DataMapper.repository(:udv).auto_migrate!
