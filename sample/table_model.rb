require 'tecode'

def dump_model(model)
  model.each_row do |row|
    s = "| "
    row.each do |col|
      s << "#{col}"
      s << ", " if col != row[-1]
    end
    puts s << " |"
  end
end

puts "Initialization of array model"
amodel = TECode::Table::ArrayTableModel.new(3)
amodel.enable_type_conversion = false
amodel.append_row %w( one two three )
amodel.append_row [ 1, 2, 3 ]
amodel.append_row %w( un du troi )
dump_model(amodel)

puts "Modification of array model"
amodel.set_value_for(2, 0, "new")
amodel.set_value_for(1, 1, "bar")
amodel.new_row_at(3)
amodel.set_value_for(3, 0, "arf")
amodel.set_value_for(3, 1, "dog")
amodel.set_value_for(3, 2, "woof")
dump_model(amodel)

puts "Initialization of hash model"
hash = { "one" => 1, "two" => 2, "three" => 3 }
hmodel = TECode::Table::HashTableModel.new(hash)
hmodel.enable_type_conversion = false
dump_model(hmodel)
puts hash.inspect

puts "Modification of hash model"
hmodel.set_value_for(2, 0, "new")
hmodel.set_value_for(1, 1, "bar")
hmodel.new_row_at(3)
hmodel.set_value_for(3, 0, "arf")
hmodel.set_value_for(3, 1, "dog")
dump_model(hmodel)
puts hash.inspect

class Person
  attr_accessor :name, :age, :sex
  def initialize(name, age, sex)
    @name, @age, @sex = name, age, sex
  end
end

puts "Initialization of object model"
omodel = TECode::Table::ObjectTableModel.new(Person, [:name, :age, :sex])
class <<omodel
  def create_row(sender)
    Person.new(nil, nil, nil)
  end
end
omodel.row_factory = omodel

omodel.append_row(Person.new("bart", 8, "male"))
omodel.append_row(Person.new("homer", 40, "male"))
omodel.append_row(Person.new("lisa", 6, "female"))
dump_model(omodel)

puts "Modification of object model"
omodel.set_value_for(0, 1, 10)
omodel.set_value_for(2, 1, 8)
dump_model(omodel)
