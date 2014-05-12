# -*- coding: utf-8 -*-
require 'gtk2'
require_relative 'settings'
require_relative 'utility'
require_relative 'object_list'
require_relative 'type_assoc_dialog'
require_relative 'gtk_helper'

class SettingsDialog < Gtk::Dialog
  include Gtk, GtkHelper

  def show_message(message, title, kind = MessageDialog::ERROR)
    md = MessageDialog.new(self,
                           Dialog::DESTROY_WITH_PARENT,
                           MessageDialog::ERROR,
                           MessageDialog::BUTTONS_OK,
                           message)
    md.title = title
    md.run do |response|
      md.destroy
    end
  end

  def initialize(parent)
    # ピアキャストのポート番号、動画プレーヤーのパス？
    super("設定", parent, Dialog::MODAL)
 
    set border_width: 5, resizable: false
    vbox.set(spacing: 10)

    table = create(Table, 2, 2, row_spacings: 5, column_spacings: 10)

    @peercast_entry = create(Entry, no_show_all: true, text: ::Settings[:USER_PEERCAST])
    @file_assoc_button = create(Button, '設定', on_clicked: method(:cb_file_assoc_button_clicked))
    @font_button = create(FontButton, ::Settings[:LIST_FONT])
    @bandwidth_check_button = create(CheckButton, active: ::Settings[:ENABLE_AUTO_BANDWIDTH_CHECK])
    @grid_combo_box = create(ComboBox) do |combobox|
      ["なし", "横", "縦", "両方"].each_with_index do |word, idx|
        combobox.append_text word
      end
      combobox.active = ::Settings[:GRID_LINES]
    end
    @rules_check_button = create(CheckButton, active: ::Settings[:RULES_HINT])

    definition = [
                  [head("接続先 Peercast ノード"), @peercast_entry],
                  [head("プレーヤー"), @file_assoc_button],
                  [head("自動帯域チェック"), @bandwidth_check_button],
                  [head("リストのフォント"), @font_button],
                  [head("罫線"), @grid_combo_box],
                  [head("交互に暗色", "一行ごとに背景を暗くする(テーマ依存)"), @rules_check_button],
                 ]

    definition.each_with_index do |row, y|
      row.each_with_index do |widget, x|
        table.attach_defaults(widget,
                              x, x+1,
                              y, y+1)
      end
    end

    vbox.pack_start(table)
    vbox.pack_end(HSeparator.new)

    add_button(Stock::CANCEL, Dialog::RESPONSE_CANCEL)
    add_button(Stock::OK, Dialog::RESPONSE_OK)

    set_alternative_button_order [RESPONSE_OK, RESPONSE_CANCEL]

    signal_connect("response") do |d, res|
      case res
      when Dialog::RESPONSE_OK
        ::Settings[:USER_PEERCAST] = @peercast_entry.text
        ::Settings[:LIST_FONT] = @font_button.font_name
        ::Settings[:ENABLE_AUTO_BANDWIDTH_CHECK] = @bandwidth_check_button.active?
        ::Settings[:GRID_LINES] = @grid_combo_box.active
        ::Settings[:RULES_HINT] = @rules_check_button.active?
        ::Settings.save
      end
      destroy
    end
  end

  def cb_file_assoc_button_clicked button
    dialog = TypeAssocDialog.new(self, ::Settings[:TYPE_ASSOC]).show_all
    dialog.run do |response|
      case response
      when RESPONSE_OK
        ::Settings[:TYPE_ASSOC] = dialog.type_assoc
      end
      dialog.destroy
    end
  end

  def show_all
    super
    @peercast_entry.show
  end
end
