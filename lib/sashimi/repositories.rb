Dir[File.dirname(__FILE__) + '/repositories/*.rb'].sort.each{|f| require f}
