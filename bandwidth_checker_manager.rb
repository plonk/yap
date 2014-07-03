# -*- coding: utf-8 -*-
require_relative 'bandwidth_checker_window'
require_relative 'bandwidth_checker'

# 帯域測定が必要かどうかチェックしてスケジュールする。
class BandwidthCheckerManager
  include DispatchingObserver

  def initialize(model, main_window)
    @main_window = main_window
    @model = model
    @model.add_observer(self, :update)
    @checking = []
    @finished_recently = []
    @running = false
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
    unchecked =
      @model.master_table.select { |ch| BandwidthChecker.valid_unchecked?(ch) }

    update_lists

    to_be_checked = unchecked - (@checking + @finished_recently).map(&:channel)

    to_be_checked.each { |ch| check(ch) }
    @running = false
  end

  def check(ch)
    checker = BandwidthChecker.new(ch)
    checker.add_observer(self, :checker_changed)
    @checking << checker
    BandwidthCheckerWindow.new(checker, @main_window).show_all
    checker.run
  end
end
