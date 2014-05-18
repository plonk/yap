# -*- coding: utf-8 -*-
require 'gtk2'
require_relative 'utility'
require_relative 'gtk_helper'

class MainWindow < Gtk::Window
  # カスタム InfoBar
  class Notification < Gtk::InfoBar
    include Gtk, GtkHelper
    include DispatchingObserver

    def initialize(model)
      @model = model
      super()

      set_no_show_all true
      @info_bar_label = create(Label, '', wrap: true)
      @info_bar_label.show
      add_button Stock::OK, Dialog::RESPONSE_OK
      content_area.pack_start @info_bar_label

      observer_setup(@model)
      signal_connect('response', &method(:on_response))
    end

    def on_response(_widget, res)
      case res
      when Dialog::RESPONSE_OK
        hide
      else
        fail 'unexpected response'
      end
    end

    def put_up(message)
      @info_bar_label.text = message

      show
      # 一定時間後に自動的に閉じる。
      Thread.new do
        sleep ::Settings[:NOTIFICATION_AUTO_CLOSE_SECONDS]
        Gtk.queue { hide if @info_bar_label.text == message }
      end
    end

    def notification_changed
      put_up(@model.notification)
    end
  end
end
