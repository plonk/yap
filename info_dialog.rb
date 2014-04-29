# -*- coding: utf-8 -*-
class InfoDialog < Gtk::Dialog
  include Gtk
  include GtkHelper

  def initialize(ch)
    table = Table.new(2, 8)
    table.row_spacings = 5
    table.column_spacings = 10
    # [A1, A2]
    # [B1, B2] 
    # [C1, C2]
    # [D1, D2]
    # [E1, E2]
    # [F1, F2]
    
    
    #  a1 = head("チャンネル名")
    f = Frame.new
    unless ch.contact_url.empty?
      i = get_favicon_image_for(ch.contact_url)
      i.pixbuf = i.pixbuf.scale(64, 64, Gdk::Pixbuf::INTERP_NEAREST)
      f.add i
    end
    a1 = f
    a2 = Label.new(ch.name)
    a2.selectable = true
    a2.xalign = 0 
    b1 = head("リスナー数/リレー数")
    b2 = cell("#{ch.listener}/#{ch.relay}")
    c1 = head("TIP")
    if ch.tip.empty?
      additional_info = ""
    else
      if $REVERSE_LOOKUP_TIP
        addr, port = ch.tip.split(':')
        # XXX should catch Resolv::ResolvError
        hostname = Resolv.getname(addr)
        additional_info = "\n(#{hostname}:#{port})"
      else
        additional_info = ""
      end
    end
    c2 = cell("#{ch.tip}#{additional_info}")
    d1 = head("コンタクトURL")
    d2 = cell(ch.contact_url)
    e1 = head("ID")
    e2 = cell(ch.id)
    f1 = head("詳細")
    f2 = cell(ch.detail)
    g1 = head("ジャンル")
    g2 = cell(ch.genre)
    h1 = head("コメント")
    h2 = cell(ch.comment)
    
    table.attach_defaults(a1, 0, 1, 0, 1)
    table.attach_defaults(a2, 1, 2, 0, 1)
    table.attach_defaults(b1, 0, 1, 1, 2)
    table.attach_defaults(b2, 1, 2, 1, 2)
    table.attach_defaults(c1, 0, 1, 2, 3)
    table.attach_defaults(c2, 1, 2, 2, 3)
    table.attach_defaults(d1, 0, 1, 3, 4)
    table.attach_defaults(d2, 1, 2, 3, 4)
    table.attach_defaults(e1, 0, 1, 4, 5)
    table.attach_defaults(e2, 1, 2, 4, 5)
    table.attach_defaults(f1, 0, 1, 5, 6)
    table.attach_defaults(f2, 1, 2, 5, 6)
    table.attach_defaults(g1, 0, 1, 6, 7)
    table.attach_defaults(g2, 1, 2, 6, 7)
    table.attach_defaults(h1, 0, 1, 7, 8)
    table.attach_defaults(h2, 1, 2, 7, 8)
    
    super("#{ch.name}のチャンネル情報", $window, Dialog::MODAL, [ Stock::OK, Dialog::RESPONSE_NONE ])
    
    vbox.pack_start(table)
  end
end

