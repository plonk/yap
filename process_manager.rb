# -*- coding: utf-8 -*-
require 'gtk2'
require_relative 'gtk_helper'

# プレーヤーの動作状況を把握する、プロセス管理ダイアログ
class ProcessManager < Gtk::Dialog
  include Gtk, GtkHelper

  def initialize(parent, model)
    @model = model

    super('プロセス管理', parent)

    do_layout

    @object_list.set @model.child_processes

    @model.add_observer(self, :model_update)
    signal_connect('destroy') { @model.delete_observer(self) }

    signal_connect('response') { destroy }
  end

  def do_layout
    set_size_request(480, 320)

    create(HBox, false, 5) do |hbox|
      @object_list = ObjectList.new(['PID', '名前', '状態'],
                                    [proc { |p| p.pid.to_s },
                                     :name,
                                     :status],
                                    [nil,
                                     nil,
                                     nil])
      @object_list.add_observer(self, :object_list_update)

      hbox.pack_start(@object_list, true)

      create(VButtonBox, spacing: 5, layout_style: ButtonBox::START) do |bbox|
        @kill_button = Button.new(Stock::STOP, sensitive: false)
        @kill_button.signal_connect('clicked') do
          cp = @object_list.selected
          cp.kill(15) # SIGTERM
        end
        bbox.add @kill_button

        @clear_button = Button.new(Stock::CLEAR, sensitive: false)
        @clear_button.signal_connect('clicked') do
          @model.clear_finished_child_processes
        end
        bbox.add @clear_button
        hbox.pack_start(bbox, false)
      end

      vbox.pack_start hbox
    end

    add_button(Stock::OK, RESPONSE_OK)
  end

  def object_list_update
    @kill_button.sensitive =
      @object_list.selected && !@object_list.selected.finished?
    @clear_button.sensitive =
      !@object_list.get.select(&:finished?).empty?
  end

  def model_update(what, *_args)
    case what
    when :child_process_changed
      @object_list.set @model.child_processes
    end
    nil
  end
end
