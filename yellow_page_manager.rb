# -*- coding: utf-8 -*-
require_relative 'gtk_helper'
require_relative 'list_edit_dialog'
require_relative 'type'

class YellowPageManager < ListEditDialog
  include Gtk
  include GtkHelper

  def initialize(parent)
    table = intern(::Settings[:YELLOW_PAGES])

    super(parent,
          title: 'YP 設定',
          table: table,
          headers: ['有効', '名前', 'URL', 'チャット有', '統計有'],
          types: [:toggle, :text, :text, :toggle, :toggle],
          editable: [true, true, true, true, true])

    signal_connect 'response', &method(:on_response)
  end

  def intern(yellow_pages)
    yellow_pages.as([[::Object, String, String, ::Object, ::Object]])
      .map do |enabled, name, url, chat, stat|
      [enabled, name, url, chat.to_bool, stat.to_bool]
    end
  end

  def extern(rows)
    rows.as([[::Object, String, String, ::Object, ::Object]])
      .map do |enabled, name, url, has_chat, has_stat|
      [enabled, name, url,
       has_chat ? 'chat.php?cn=' : nil,
       has_stat ? 'getgmt.php?cn=' : nil]
    end
  end

  def on_response(_, response_id)
    case response_id
    when RESPONSE_OK
      ::Settings[:YELLOW_PAGES] = extern result
      ::Settings.save
    end

    destroy
  end
end
