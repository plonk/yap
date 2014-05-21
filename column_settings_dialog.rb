# -*- coding: utf-8 -*-
require_relative 'gtk_helper'
require_relative 'list_edit_dialog'
require_relative 'type'

# カラム設定ダイアログ
class ColumnSettingsDialog < ListEditDialog
  include Gtk
  include GtkHelper

  def initialize(parent)
    table = intern(::Settings[:COLUMN_PREFERENCE])
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

  def intern(enabled_ids)
    all_ids = (0..ColumnSet::NUM_IDS - 1).to_a
    disabled_ids = all_ids - enabled_ids

    enabled_ids.map { |column_id| [true, ColumnSet::ID_TO_NAME[column_id]] } +
      disabled_ids.map { |column_id| [false, ColumnSet::ID_TO_NAME[column_id]] }
  end

  def name_to_id(name)
    result = ColumnSet::ID_TO_NAME.index(name)
    fail 'something wrong' unless result
    result
  end

  def extern(rows)
    rows.flat_map do |enabled, name|
      enabled ? [name_to_id(name)] : []
    end
  end

  def on_response(_, response_id)
    case response_id
    when RESPONSE_OK
      ::Settings[:COLUMN_PREFERENCE] = extern result
      ::Settings.save
    end

    destroy
  end
end
