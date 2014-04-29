# -*- coding: utf-8 -*-
#require "win32/sound"

class HelpDialog < Gtk::Dialog
  include Gtk

  def initialize
    super("ヘルプ", $window, Dialog::MODAL)
    add_button(Stock::OK, Dialog::RESPONSE_OK)
    label = Label.new("なくなった")
    label.width_request = 500
    label.name ="ascii_art"
    self.vbox.pack_start(label)
    signal_connect("response") do |d, response|
      case response
      when Dialog::RESPONSE_OK
        destroy
      end
    end
  end
end
