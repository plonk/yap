# -*- coding: utf-8 -*-
require 'gtk2'
require_relative 'settings'
require_relative 'utility'

class SettingsDialog < Gtk::Dialog
  include Gtk
  include GtkHelper

  def show_message(message, title, kind = MessageDialog::ERROR)
    md = MessageDialog.new(self,
                           Dialog::DESTROY_WITH_PARENT,
                           MessageDialog::ERROR,
                           MessageDialog::BUTTONS_OK,
                           message)
    md.title = title
    md.run do |response|
      md.destroy
    end
  end

  def check_peercast
    str = @peercast_entry.text
    return true if str.empty?

    if not str =~ /^.+:.+$/
      show_message("ホスト名:ポート番号の形式で指定してください", "peercast 入力形式エラー")
      return false
    end

    host, port = str.split(/:/, 2)
    unless port =~ /^\d+$/ and port.to_i.between?(1, 65535)
      show_message("ポート番号が有効な数字ではありません", "ポート番号エラー")
      return false
    end

    # 開いてみる？ タイムアウトが長い。
    open_failed = false
    begin
      s = TCPSocket.new(host, port.to_i)
      s.close
    rescue
      open_failed = true
    end
    if open_failed
      show_message("#{host}:#{port}にアクセスできません。\n設定しますが、再生できないと思われます。",
                         "#{host}:#{port}が開けません",
                         MessageDialog::WARNING)
    end

    return true
  end

  def initialize(parent)
    # ピアキャストのポート番号、動画プレーヤーのパス？
    super("設定", parent, Dialog::MODAL)
    table = Table.new(3, 2)
    table.row_spacings = 5
    table.column_spacings = 10

    self.resizable = false

    a1 = head("peercast のホスト名とポート\n（通常 localhost:7144）")
    a2 = Entry.new
    a2.text = ::Settings[:USER_PEERCAST] if ::Settings[:USER_PEERCAST]
    @peercast_entry = a2 
    a3 = Button.new("チェック")
    a3.signal_connect ("clicked") do 
      if a2.text != "" and check_peercast
        show_message("#{@peercast_entry.text} に問題は見つかりませんでした。",
                           "問題なし",
                           MessageDialog::INFO)
      end
    end
    b1 = head("プレーヤー")
    b2 = FileChooserButton.new("動画プレーヤーを選択してください", FileChooser::ACTION_OPEN) #Entry.new
    b2.current_folder = "\\"
    if RUBY_PLATFORM =~ /cygwin/ or
        RUBY_PLATFORM =~ /mingw/
      filter = FileFilter.new
      filter.add_pattern("*.exe")
      filter.name = "実行ファイル (*.exe)"
      b2.add_filter filter
    end
    b2.filename = ::Settings[:USER_PLAYER] if ::Settings[:USER_PLAYER]
    b3 = Button.new("クリア")
    b3.signal_connect("clicked") do
      b2.filename = ""
      b2.current_folder = "\\"
    end
    table.attach_defaults(a1, 0, 1, 0, 1)
    table.attach_defaults(a2, 1, 2, 0, 1)
    table.attach_defaults(a3, 2, 3, 0, 1)

    table.attach_defaults(b1, 0, 1, 1, 2)
    table.attach_defaults(b2, 1, 2, 1, 2)
    table.attach_defaults(b3, 2, 3, 1, 2)

    add_button(Stock::OK, Dialog::RESPONSE_OK)
    add_button(Stock::CANCEL, Dialog::RESPONSE_CANCEL)

    self.border_width = 5

    signal_connect("response") do |d, res|
      case res
      when Dialog::RESPONSE_OK
        player = b2.filename # nil if unset
        if player and not File.exist? player
          md = MessageDialog.new(parent,
                                 Dialog::DESTROY_WITH_PARENT,
                                 MessageDialog::ERROR,
                                 MessageDialog::BUTTONS_OK,
                                 "'%s'は存在しません" % player)
          md.title = "エラー"
          md.run do |response|
            md.destroy
          end
        elsif not check_peercast
          # do not save settings
        else
          ::Settings[:USER_PLAYER] = player
          s = @peercast_entry.text
          if s == nil or s.empty?
            ::Settings[:USER_PEERCAST] = nil
          else
            ::Settings[:USER_PEERCAST] = s
          end
          ::Settings.save
          destroy
        end
      else
        # 破棄して閉じる
        destroy # なんか warning 出てる？
      end
    end

    vbox.pack_start(table)
  end
end
