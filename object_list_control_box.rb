# -*- coding: utf-8 -*-
class ObjectListControlBox < Gtk::VButtonBox
  include Gtk
  include GtkHelper
  include Gtk::Stock
  include Relation

  def initialize(object_list)
    @object_list = object_list

    super()

    do_layout

    wire_up_button_callbacks
    declare_relations

    signal_connect('destroy') do
      dissolve_relations
    end
  end

  def do_layout
    set(layout_style: ButtonBox::START, spacing: 5)

    @add_button, @delete_button, @up_button, @down_button =
      buttons =
      [ADD, DELETE, GO_UP, GO_DOWN]
      .map { |type| create(Button, type) }

    [:pack_start, :pack_start, :pack_end, :pack_end].zip(buttons)
      .each do |pack, button|
      send(pack, button, false)
    end
  end

  def wire_up_button_callbacks
    @add_button   .signal_connect('clicked') { @object_list.run_add_dialog }
    @delete_button.signal_connect('clicked') { @object_list.delete }
    @up_button    .signal_connect('clicked') { @object_list.go_up }
    @down_button  .signal_connect('clicked') { @object_list.go_down }
  end

  def declare_relations
    relation '@delete_button.sensitive mimics @object_list.can_delete?'
    relation '@up_button.sensitive mimics @object_list.can_go_up?'
    relation '@down_button.sensitive mimics @object_list.can_go_down?'
  end
end
