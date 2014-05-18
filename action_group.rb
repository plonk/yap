# -*- coding: utf-8 -*-
class MainWindow < Gtk::Window
  class ActionGroup < Gtk::ActionGroup
    include Gtk

    def initialize(model, main_window)
      @model = model
      @main_window = main_window

      super('default action group')

      add_actions \
      [
       ['FileMenuAction', Stock::FILE, 'ファイル(_F)', '', nil, proc {}],
       ['ReloadAction', Stock::REFRESH, '更新(_R)', '', nil, proc { @model.reload }],
       ['ExitAction', Stock::QUIT, '終了(_X)', '', nil, proc { @main_window.quit }],

       ['ViewMenuAction', nil, '表示(_V)', '', nil, proc {}],

       ['FavoritesMenuAction', nil, 'お気に入り(_A)', '', nil, proc {}],
       ['OrganizeFavoritesAction', nil, '整理(_A)', '', nil, proc { @main_window.run_favorite_dialog }],

       ['ToolMenuAction', nil, 'ツール(_T)', '', nil, proc {}],
       ['SettingsAction', Stock::PREFERENCES, '一般設定(_S)', '', nil, proc { @main_window.open_settings_dialog }],
       ['TypeAssocAction', nil, 'プレーヤー設定(_T)', '', nil, proc {}],
       ['YellowPageAction', nil, 'YP 設定(_Y)', '', nil, proc { @main_window.open_yellow_page_manager }],
       ['ColumnSettingsAction', nil, 'カラム設定(_C)', '', nil, proc { @main_window.open_column_settings_dialog }],
       ['ProcessManagerAction', nil, 'プロセスマネージャ(_P)', '', nil, proc { @main_window.open_process_manager }],

       ['HelpMenuAction', Stock::HELP, 'ヘルプ(_H)', '', nil, proc {}],
       ['AboutAction', Stock::ABOUT, 'このアプリケーションについて(_A)', '', nil, proc { @main_window.run_about_dialog }]
      ]

      # [name, stock_id, label, accelarator, tooltip, proc, is_active]
      add_toggle_actions \
      [
       ['ToolbarVisibleAction', nil, 'ツールバー(_T)', '', nil, proc { @main_window.toggle_toolbar_visibility }, ::Settings[:TOOLBAR_VISIBLE]],
       ['ChannelInfoVisibleAction', nil, 'チャンネル情報(_C)', '', nil, proc { @main_window.toggle_channel_info_visibility }, ::Settings[:CHANNEL_INFO_VISIBLE]]
      ]
    end
  end
end
