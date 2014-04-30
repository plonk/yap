# -*- coding: utf-8 -*-
require 'gtk2'
require_relative "mw_model"
require_relative 'channel_info_label'
require_relative 'channel_name_label'

class MainWindow < Gtk::Window
end

require_relative "mw_components"

class MainWindow
  include Gtk

  def initialize
    super(Window::TOPLEVEL)

    @model = MainWindowModel.new

    initialize_components

    signal_connect("destroy", &method(:main_window_destroy_callback))

    @model.add_observer(self, :update)
    @model.start_helper_threads
  end

  def favorite_toggled
    @favorite_toggle_button.activate
  end

  def show_all
    super
    # フォーカスバグを回避するために Entry の show を遅らせる。
    @search_field.show
  end

  def update message, *args
    if self.respond_to? message
      # 別スレッドから呼ばれる可能性があるはず。
      Gtk.queue do 
        self.__send__(message, *args)
      end
    else
      STDERR.puts "update: unknown message #{message}(args: #{args.inspect}) received"
    end
  end

  def search_term_changed term
    if term == ""
      @channel_list_view.reset_model
      @search_field.text = ""
      @search_label.text = ""
    else
      @channel_list_view.reset_model
      @search_label.markup = "<span size=\"10000\" background=\"yellow\" font_weight=\"bold\">検索中</span>" # 10pt bold
      @channel_list_view.search(term)
    end
  end

  def search_field_activate_callback widget
    @model.search_term = @search_field.text
  end

  def favorites_changed
    update_favorite_toolbutton_label
  end

  def create_favorite_menu
    Menu.new.tap do |menu|
      MenuItem.new("お気に入りの整理...").tap do |edit|
        edit.signal_connect("activate") do
          dialog = FavoriteDialog.new(self, @model.favorites.to_a)
          dialog.show_all
          dialog.run do |response|
            if response==Dialog::RESPONSE_OK
              @model.favorites.replace(dialog.list)
            end
          end
          dialog.destroy
        end
        menu.append edit
      end

      menu.append MenuItem.new # separator

      # 配信中のお気に入り配信をメニューに追加する。
      @model.favorites.sort.each do |name|
        if YellowPage.is_on_air?(name)
          MenuItem.new(name).tap do |item|
            item.signal_connect("activate") do
              chs = YellowPage.get_channels(name)
              if chs.size > 1
                STDERR.puts "Warning: more than one #{name}\n"
              end
              # これ nil を set_cursor したらどうなるんだろう。
              path = @channel_list_view.get_path_of_channel( chs[0] )
              @channel_list_view.grab_focus
              @channel_list_view.set_cursor(path, nil, false) # no column selection, no editing
            end
            menu.append item
          end
        end
      end
      menu.show_all
    end
  end

  def main_window_destroy_callback widget
    puts "destroying main window"
    @model.finalize
    @model.delete_observer(self)

    Gtk.main_quit
  end

  def until_reload_toolbutton_available sec
    @reload_toolbutton.sensitive = (sec == 0)
    @reload_toolbutton.label = (sec == 0) ? "すぐに更新" : "すぐに更新（あと#{sec}秒）"
  end

  COLORED_STAR_MARKUP = " <span foreground=\"#FEA315\" size=\"xx-large\">★</span> "
  GRAY_STAR_MARKUP = " <span foreground=\"gray\" size=\"xx-large\">★</span> "
  
  def favorite_toggle_button_toggled_callback widget
    if @favorite_toggle_button.active?
      if ch = @channel_list_view.get_selected_channel
        @favorite_toggle_button.child.set_markup(COLORED_STAR_MARKUP)
        @model.favorites << ch.name unless @model.favorites.include? ch.name
      end
    else
      if ch = @channel_list_view.get_selected_channel
        @favorite_toggle_button.child.set_markup(GRAY_STAR_MARKUP)
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

  def update_favorite_toggle_button
    if ch = @model.selected_channel
      @favorite_toggle_button.sensitive = true
      @favorite_toggle_button.active = @model.favorites.include? ch.name
    else
      @favorite_toggle_button.sensitive = false
    end
  end

  def update_play_button
    @play_button.sensitive = (ch = @model.selected_channel and ch.playable?)
  end

  def update_favicon_image
    if ch = @model.selected_channel
      pixbuf = $URL2PIXBUF[ch.contact_url]
      if pixbuf
        @favicon_image.pixbuf = pixbuf
      else
        @favicon_image.pixbuf = LOADING_16
        Thread.start do
          pixbuf = get_favicon_pixbuf_for(ch)
          pixbuf = pixbuf.scale(16, 16, Gdk::Pixbuf::INTERP_NEAREST)
          $URL2PIXBUF[ch.contact_url] = pixbuf
          Gtk.queue do 
            current_channel = @model.selected_channel
            if current_channel == ch
              @favicon_image.pixbuf = pixbuf
            end
          end
        end
      end
    else
      @favicon_iamge.pixbuf = nil
    end
  end
  
  def update_genre_label
    if ch = @model.selected_channel
      @genre_label.text = ch.genre
    else
      @genre_label.text = ''
    end
  end

  def selected_channel_changed
    ch = @model.selected_channel

    @chname_label.show_channel(ch)
    @info_label.show_channel(ch)

    update_link_button
    update_favorite_toggle_button

    update_favicon_image
    update_genre_label
  end

  # -- class MainWindow --

  def channel_list_updated
    update_favorite_toolbutton_label
    @channel_list_view.refresh
    # set favorite menu to toolbutton
    @favorite_toolbutton.menu = create_favorite_menu
    update_window_title
  end

  def update_favorite_toolbutton_label
    numfavs = (YellowPage.all.flat_map(&:channel_names) & @model.favorites.to_a).size
    @favorite_toolbutton.label = "お気に入り (#{numfavs})"
  end

  # -- class MainWindow

  def channel_db_updated
  end

  def reload_toolbutton_callback widget
    STDERR.puts "RELOAD CLICKED"
    @model.reload
  end

  def update_window_title
    # ウィンドウタイトルを更新する
    str = "YAP - #{Time.now.strftime('%H時%M分')}現在 #{YellowPage.count} chが配信中"
    # str += "interval = #{UPDATE_INTERVAL_MINUTE}"
    self.title = str
  end

  def notification_changed
    @notification.put_up(@model.notification)
  end
end
