# -*- coding: utf-8 -*-
require 'gtk2'
require_relative 'gtk_helper'
require_relative 'list_edit_view'

# 二次元のリストを受け取って編集するためのダイアログウィンドウ。
class ListEditDialog < Gtk::Dialog
  include Gtk
  include GtkHelper

  def do_layout(options)
    @treeview = ListEditView.new(self, options)

    create(HBox, spacing: 5) do |hbox|
      create(ScrolledWindow,
             hscrollbar_policy: POLICY_AUTOMATIC,
             vscrollbar_policy: POLICY_AUTOMATIC) do |sw|
        sw.add @treeview

        @scrolled_window = sw
        hbox.pack_start(sw, true)
      end

      create(ObjectListControlBox, @treeview) do |control_box|
        hbox.pack_start(control_box, false)
      end

      vbox.pack_start(hbox, true)
    end

    add_buttons
  end

  def add_buttons
    add_button(Stock::CANCEL, RESPONSE_CANCEL)
    @ok_button = add_button(Stock::OK, RESPONSE_OK)

    set_alternative_button_order [RESPONSE_OK, RESPONSE_CANCEL]
  end

  def result
    @treeview.result
  end

  def initialize(parent_window, options)
    super(options[:title] || 'List Edit Dialog', parent_window)

    do_layout(options)
    update_size_request
  end

  def update_size_request
    width, height = @treeview.size_request
    @scrolled_window.set_size_request width + 15, height + 30
  end
end
