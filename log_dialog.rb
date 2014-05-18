# -*- coding: utf-8 -*-
# 動作ログを表示するダイアログだがたいてい無効にされている。
class LogDialog < Gtk::Dialog
  include Gtk
  include GtkHelper

  def initialize(parent)
    super('ログ', parent, MODAL)

    create(TextView,
           create(TextBuffer, text: $stdout.string),
           wrap_mode: TextTag::WRAP_CHAR) do |textview|
      create(ScrolledWindow,
             hscrollbar_policy: POLICY_AUTOMATIC,
             vscrollbar_policy: POLICY_ALWAYS) do |scrolledwindow|
        scrolledwindow.add textview
        vbox.pack_start scrolledwindow
      end
    end
    set_default_size(512, 384)

    add_button(Stock::OK, RESPONSE_OK)

    signal_connect('response') do
      destroy
    end
  end
end
