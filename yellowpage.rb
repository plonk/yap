#!ruby
# -*- coding: utf-8 -*-
require_relative "channel.rb"
require "net/http"

class YellowPage
  attr_reader :name, :url

  include Enumerable

  private_class_method :new

  IDENTITY_MAP = {}

  def self.get *args
    if IDENTITY_MAP.has_key? args
      IDENTITY_MAP[args]
    else
      IDENTITY_MAP[args] = new *args
    end
  end

  def initialize(name, url, chat, stat)
    @name = name
    @url = url =~ /\/$/ ? url : url + "/"

    @chlist = Array.new

    @chat_url_string = chat
    @stat_url_string = stat
  end

  def favicon_url
    return @url + "favicon.ico"  # Ad hoc
  end

  def loaded?
    !!@timestamp
  end

  def retrieve
    host = nil
    path = nil
    if self.url =~ /^http:\/\/([^\/]+)(\/.*)$/
      host = $1
      path = $2 + "index.txt"
    end
    #    p host, path
    begin
      txt = Net::HTTP.get(host, path)
    rescue
      return false
    end

    @chlist.clear
    txt.force_encoding("utf-8")
    txt.each_line do |l|
      l.chomp!
      ch = Channel.new(l)
      ch.yp = self
      @chlist << ch
    end

    @timestamp = Time.now

    return true
  end
 
  def retrieval_interval
    @retrieval_interval
  end

  def retrieval_interval=(sec)
    @retrieval_interval = sec
  end

  def is_on_air?(chname)
    each_channel do |ch|
      return true if ch.name == chname
    end
    return false
  end

  def get_channel(chname)
    each_channel do |ch|
      return ch if ch.name == chname
    end
    return nil
  end

  def channel_names
    rv = []
    @chlist.each do |ch|
      rv << ch.name
    end
    return rv
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

  def timestamp
    @timestamp
  end

  def stat_url_for(ch)
    if @stat_url_string and ch.id != '00000000000000000000000000000000' and !ch.chname_proper.empty?
      return "#{url}#{@stat_url_string}#{ch.chname_proper.url_encode}"
    else
      return ""
    end
  end

  def chat_url_for(ch)
    if @chat_url_string and ch.id != '00000000000000000000000000000000' and !ch.chname_proper.empty?
      return "#{url}#{@chat_url_string}#{ch.chname_proper.url_encode}"
    else
      return ""
    end
  end
end

class DummyYellowPage < YellowPage
  def initialize
    @name = "local"
    @url = "n/a"

#    super(@name, @url, nil, nil)
  end

  def favicon_url
#    return nil
#    return "http://bayonet.ddo.jp/sp/favicon.ico"
#    return "http://temp.orz.hm/yp/favicon.ico"
    return "http://www.ne.jp/asahi/yoteichi/place/favicon.ico"
  end

  def retrieve
    @chlist.clear
    # デバッグ用エントリ追加
    txt = File.new("index.txt", "r:utf-8").read
    #        txt.force_encoding("utf-8")
    txt.each_line do |l|
      l.chomp!
      ch = Channel.new(l)
      ch.yp = self
      @chlist << ch
    end
  end
end
