require 'tecode'
require 'tecode/ui/gtk'

include TECode

def dump_model(model)
  model.each_row do |row|
    s = "| "
    row.each do |col|
      s << "#{col.class}:#{col}"
      s << ", " if col != row[-1]
    end
    puts s << " |"
  end
end

class Person
  attr_accessor :name, :age, :sex, :married
  def initialize(name, age, sex, married)
    @name, @age, @sex, @married = name, age, sex, married
  end
end

model = ObjectTableModel.new(Person, [:name, :age, :sex, :married])
class <<model
  def create_row(sender)
    Person.new(nil, nil, nil, nil)
  end
end
model.row_factory = model

model.append_row(Person.new("bart", 8, "male", false))
model.append_row(Person.new("homer", 40, "male", true))
model.append_row(Person.new("lisa", 6, "female", false))

table = TECode::UI::Gtk::TableView.new
widget = table.widget
table.model = model

window = Gtk::Window.new
window.set_default_size(250, 150)
window.border_width = 5 
window.signal_connect("destroy") do
  Gtk.main_quit
  dump_model(model)
end

window.add(widget)
window.show_all
Gtk.main
