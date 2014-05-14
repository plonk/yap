# -*- coding: utf-8 -*-
require 'mechanize'
require 'nokogiri'

class BandwidthCheckerManager
  class Checker
    include Observable

    def self.valid_unchecked?(ch)
      ch.name =~ /アップロード帯域$/ &&
        ch.contact_url =~ /uptest\/$/ &&
        ch.detail =~ /^No data/
    end

    attr_reader :finished_time, :channel

    def initialize(channel)
      @channel = channel
      @monitor = Monitor.new
      self.state = 'initialized'
    end

    def state=(value)
      @monitor.synchronize do
        @state = value
      end
      changed
      notify_observers
    end

    def state
      @monitor.synchronize do
        @state
      end
    end

    def run
      normal_post_url = channel.contact_url + 'uptest_n.php'

      mech = Mechanize.new
      self.state = 'getting form'
      mech.get(normal_post_url) do |page|
        self.state = 'submitting form'
        check_result = page.form_with(name: 'uptest').submit

        doc = Nokogiri::HTML(check_result.body)
        doc.css('span').each do |elem|
          @finished_time = Time.now
          self.state = "finished (#{elem.content})"
        end
      end
    rescue
      self.state = 'finished (error)'
    end
  end

  def initialize(model)
    @model = model
    @model.add_observer(self, :update)
    @checking = []
    @finished_recently = []
    @running = false
  end

  def update(message, *args)
    __send__(message, *args) if respond_to? message
  end

  def reject_finished(checkers)
    checkers.reject { |checker| checker.state =~ /finished/ }
  end

  def update_lists
    finished  = @checking.group_by { |c| (c.state =~ /finished/).to_bool }
    @finished_recently += finished[true] || []
    @checking = finished[false] || []

    old = @finished_recently.group_by { |c| (Time.now - c.finished_time) > 60 }
    (old[true] || []).each do |checker|
      checker.delete_observer(self)
    end
    @finished_recently = (old[false] || [])
  end

  def checker_changed
    @checking.each do |checker|
      checker.state =~ /finished/
      @model.do_update_channel_list(true, false)
    end
  end

  def channel_list_updated
    return unless ::Settings[:ENABLE_AUTO_BANDWIDTH_CHECK]
    return if @running

    @running = true
    unchecked = @model.master_table.select do |ch|
      Checker.valid_unchecked? ch
    end

    update_lists

    to_be_checked = unchecked - (@checking + @finished_recently).map(&:channel)

    to_be_checked.each do |ch|
      checker = Checker.new(ch)
      checker.add_observer(self, :checker_changed)
      @checking << checker
      CheckerWindow.new(checker).show_all
      checker.run
    end
    @running = false
  end

  class CheckerWindow < Gtk::Dialog
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
end
