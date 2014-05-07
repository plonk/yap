# -*- coding: utf-8 -*-
require 'gtk2'
require_relative 'utility'

class Notification < Gtk::InfoBar
  include Gtk, GtkHelper

  def initialize
    super

    set_no_show_all true
    @info_bar_label = create(Label, "", wrap: true)
    @info_bar_label.show
    add_button Stock::OK, Dialog::RESPONSE_OK
    content_area.pack_start @info_bar_label

    signal_connect("response", &method(:on_response))
  end

  def on_response widget, res
    case res
    when Dialog::RESPONSE_OK
      hide
    else
      fail "unexpected response"
    end
  end


  def put_up(message)
    @info_bar_label.text = message

    show
    # 一定時間後に自動的に閉じる。
    Thread.new do
      sleep $NOTIFICATION_AUTO_CLOSE_TIMEOUT
      Gtk.queue { hide if @info_bar_label.text == message }
    end
  end
end

