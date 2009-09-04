require 'tecode'
require 'tecode/ui/gtk'

include TECode::Table

table = TECode::UI::Gtk::TableView.new
table.settings[TECode::UI::Gtk::TableView::SHOW_SENTINAL_ROW] = false
widget = table.widget
table.clear

window = Gtk::Window.new
window.set_default_size(250, 150)
window.border_width = 5 
window.signal_connect("destroy") do
  Gtk.main_quit
end

window.add(widget)
window.show_all
Gtk.main
