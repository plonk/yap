# -*- coding: utf-8 -*-
# 帯域測定進捗状況表示用ミニウィンドウ
class BandwidthCheckerWindow < Gtk::Dialog
  include Gtk
  include GtkHelper

  attr_reader :checker

  def initialize(checker)
    super("#{checker.channel.name}", nil)
    do_layout
    @checker = checker
    @checker.add_observer(self, :update)

    signal_connect('response') do
      @checker.delete_observer(self)
      destroy
    end
  end

  def do_layout
    set_width_request 320

    @progress_bar = ProgressBar.new
    vbox.add @progress_bar

    add_button Stock::OK, RESPONSE_OK
  end

  def state_to_fraction(state)
    case state
    when 'initialized'
      0.0
    when 'getting form'
      0.33
    when 'submitting form'
      0.66
    when /finished/
      1.0
    end
  end

  def update
    Gtk.queue do
      @progress_bar.text = @checker.state
      @progress_bar.fraction = state_to_fraction @checker.state
    end
  end
end
