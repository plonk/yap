# -*- coding: utf-8 -*-
require 'gtk2'

class ChannelInfoLabel < Gtk::Label
  include Pango, Gtk

  def initialize
    super
    self.ellipsize = Layout::ELLIPSIZE_END
    self.wrap      = true
    self.xalign    = 0
  end

  class << self
    def render_detail_markup(ch)
      if ch.detail.empty?
        '<span foreground="navy" size="large">(詳細なし)</span>'
      else
        '<span font_weight="bold" foreground="navy" size="large">' +
          ch.detail.escape_html +
          '</span>'
      end
    end

    def render_detail_tooltip(ch)
      if ch.detail.empty?
        '(詳細なし)'
      else
        ch.detail
      end
    end
  end

  def show_channel(ch)
    if ch
      label_markup  = ChannelInfoLabel.render_detail_markup(ch)
      label_tooltip = ChannelInfoLabel.render_detail_tooltip(ch)
      unless ch.comment.empty?
        label_markup += "\n「#{ch.comment.escape_html}」"
        label_tooltip += "\n「#{ch.comment}」"
      end
      set_markup label_markup
      set_tooltip_text label_tooltip
    else
      set_text ''
    end
  end
end
