# -*- coding: utf-8 -*-
class InformationArea < Gtk::VBox
  include Gtk
  include GtkHelper

  URL2PIXBUF = Hash.new # contact URL to favicon pixbuf

  def initialize(model)
    super()
    @model = model
    @model.add_observer(self, :update)

    do_layout

    signal_connect("destroy") do
      @model.delete_observer(self)
    end
  end

  def do_layout
    set(homogeneous: false, spacing: 5, border_width: 10)

    create(HBox, false, 15) do |hbox|
      @play_button = create(Button, 
                            tooltip_text: "チャンネルを再生する",
                            sensitive: false,
                            height_request: 75,
                            width_request: 120)
      @play_button.add Image.new Resource["play.ico"]
      @play_button.signal_connect("clicked") do 
        if ch = @model.selected_channel
          @model.play(ch)
        end
      end
      hbox.pack_start(@play_button, false, false)

      create(VBox) do |little_vbox|
        @chname_label = ChannelNameLabel.new
        little_vbox.pack_start(@chname_label, false)

        @info_label = ChannelInfoLabel.new
        little_vbox.pack_start(@info_label)
        hbox.pack_start little_vbox
      end

      create(Alignment, 1, 0, 0, 0) do |align| # place in the top-right corner
        @favorite_toggle_button = create(ToggleButton, "",
                                         tooltip_text: "お気に入り",
                                         sensitive: false,
                                         draw_indicator: false,
                                         on_toggled: method(:on_favorite_toggle_button_toggled))
        @favorite_toggle_button.child.set_markup(" <span foreground=\"gray\" size=\"xx-large\">★</span> ")

        align.add @favorite_toggle_button
        hbox.pack_start(align, false, false)
      end

      pack_start(hbox, false)
    end


    create(VBox) do |detail_vbox|
      create(HBox, false, 5) do |genre_hbox|
        @genre_label = create(Label, '',
                              wrap: true,
                              xalign: 0,
                              width_request: 120 + 15,
                              ellipsize: Pango::Layout::ELLIPSIZE_END)

        @favicon_image = Image.new
        @link_button = create(LinkButton, "", "",
                              xalign: 0)
        @link_button.child.set(ellipsize: Pango::Layout::ELLIPSIZE_END)

        genre_hbox.pack_start(@genre_label, false);
        genre_hbox.pack_start(@favicon_image, false)
        genre_hbox.pack_start(@link_button, true)

        detail_vbox.pack_start(genre_hbox, false)
      end
      pack_start(detail_vbox, false)
    end
  end

  def update message, *args
    if self.respond_to? message
      # 別スレッドから呼ばれる可能性があるはず。
      Gtk.queue do 
        self.__send__(message, *args)
      end
    end
  end

  def favorites_changed
    update_favorite_toggle_button
  end

  COLORED_STAR_MARKUP = " <span foreground=\"#FEA315\" size=\"xx-large\">★</span> "
  GRAY_STAR_MARKUP = " <span foreground=\"gray\" size=\"xx-large\">★</span> "
  
  def update_favorite_toggle_button
    if ch = @model.selected_channel
      @favorite_toggle_button.sensitive = true
      if @model.favorites.include? ch.name
        @favorite_toggle_button.active = true
        @favorite_toggle_button.child.set_markup(COLORED_STAR_MARKUP)
      else
        @favorite_toggle_button.active = false
        @favorite_toggle_button.child.set_markup(GRAY_STAR_MARKUP)
      end
    else
      @favorite_toggle_button.active = false
      @favorite_toggle_button.sensitive = false
      @favorite_toggle_button.child.set_markup(GRAY_STAR_MARKUP)
    end
  end

  def update_play_button
    @play_button.sensitive = (ch = @model.selected_channel and ch.playable?)
  end

  def update_favicon_image
    if ch = @model.selected_channel
      pixbuf = URL2PIXBUF[ch.contact_url]
      if pixbuf
        @favicon_image.pixbuf = pixbuf
      else
        @favicon_image.pixbuf = LOADING_16
        Thread.start do
          pixbuf = get_favicon_pixbuf_for(ch)
          pixbuf = pixbuf.scale(16, 16, Gdk::Pixbuf::INTERP_NEAREST)
          URL2PIXBUF[ch.contact_url] = pixbuf
          Gtk.queue do 
            current_channel = @model.selected_channel
            if current_channel == ch
              @favicon_image.pixbuf = pixbuf

            end
          end
        end
      end
    else
      @favicon_image.pixbuf = nil
    end
  end

  def get_favicon_pixbuf_for(ch, fallback = QUESTION_16)
    if ch.favicon_url
      puts "favicon is specified for #{ch}"
      WebResource.get_pixbuf(ch.favicon_url, fallback)
    else
      fallback
    end
  end

  def update_genre_label
    if ch = @model.selected_channel
      @genre_label.set(text: ch.genre,
                       tooltip_text: ch.genre)
    else
      @genre_label.set(text: '',
                       tooltip_text: '')
    end
  end

  def selected_channel_changed
    ch = @model.selected_channel

    @chname_label.show_channel(ch)
    @info_label.show_channel(ch)

    update_play_button
    update_link_button
    update_favorite_toggle_button

    update_favicon_image
    update_genre_label
  end

  def on_favorite_toggle_button_toggled widget
    if @favorite_toggle_button.active?
      if ch = @model.selected_channel
        @model.favorites << ch.name unless @model.favorites.include? ch.name
      end
    else
      if ch = @model.selected_channel
        @model.favorites.delete ch.name
      end
    end
  end

  def update_link_button
    if ch = @model.selected_channel
      if ch.contact_url.empty?
        @link_button.child.text = "今からpeercastでゲーム実況配信"
        @link_button.uri = "http://yy25.60.kg/peercastjikkyou/"
      else
        @link_button.child.text = ch.contact_url
        @link_button.uri = ch.contact_url
      end
    else
      @link_button.child.text = ''
      @link_button.uri = ''
    end
  end

end
