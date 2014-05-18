# -*- coding: utf-8 -*-
class MainWindow < Gtk::Window
  class Toolbar < Gtk::Toolbar
    include Gtk
    include GtkHelper
    include DispatchingObserver

    def initialize(model, ui)
      @model = model
      @ui = ui

      super()

      do_layout
      connect_callbacks

      observer_setup(@model)
    end

    def do_layout
      set(toolbar_style: Gtk::Toolbar::Style::BOTH_HORIZ)

      @reload_toolbutton =
        create(ToolButton, Stock::REFRESH,
               label: 'すぐに更新',
               tooltip_text:
               '次の自動更新を待たずにチャンネルリストを更新します' \
               "\n（#{MainWindowModel::MANUAL_UPDATE_INTERVAL}秒間に" \
               "#{MainWindowModel::MANUAL_UPDATE_COUNT}回まで実行できます）",
               important: true)

      if ::Settings[:ENABLE_VIEWLOG]
        @viewlog_toolbutton = create(ToolButton, Stock::JUSTIFY_LEFT,
                                     label: 'ログ',
                                     important: true)
      end
      @settings_toolbutton = create(ToolButton,
                                    Stock::PREFERENCES,
                                    important: true)

      add @reload_toolbutton
      add @viewlog_toolbutton if ::Settings[:ENABLE_VIEWLOG]
      add @settings_toolbutton
    end

    def connect_callbacks
      @reload_toolbutton
        .signal_connect('clicked', &method(:reload_toolbutton_callback))

      @viewlog_toolbutton.signal_connect('clicked') do
        @ui.open_log_dialog
      end if ::Settings[:ENABLE_VIEWLOG]

      @settings_toolbutton.signal_connect('clicked') do
        @ui.open_settings_dialog
      end
    end

    def until_reload_toolbutton_available(sec)
      @reload_toolbutton.sensitive = (sec == 0)
      @reload_toolbutton.label = (sec == 0) ? 'すぐに更新' : "すぐに更新（あと#{sec}秒）"
    end

    def reload_toolbutton_callback(_widget)
      STDERR.puts 'RELOAD CLICKED'
      @model.reload
    end

    def settings_changed
      self.visible = ::Settings[:TOOLBAR_VISIBLE]
    end
  end
end

