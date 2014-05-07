# -*- coding: utf-8 -*-
class TypeAssocDialog < Gtk::Dialog
  include Gtk, GtkHelper, Gtk::Stock

  attr_reader :type_assoc

  def initialize parent
    super("タイプ関連付け", parent, MODAL)

    @type_assoc = ::Settings[:TYPE_ASSOC].dup

    layout
    load
  end

  def load
    @assoc_list.set @type_assoc
  end

  def layout
    self.set_size_request(480,320)
    self.vbox.spacing = 5

    @assoc_list = create_assoc_list

    create(HBox, false, 5) do |hbox|
      hbox.pack_start(@assoc_list, true)

      create(VButtonBox,
             layout_style: ButtonBox::START,
             spacing: 5) do |bbox|
        buttons = [ADD, DELETE, GO_UP, GO_DOWN]
          .map { |type| create(Button, type, sensitive: false) }

        [:pack_start, :pack_start, :pack_end, :pack_end].zip(buttons)
          .each do |pack, button|
          bbox.send(pack, button, false)
        end
        @add_button, @delete_button, @up_button, @down_button = buttons

        hbox.pack_start(bbox, false)
      end
      self.vbox.pack_start(hbox)
    end
    self.vbox.pack_end(HSeparator.new, false)

    add_button(OK,     RESPONSE_OK)
    add_button(CANCEL, RESPONSE_CANCEL)
  end

  def create_assoc_list
    headers = ['タイプ', 'コマンドライン']
    readers = [ proc { |obj| obj[0] },
                proc { |obj| obj[1] } ]
    writers = [ proc { |obj, val| obj[0] = val },
                proc { |obj, val| obj[1] = val } ]
    return ObjectList.new(headers, readers, writers)
  end
end
