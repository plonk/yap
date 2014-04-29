require 'gtk2'

window = Gtk::Window.new
menu = Gtk::Menu.new
menu.append(Gtk::MenuItem.new("Test1"))
menu.append(Gtk::MenuItem.new("Test2"))

menu.show_all
window.add_events(Gdk::Event::BUTTON_PRESS_MASK)
window.signal_connect("button_press_event") do |widget, event|
  if (event.button == 3)
    menu.popup(nil, nil, event.button, event.time)
  end	
end
window.set_default_size(300, 100).show_all

window.signal_connect('delete_event') {
  menu.destroy # ruby 1.9.1p129 gets segmentation fault without this line
  Gtk.main_quit
}

Gtk.main
