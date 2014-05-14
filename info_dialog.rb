# -*- coding: utf-8 -*-
require_relative 'gtk_helper'

# チャンネル情報ダイアログ
class InfoDialog < Gtk::Dialog
  include Gtk, GtkHelper

  def initialize(parent, ch)
    super "#{ch.name}のチャンネル情報", parent, MODAL, [Stock::OK, RESPONSE_NONE]

    do_layout(ch)
  end

  def widget_table(ch)
    [[get_framed_favicon_image(ch), cell(ch.name)],
     [head('リスナー数/リレー数'), cell("#{ch.listener}/#{ch.relay}")],
     [head('TIP'), cell("#{ch.tip}#{get_tip_info(ch.tip)}")],
     [head('コンタクトURL'), cell(ch.contact_url)],
     [head('ID'), cell(ch.id)],
     [head('タイプ'), cell(ch.type)],
     [head('詳細'), cell(ch.detail)],
     [head('ジャンル'), cell(ch.genre)],
     [head('コメント'), cell(ch.comment)]]
  end

  def do_layout(ch)
    rows = widget_table(ch)
    table = create(Table, 2, rows.size, row_spacings: 5, column_spacings: 10)

    rows.each_with_index do |row, y|
      row.each_with_index do |item, x|
        table.attach_defaults(item, x, x + 1, y, y + 1)
      end
    end
    vbox.pack_start(table)
  end

  def get_tip_info(tip)
    return '' unless ::Settings[:REVERSE_LOOKUP_TIP]
    return '' if tip.empty?

    addr, port = tip.split(':')
    begin
      hostname = Resolv.getname(addr)
      "\n(#{hostname}:#{port})"
    rescue
      "\n(reverse lookup failed)"
    end
  end

  def get_framed_favicon_image(ch)
    create Frame do |frame|
      frame.add Image.new favicon_pixbuf_for(ch)
        .scale(64, 64, Gdk::Pixbuf::INTERP_NEAREST)
    end
  end

  def default_icon_pixbuf
    IconFactory.lookup_default('gtk-network')
      .render_icon(style,
                   Widget::TEXT_DIR_RTL,
                   STATE_NORMAL,
                   IconSize::LARGE_TOOLBAR)
  end

  def load_pixbuf(icon_data, fallback)
    Gdk::PixbufLoader.open do |loader|
      loader.write icon_data
      loader.close
      return loader.pixbuf
    end
  rescue
    fallback
  end

  def favicon_pixbuf_for(ch)
    favicon_url = ch.favicon_url
    icon_data = WebResource.favicon_data(favicon_url) if favicon_url
    if icon_data
      load_pixbuf(icon_data, default_icon_pixbuf)
    else
      default_icon_pixbuf
    end
  end
end
