# -*- coding: utf-8 -*-
require_relative 'gtk_helper'
require_relative 'list_edit_dialog'
require_relative 'type'

# カラム設定ダイアログ
class ColumnSettingsDialog < ListEditDialog
  include Gtk
  include GtkHelper

  def initialize(parent)
    table = [[true, 'チャンネル名'],
             [false, '人数']]
    super(parent,
          title: 'カラム設定',
          table: table,
          headers: ['有効', '名前'],
          types: [:toggle, :text],
          editable: [true, false],
          movable_rows: true,
          allow_add: false,
          allow_delete: false)

    signal_connect 'response', &method(:on_response)
  end

  def intern(rows)
  end

  def extern(rows)
  end

  def on_response(_, response_id)
    case response_id
    when RESPONSE_OK
      # ::Settings[:COLUMN_SETTINGS] = extern result
      # ::Settings.save
    end

    destroy
  end
end
