# -*- coding: utf-8 -*-
require 'gtk2'
require_relative 'utility'
require_relative 'gtk_helper'

class LinePrompt < Gtk::Dialog
  include Gtk, GtkHelper
  attr_accessor :validator

  def initialize(title = 'ラインプロンプト', parent = nil, mode = MODAL)
    super(title, parent, mode)

    add_button(Stock::CANCEL, RESPONSE_CANCEL)
    @ok_button = add_button(Stock::OK, RESPONSE_OK)

    set_alternative_button_order [RESPONSE_OK, RESPONSE_CANCEL]

    vbox.spacing = 10
    @entry = create(Entry,
                    on_activate: method(:on_entry_activate),
                    on_changed: method(:on_entry_changed))
    vbox.pack_start(@entry, false)

    vbox.pack_end(HSeparator.new, false)

    signal_connect('show', &method(:on_show))

    self.validator = proc { |text| true }
  end

  def on_show(dialog)
    @ok_button.sensitive = validator.call('')
  end

  def on_entry_changed(entry)
    @ok_button.sensitive = validator.call(entry.text)
  end

  def on_entry_activate(entry)
    if validator.call(entry.text)
      response(RESPONSE_OK)
    end
  end

  def text
    @entry.text
  end
end
