# -*- coding: utf-8 -*-
class FileAssocDialog < Gtk::Dialog
  include Gtk
  include GtkHelper

  attr_reader :type_assoc

  def initialize parent
    super("タイプ関連付け", parent, Dialog::MODAL)
    @type_assoc = ::Settings[:TYPE_ASSOC]

    self.set_size_request(480,320)

    @object_list = ObjectList.new(['タイプ', 'コマンドライン'], 
                                  [
                                   proc { |obj| obj[0] },
                                   proc { |obj| obj[1] }
                                  ],
                                  [
                                   proc { |obj, val| obj[0] = val }, 
                                   proc { |obj, val| obj[1] = val },
                                  ])
    @object_list.set @type_assoc

    create(HBox, false, 5) do |hbox|
      hbox.pack_start(@object_list, true)

      create(VButtonBox, spacing: 5, layout_style: ButtonBox::START) do |bbox|
        @add_button = create(Button, Stock::ADD, sensitive: false)
        bbox.pack_start(@add_button, false)
        @delete_button = create(Button, Stock::DELETE, sensitive: false)
        bbox.pack_start(@delete_button, false)
        hbox.pack_start(bbox, false)

        @up_button = create(Button, Stock::GO_UP, sensitive: false)
        bbox.pack_end(@up_button, false)
        @down_button = create(Button, Stock::GO_DOWN, sensitive: false)
        bbox.pack_end(@down_button, false)
      end
      vbox.pack_start(hbox)
    end
    vbox.spacing = 5
    vbox.pack_end(HSeparator.new, false)

    add_button(Stock::OK, RESPONSE_OK)
    add_button(Stock::CANCEL, RESPONSE_CANCEL)
  end
end
