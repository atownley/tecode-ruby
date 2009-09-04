require 'tecode'
require 'tecode/ui/gtk'

include TECode::Table

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

hash = { "one" => 1, "two" => 2, "three" => 3 }
model = TECode::UI::HashTableModel.new(hash)

table = TECode::UI::Gtk::TableView.new
widget = table.widget
table.model = model
dump_model(model)

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
