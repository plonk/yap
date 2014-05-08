# -*- coding: utf-8 -*-
require 'gtk2'
require_relative "mw_model"
require_relative 'channel_info_label'
require_relative 'channel_name_label'
require_relative 'process_manager'

class MainWindow < Gtk::Window
end

require_relative "mw_components"

class MainWindow
  include Gtk

  def initialize
    super(Window::TOPLEVEL)

    @model = MainWindowModel.new

    initialize_components
    create_status_icon

    setup_accel_keys
    signal_connect("destroy", &method(:main_window_destroy_callback))

    @model.add_observer(self, :update)
    @model.start_helper_threads
  end

  def create_status_icon
    @status_icon = create(StatusIcon,
                          pixbuf: Gdk::Pixbuf.new(Resource.path('yap.png')),
                          tooltip: "YAP")

    # クリックされたらメインウィンドウの表示・非表示を切り替える。
    @status_icon.signal_connect('activate') do
      if visible?
        hide
      else
        show
        deiconify
      end
    end

    menu = create_status_icon_menu
    @status_icon.signal_connect('popup-menu') do |tray, button, time|
      menu.popup(nil, nil, button, time)
    end

    # メインウィンドウが最小化されたら非表示にする。
    self.signal_connect('window-state-event') do |win, e|
      # p [:changed_mask, e.changed_mask]
      # p [:new_state, e.new_window_state]
      if e.changed_mask.iconified?
        if e.new_window_state.iconified? and !e.new_window_state.withdrawn?
          self.hide
          next true
        end
      end
      false
    end
  end

  def settings_changed
    @toolbar.visible = ::Settings[:TOOLBAR_VISIBLE]
    @mainarea_vbox.visible = ::Settings[:CHANNEL_INFO_VISIBLE]
  end

  def toggle_toolbar_visibility
    ::Settings[:TOOLBAR_VISIBLE] = !::Settings[:TOOLBAR_VISIBLE]
  end

  def toggle_channel_info_visibility
    ::Settings[:CHANNEL_INFO_VISIBLE] = !::Settings[:CHANNEL_INFO_VISIBLE]
  end

  def create_status_icon_menu
    create(Menu) do |menu|
      create(ImageMenuItem, Stock::INFO) do |info|
        info.signal_connect('activate') do
          run_about_dialog
        end
        menu.append(info)
      end

      menu.append(Gtk::SeparatorMenuItem.new)

      create(ImageMenuItem, Stock::QUIT) do |quit|
        quit.signal_connect('activate') do self.quit end
        menu.append(quit)
      end

      menu.show_all
    end
  end

  def on_about_toolbutton_clicked toolbutton
    run_about_dialog
  end

  def run_about_dialog
    comments = <<EOS
GTK+ #{Gtk::VERSION.join('.')}
Ruby/GTK: #{Gtk::BINDING_VERSION.join('.')} (built for #{Gtk::BUILD_VERSION.join('.')})
Ruby: #{RUBY_VERSION} [#{RUBY_PLATFORM}]
EOS
    comments = comments.chomp
    dialog = create(AboutDialog,
                    modal: true,
                    program_name: "YAP",
                    version: "0.0.3",
                    comments: comments,
                    authors: ['予定地'],
                    website: 'https://github.com/plonk/yap')
    dialog.run do |response|
      dialog.destroy
    end
  end

  def favorite_toggled
    @favorite_toggle_button.activate
  end

  def show_all
    super
    # フォーカスバグを回避するために Entry の show を遅らせる。
    @search_field.show
    @toolbar.visible = ::Settings[:TOOLBAR_VISIBLE]
    @mainarea_vbox.visible = ::Settings[:CHANNEL_INFO_VISIBLE]
  end

  def show_channel_info ch
    dialog = InfoDialog.new(self, ch)
    dialog.show_all
    dialog.run do |response|
      dialog.destroy
    end
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
    update_favorite_toolbutton
  end

  def run_favorite_dialog
    dialog = FavoriteDialog.new(self, @model.favorites.to_a)
    dialog.show_all
    dialog.run do |response|
      if response==Dialog::RESPONSE_OK
        @model.favorites.replace(dialog.list)
      end
    end
    dialog.destroy
  end

  def create_favorite_menu
    Menu.new.tap do |menu|
      MenuItem.new("お気に入りの整理...").tap do |edit|
        edit.signal_connect("activate") do
          run_favorite_dialog
        end
        menu.append edit
      end

      menu.append MenuItem.new # separator

      # 配信中のお気に入り配信をメニューに追加する。
      @model.favorites.sort.each do |name|
        if @model.is_on_air?(name)
          MenuItem.new(name).tap do |item|
            item.signal_connect("activate") do
              chs = @model.get_channels(name)
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


  def open_settings_dialog
    d = SettingsDialog.new(self)
    d.show_all
  end

  def setup_accel_keys
    accel_group = Gtk::AccelGroup.new
    accel_group.connect(Gdk::Keyval::GDK_A,
                        Gdk::Window::CONTROL_MASK,
                        Gtk::ACCEL_VISIBLE) do
      open_process_manager
    end

    add_accel_group(accel_group)
  end

  def open_process_manager
    ProcessManager.new(self, @model).show_all
  end

  def finalize
    @model.finalize
    @model.delete_observer(self)
  end

  def main_window_destroy_callback widget
    puts "destroying main window"
    quit
  end

  def quit
    finalize
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

    update_play_button
    update_link_button
    update_favorite_toggle_button

    update_favicon_image
    update_genre_label
  end

  # -- class MainWindow --

  def channel_list_updated
    update_favorite_toolbutton
    @channel_list_view.refresh
    update_window_title
  end

  def update_favorite_toolbutton
    numfavs = (@model.yellow_pages.flat_map(&:channel_names) & @model.favorites.to_a).size
    @favorite_toolbutton.label = "お気に入り (#{numfavs})"
    @favorite_toolbutton.menu = create_favorite_menu
  end

  # -- class MainWindow

  def reload_toolbutton_callback widget
    STDERR.puts "RELOAD CLICKED"
    @model.reload
  end

  def update_window_title
    # ウィンドウタイトルを更新する
    str = "YAP - #{Time.now.strftime('%H時%M分')}現在 #{@model.total_channel_count} chが配信中"
    # str += "interval = #{UPDATE_INTERVAL_MINUTE}"
    self.title = str
  end

  def notification_changed
    @notification.put_up(@model.notification)
  end
end
