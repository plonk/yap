# -*- coding: utf-8 -*-
class MainWindow < Gtk::Window
  class StatusIcon < Gtk::StatusIcon
    include Gtk
    include GtkHelper

    def initialize(main_window)
      @main_window = main_window

      super()
      set(pixbuf: Gdk::Pixbuf.new(Resource['yap.png']),
          tooltip: 'YAP')

      # クリックされたらメインウィンドウの表示・非表示を切り替える。
      signal_connect('activate') do
        if visible?
          @main_window.hide
        else
          @main_window.show
          @main_window.deiconify
        end
      end

      menu = create_status_icon_menu
      signal_connect('popup-menu') do |_tray, button, time|
        menu.popup(nil, nil, button, time)
      end

      # メインウィンドウが最小化されたら非表示にする。
      @main_window.signal_connect('window-state-event') do |_win, e|
        if e.changed_mask.iconified?
          if e.new_window_state.iconified? && !e.new_window_state.withdrawn?
            @main_window.hide
            next true
          end
        end
        false
      end
    end

    def create_status_icon_menu
      create(Menu) do |menu|
        menu.append create(ImageMenuItem, Stock::INFO,
                           on_activate: proc { @main_window.run_about_dialog })
        menu.append SeparatorMenuItem.new
        menu.append create(ImageMenuItem, Stock::QUIT,
                           on_activate: proc { @main_window.quit })
      end.show_all
    end
  end
end
