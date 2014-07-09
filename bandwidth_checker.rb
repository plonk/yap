# -*- coding: utf-8 -*-
# YP4G の uptest で帯域測定をする。
class BandwidthChecker
  include Observable

  def self.valid_unchecked?(ch)
    ch.name =~ /アップロード帯域$/ &&
      ch.contact_url =~ /uptest\/$/ &&
      ch.detail =~ /^No data/
  end

  attr_reader :finished_time, :channel

  def initialize(channel)
    fail ArgumentError, 'not an uptest channel object' unless
      BandwidthChecker.valid_unchecked?(channel)
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

  def extract_kbps(html)
    Nokogiri::HTML(html).css('span').each do |elem|
      return elem.content
    end
    '???'
  end

  def run
    normal_post_url = channel.contact_url + 'uptest_n.php'

    self.state = 'getting form'
    Mechanize.new.get(normal_post_url) do |page|
      self.state = 'submitting form'
      check_result = page.form_with(name: 'uptest').submit
      speed = extract_kbps check_result.body
      self.state = "finished (#{speed})"
    end
  rescue
    self.state = 'finished (error)'
  ensure
    @finished_time = Time.now
  end
end
