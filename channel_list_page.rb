# -*- coding: utf-8 -*-
require_relative 'channel_list_view'

class ChannelListPage < Gtk::VBox
  include Gtk
  include GtkHelper

  def initialize(model, func = proc { true })
    super()

    @model = model
    @func = func
    set(homogeneous: false)

    do_layout
  end

  def do_layout
    create(HBox, false) do |hbox|
      @search_label = Label.new("")
      @search_field = Entry.new
      @search_field.signal_connect("activate", &method(:search_field_activate_callback))
      clear_icon = IconFactory
        .lookup_default("gtk-clear")
        .render_icon(self.style, Widget::TEXT_DIR_RTL, STATE_NORMAL, IconSize::MENU)
      @clear_button = create(Button, image: Image.new(clear_icon),
                             tooltip_text: "入力欄をクリアして検索をやめる",
                             on_clicked: method(:clear_button_clicked_callback))

      hbox.pack_end(@clear_button, false)
      hbox.pack_end(@search_field, false)
      hbox.pack_end(@search_label, false)

      pack_start(hbox, false)
    end

    @channel_list_view = ChannelListView.new(@model, @func)
    create(ScrolledWindow, 
           shadow_type: SHADOW_ETCHED_IN,
           hscrollbar_policy: POLICY_AUTOMATIC,
           vscrollbar_policy: POLICY_ALWAYS) do |sw|
      sw.add @channel_list_view
      pack_start(sw, true)
    end
  end

  def clear_button_clicked_callback widget
    @channel_list_view.reset_model
    @search_field.text = ""
    @search_label.markup = ""
    @channel_list_view.search(@search_field.text)
  end

  def search_field_activate_callback widget
    if @search_field.text == ""
      @channel_list_view.reset_model
      @search_label.markup = ""
      @channel_list_view.search(@search_field.text)
    else
      @channel_list_view.reset_model
      @search_label.markup = "<span size=\"10000\" background=\"yellow\" font_weight=\"bold\">検索中</span>" # 10pt bold
      @channel_list_view.search(@search_field.text)
    end
  end
end
