# -*- coding: utf-8 -*-
require_relative 'gtk_helper'

# チャンネル情報ダイアログ
class InfoDialog < Gtk::Dialog
  include Gtk, GtkHelper

  def initialize(parent, ch)
    super "#{ch.name}のチャンネル情報", parent, MODAL, [Stock::OK, RESPONSE_NONE]

    rows =
      [
       [get_framed_favicon_image(ch), cell(ch.name)],
       [head('リスナー数/リレー数'), cell("#{ch.listener}/#{ch.relay}")],
       [head('TIP'), cell("#{ch.tip}#{get_tip_info(ch.tip)}")],
       [head('コンタクトURL'), cell(ch.contact_url)],
       [head('ID'), cell(ch.id)],
       [head('タイプ'), cell(ch.type)],
       [head('詳細'), cell(ch.detail)],
       [head('ジャンル'), cell(ch.genre)],
       [head('コメント'), cell(ch.comment)]
      ]

    table = create(Table, 2, rows.size, row_spacings: 5, column_spacings: 10)

    rows.each_with_index do |row, y|
      row.each_with_index do |item, x|
        table.attach_defaults(item, x, x + 1, y, y + 1)
      end
    end

    vbox.pack_start(table)
  end

  def get_tip_info(tip)
    if tip.empty?
      additional_info = ''
    else
      if ::Settings[:REVERSE_LOOKUP_TIP]
        addr, port = tip.split(':')
        begin
          hostname = Resolv.getname(addr)
          additional_info = "\n(#{hostname}:#{port})"
        rescue
          additional_info = "\n(reverse lookup failed)"
        end
      else
        additional_info = ''
      end
    end
    additional_info
  end

  def get_framed_favicon_image(ch)
    create Frame do |frame|
      frame.add Image.new favicon_pixbuf_for(ch).scale(64, 64, Gdk::Pixbuf::INTERP_NEAREST)
    end
  end

  def default_icon_pixbuf
    IconFactory.lookup_default('gtk-network')
      .render_icon(style,
                   Widget::TEXT_DIR_RTL,
                   STATE_NORMAL,
                   IconSize::LARGE_TOOLBAR)
  end

  def favicon_pixbuf_for(ch)
    favicon_url = ch.favicon_url
    icon_data = WebResource.get_favicon(favicon_url) if favicon_url
    if icon_data
      Gdk::PixbufLoader.open do |loader|
        loader.write icon_data
        loader.close
        return loader.pixbuf
      end
    else
      default_icon_pixbuf
    end
  end
end
