# -*- coding: utf-8 -*-
require_relative 'relation'
require_relative 'type'
require_relative 'gtk_helper'
require_relative 'object_list_control_box'

# ストリームタイプとプレーヤーの対応付けを編集するためのダイアログ
class TypeAssocDialog < Gtk::Dialog
  include Gtk, GtkHelper, Gtk::Stock

  attr_reader :type_assoc

  FORMAT = [[String, String]]

  def initialize(parent, type_assoc)
    super('タイプ関連付け', parent, MODAL)

    @type_assoc = type_assoc.as(FORMAT).map(&:dup)

    layout
    load
  end

  def load
    @assoc_list.set @type_assoc
  end

  def layout
    set_size_request(480, 320)
    vbox.spacing = 5

    @assoc_list = create_assoc_list

    create(HBox, false, 5) do |hbox|
      hbox.pack_start(@assoc_list, true)

      create(ObjectListControlBoxFull, @assoc_list) do |control_box|
        hbox.pack_start(control_box, false)
      end

      vbox.pack_start(hbox)
    end
    vbox.pack_end(HSeparator.new, false)

    add_button(CANCEL, RESPONSE_CANCEL)
    add_button(OK,     RESPONSE_OK)

    set_alternative_button_order [RESPONSE_OK, RESPONSE_CANCEL]
  end

  def create_assoc_list
    headers = ['タイプ', 'コマンドライン']
    readers = [proc { |obj| obj[0] },
               proc { |obj| obj[1] }]
    writers = [proc { |obj, val| obj[0] = val },
               proc { |obj, val| obj[1] = val }]
    constructor = Array.method(:[])
    create(ObjectList, headers, readers, writers, constructor,
           vscrollbar_policy: POLICY_AUTOMATIC)
  end
end
