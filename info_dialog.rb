# -*- coding: utf-8 -*-
class InfoDialog < Gtk::Dialog
  include Gtk
  include GtkHelper

  def initialize(parent, ch)
    super "#{ch.name}のチャンネル情報", parent, Dialog::MODAL, [ Stock::OK, Dialog::RESPONSE_NONE ]

    rows = [
             [ get_framed_favicon_image(ch), cell(ch.name) ],
             [ head("リスナー数/リレー数"), cell("#{ch.listener}/#{ch.relay}") ],
             [ head("TIP"), cell("#{ch.tip}#{get_tip_info(ch.tip)}") ],
             [ head("コンタクトURL"), cell(ch.contact_url) ],
             [ head("ID"), cell(ch.id) ],
             [ head("タイプ"), cell(ch.type) ],
             [ head("詳細"), cell(ch.detail) ],
             [ head("ジャンル"), cell(ch.genre) ],
             [ head("コメント"), cell(ch.comment) ],
            ]

    table = create(Table, 2, rows.size, row_spacings: 5, column_spacings: 10)

    rows.each_with_index do |row, y|
      row.each_with_index do |item, x|
        table.attach_defaults(item, x, x+1, y, y+1)
      end
    end
    
    vbox.pack_start(table)
  end

  def get_tip_info tip
    if tip.empty?
      additional_info = ""
    else
      if $REVERSE_LOOKUP_TIP
        addr, port = tip.split(':')
        # XXX should catch Resolv::ResolvError
        hostname = Resolv.getname(addr)
        additional_info = "\n(#{hostname}:#{port})"
      else
        additional_info = ""
      end
    end
    additional_info
  end
  
  def get_framed_favicon_image ch
    f = Frame.new
    unless ch.contact_url.empty?
      i = get_favicon_image_for(ch.contact_url)
      i.pixbuf = i.pixbuf.scale(64, 64, Gdk::Pixbuf::INTERP_NEAREST)
      f.add i
    end
    f
  end

  def get_favicon_image_for(url)
    buf = get_page(url)
    image = Gtk::Image.new
    if buf =~ /<link rel="?(shortcut )?icon"? href="([^"]+)"/i
      puts "favicon is specified"
      favicon_url = $2
      p favicon_url
      uri = URI.join(url, favicon_url)
      Gdk::PixbufLoader.open do |loader|
        loader.write get_favicon(uri.to_s)
        loader.close
        image.pixbuf = loader.pixbuf
      end
    else
      image.pixbuf = Gtk::IconFactory
        .lookup_default("gtk-network")
        .render_icon(self.style,
                     Gtk::Widget::TEXT_DIR_RTL,
                     Gtk::STATE_NORMAL,
                     Gtk::IconSize::LARGE_TOOLBAR)
    end
    return image
  end
end
