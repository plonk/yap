# -*- coding: utf-8 -*-
require 'gtk2'

class ChannelNameLabel < Gtk::Label
  include Gtk
  include GtkHelper

  def initialize
    super
    set(ellipsize: Pango::Layout::ELLIPSIZE_END,
        wrap: false,
        xalign: 0)
  end

  class << self
    def duration_on_air(minutes)
      if minutes == 0
        # no point in showing
        ''
      elsif minutes < 60
        "#{minutes}分経過"
      else
        format('%d時間%d分経過', minutes / 60, minutes % 60)
      end
    end

    def render_channel_name(ch)
      '<span font_weight="bold" size="12000">' +
        ch.name.escape_html +
        '</span>' +
        '　<span font_weight="bold" foreground="red" size="medium">' +
        ChannelNameLabel.duration_on_air(ch.time) +
        '</span>'
    end
  end

  def show_channel(ch)
    if ch
      set_markup(ChannelNameLabel.render_channel_name(ch))
    else
      set_text ''
    end
  end
end
