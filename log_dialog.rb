# -*- coding: utf-8 -*-
class LogDialog < Gtk::Dialog
  include Gtk

  def initialize
    super("ログ", $window, Dialog::MODAL)
    add_button(Stock::OK, Dialog::RESPONSE_OK)
    buf = TextBuffer.new
    buf.text = $log.string
    textview = TextView.new(buf)
    textview.wrap_mode = TextTag::WRAP_CHAR
    scrolledwindow = ScrolledWindow.new
    scrolledwindow.set_policy(POLICY_AUTOMATIC, POLICY_ALWAYS)
    scrolledwindow.add textview
    vbox.pack_start scrolledwindow
    set_default_size(512, 384)
    signal_connect("response") do |d, res|
      destroy
    end
  end
end

