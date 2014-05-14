#!ruby
# -*- coding: utf-8 -*-
require_relative 'channel.rb'
require 'net/http'
require 'uri'

class YellowPage
  attr_reader :name, :url
  attr_reader :timestamp
  attr_accessor :retrieval_interval

  include Enumerable

  private_class_method :new

  IDENTITY_MAP = {}

  def self.get(*args)
    if IDENTITY_MAP.key? args
      IDENTITY_MAP[args]
    else
      IDENTITY_MAP[args] = new *args
    end
  end

  def initialize(name, url, chat, stat)
    @name = name
    @url = url =~ /\/$/ ? url : url + '/'

    @chlist = []

    @chat_url_string = chat
    @stat_url_string = stat
  end

  def favicon_url
    @url + 'favicon.ico'  # Ad hoc
  end

  def loaded?
    !!@timestamp
  end

  def retrieve
    uri = URI(url)
    begin
      txt = Net::HTTP.get(uri.host, uri.path + 'index.txt')
    rescue
      return false
    end

    @chlist.clear
    txt.force_encoding('utf-8')
    txt.each_line do |line|
      line.chomp!
      ch = Channel.new(line, self)
      @chlist << ch
    end

    @timestamp = Time.now

    true
  end

  def get_channel(chname)
    each_channel do |ch|
      return ch if ch.name == chname
    end
    nil
  end

  def channel_names
    rv = []
    @chlist.each do |ch|
      rv << ch.name
    end
    rv
  end

  def each(&block)
    each_channel &block
  end

  def each_channel
    @chlist.each do  |ch|
      yield(ch)
    end
    self
  end

  # count the number of channels on this YP
  def count
    @chlist.size
  end

  def stat_url_for(ch)
    if @stat_url_string and ch.id != '00000000000000000000000000000000' and !ch.chname_proper.empty?
      return "#{url}#{@stat_url_string}#{ch.chname_proper.url_encode}"
    else
      return ''
    end
  end

  def chat_url_for(ch)
    if @chat_url_string and ch.id != '00000000000000000000000000000000' and !ch.chname_proper.empty?
      return "#{url}#{@chat_url_string}#{ch.chname_proper.url_encode}"
    else
      return ''
    end
  end
end
