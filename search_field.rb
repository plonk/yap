# -*- coding: utf-8 -*-
class SearchField < Gtk::HBox
  include Gtk
  include GtkHelper

  # 10pt bold
  SEARCHING_MARKUP = '<span size="10000" background="yellow" font_weight="bold">検索中</span>'

  def initialize(channel_list_view)
    @channel_list_view = channel_list_view

    super(false, 1)

    @search_label = Label.new('')

    @entry = create(Entry, on_activate: method(:entry_activate_callback))

    @clear_button = create(Button,
                           image: Image.new(clear_icon),
                           tooltip_text: '入力欄をクリアして検索をやめる',
                           on_clicked: method(:clear_button_clicked_callback))

    pack_end(@clear_button, false)
    pack_end(@entry, false)
    pack_end(@search_label, false)
  end

  def clear_icon
    IconFactory.lookup_default('gtk-clear')
      .render_icon(style, Widget::TEXT_DIR_RTL, STATE_NORMAL, IconSize::MENU)
  end

  def clear_button_clicked_callback(_widget)
    @entry.text = ''
    @search_label.markup = ''
    @channel_list_view.search(@entry.text)
  end

  def entry_activate_callback(_widget)
    if @entry.text == ''
      @search_label.markup = ''
    else
      @search_label.markup = SEARCHING_MARKUP
    end
    @channel_list_view.search(@entry.text)
  end
end
