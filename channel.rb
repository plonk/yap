# -*- coding: utf-8 -*-
require 'digest/md5'
require_relative 'launcher'

class Channel
  attr_reader :genre, :id, :tip, :comment, :contact_url, :type
  attr_reader :fields
  attr_accessor :yp

  include Digest

  # 0 | chname, id, ip:port, url, genre,
  # 5 | detail, listener, relay, bitrate, type,
  # 10| nil, nil, nil, nil, chname?,
  # 15| time, click, comment, n
  # A line consists of 19 fields seperated by "<>"
  NAME = 0
  ID = 1 # etc.

  def initialize(line)
    row = line.split(/<>/, 19).map{|x| x.unescape_html }
    @fields = row
    @genre = row[4]
    @id = row[1]
    @tip = row[2]
    @comment = row[17]
    @contact_url = row[3]
    @type = row[9]
    @detail = row[5]

    # チャンネル名とストリームIDから同定する
    @hash = MD5.hexdigest(row[NAME] + '<>' + @id).to_i(16)
  end

  def ==(other)
    hash == other.hash
  end

  # Array#- の為に eql? と hash をオーバーライドする。
  # 両方ともオーバーライドする必要があるらしい。
  def eql?(other)
    hash == other.hash
  end

  attr_reader :hash

  def chname_proper
    @fields[14].url_decode.force_encoding("utf-8")
  end

  def chat_url
    yp.chat_url_for(self)
  end

  def stat_url
    yp.stat_url_for(self)
  end

  def name
    @fields[0]
  end

  def bitrate
    @fields[8].to_i
  end

  def time
    if @fields[15] =~ /^(\d+):(\d+)$/
      $1.to_i * 60 + $2.to_i
    else
      print "#{self.name}: failed to parse time #{@fields[15].inspect}\n"
      -1
#      raise "time format error"
    end
  end

  def detail
#    if @detail =~ / - <([A-z ]+)>$/ or @detail =~ /^([A-z ]+)$/
#      $`
#    else
      @detail # ポート状態がないことがあるのか？
#    end
  end

  # Over, Free, Open, 2M Over etc.
  def port_stat
    if @detail =~ / - <([A-z ]+)>$/ or @detail =~ /^([A-z ]+)>$/
      "<" + $1 + ">"
    else
      nil
    end
  end

  def playlist_url
    "http://#{Settings[:USER_PEERCAST] or '127.0.0.1:7144'}/pls/#{@id}?tip=#{@tip}"
  end

  def stream_url
    "http://#{Settings[:USER_PEERCAST] or '127.0.0.1:7144'}/stream/#{@id}.wmv?tip=#{@tip}"
  end

  def playlist_url_name
    "http://#{to_host(Settings[:USER_PEERCAST] || '127.0.0.1:7144')}/pls/#{@id}?tip=#{@tip}"
  end

  def stream_url_name
    "http://#{to_host(Settings[:USER_PEERCAST] || '127.0.0.1:7144')}/stream/#{@id}.wmv?tip=#{@tip}"
  end

  def playable?
    (not tip.empty?) and
      @id !=  "000000000000000000000000000000000" and
      @type == "WMV"
  end

  def listener
    @fields[6].to_i
  end
  
  def relay
    @fields[7].to_i
  end

  # 今のところしたらばだけ
  def favicon_url
    if contact_url =~ /^http:\/\/jbbs\.shitaraba\.net\/bbs\/read\.cgi\/([a-z]+\/\d+)/ # l50などと続く可能性あり
      # the link is to a specific thread or a post
      t = get_specified_favicon_url("http://jbbs.shitaraba.net/#{$1}/")
      return t if t
    elsif contact_url =~ /^http:\/\/jbbs\.shitaraba\.net\/[a-z]+\/\d+\// # スレやレスでなく掲示板のトップなら
      t = get_specified_favicon_url(contact_url)
      return t if t
    end

    if contact_url =~ /^http:\/\/jbbs\.shitaraba\.net\//
      "http://jbbs.shitaraba.net/favicon.ico"
    else
      begin
        "http://" + URI.parse(contact_url).host / "favicon.ico"
      rescue
        nil
      end
    end
  end
end
