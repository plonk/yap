# -*- coding: utf-8 -*-
require 'gtk2'
require_relative "mw_model"
require_relative 'channel_info_label'
require_relative 'channel_name_label'
require_relative 'process_manager'
require_relative 'yellow_page_manager'
require_relative 'information_area'

class MainWindow < Gtk::Window
end

require_relative "mw_components"

class MainWindow
  include Gtk

  def initialize(model)
    super(Window::TOPLEVEL)

    @model = model

    initialize_components
    create_status_icon

    setup_accel_keys
    signal_connect("destroy", &method(:main_window_destroy_callback))

    @model.add_observer(self, :update)
    @model.start_helper_threads
  end

  def create_status_icon
    @status_icon = create(StatusIcon,
                          pixbuf: Gdk::Pixbuf.new(Resource['yap.png']),
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
    @information_area.visible = ::Settings[:CHANNEL_INFO_VISIBLE]
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

  def show_all
    super
    @toolbar.visible = ::Settings[:TOOLBAR_VISIBLE]
    @information_area.visible = ::Settings[:CHANNEL_INFO_VISIBLE]
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

  def favorites_changed
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

  def open_settings_dialog
    d = SettingsDialog.new(self)
    d.show_all
  end

  def open_yellow_page_manager
    YellowPageManager.new(self).show_all
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

  # -- class MainWindow --

  def channel_list_updated
    update_window_title
  end

  # -- class MainWindow

  def reload_toolbutton_callback widget
    STDERR.puts "RELOAD CLICKED"
    @model.reload
  end

  def update_window_title
    # ウィンドウタイトルを更新する
    str = "YAP - #{Time.now.strftime('%H時%M分')}現在 #{@model.total_channel_count} chが配信中"
    self.title = str
  end

  def notification_changed
    @notification.put_up(@model.notification)
  end
end
