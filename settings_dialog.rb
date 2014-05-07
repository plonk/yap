# -*- coding: utf-8 -*-
require 'gtk2'
require_relative 'settings'
require_relative 'utility'
require_relative 'object_list'
require_relative 'type_assoc_dialog'

class SettingsDialog < Gtk::Dialog
  include Gtk, GtkHelper

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

    self.border_width = 5
    self.resizable = false

    a1 = head("peercast のホスト名とポート\n（通常 localhost:7144）")
    @host_entry = a2 = Entry.new
    a2.no_show_all = true
    a2.text = ::Settings[:USER_PEERCAST] || ""
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
    @file_assoc_button = b2 = create(Button, '設定', on_clicked: method(:cb_file_assoc_button_clicked))

    table.attach_defaults(a1, 0, 1, 0, 1)
    table.attach_defaults(a2, 1, 2, 0, 1)
    table.attach_defaults(a3, 2, 3, 0, 1)

    table.attach_defaults(b1, 0, 1, 1, 2)
    table.attach_defaults(b2, 1, 3, 1, 2)

    add_button(Stock::OK, Dialog::RESPONSE_OK)
    add_button(Stock::CANCEL, Dialog::RESPONSE_CANCEL)

    signal_connect("response") do |d, res|
      case res
      when Dialog::RESPONSE_OK
        if not check_peercast
          # do not save settings
        else
          if (s = @peercast_entry.text).empty?
            ::Settings[:USER_PEERCAST] = nil
          else
            ::Settings[:USER_PEERCAST] = s
          end
          ::Settings.save
        end
      else # CANCEL
        ::Settings.load
      end
      destroy
    end

    vbox.pack_start(table)
    vbox.pack_end(HSeparator.new)
  end

  def cb_file_assoc_button_clicked button
    dialog = TypeAssocDialog.new(self).show_all
    dialog.run do |response|
      case response
      when RESPONSE_OK
        ::Settings[:TYPE_ASSOC] = dialog.type_assoc
      end
      dialog.destroy
    end
  end

  def show_all
    super
    @host_entry.show
  end
end
