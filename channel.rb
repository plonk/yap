# -*- coding: utf-8 -*-
require 'digest/md5'
require_relative 'launcher'
require_relative 'type_association'

class Channel
  attr_reader :genre, :id, :tip, :comment, :contact_url, :type, :detail
  attr_reader :fields
  attr_accessor :yp
  attr_reader :hash
  attr_reader :channel_id

  include Digest

  # 0 | chname, id, ip:port, url, genre,
  # 5 | detail, listener, relay, bitrate, type,
  # 10| nil, nil, nil, nil, chname?,
  # 15| time, click, comment, n
  # A line consists of 19 fields seperated by "<>"
  NAME = 0
  ID = 1 # etc.

  def initialize(line, yp)
    row = line.split(/<>/, 19).map { |x| x.unescape_html }
    @fields = row
    @genre = row[4]
    @id = row[1]
    @tip = row[2]
    @comment = row[17]
    @contact_url = row[3]
    @type = row[9]
    @detail = row[5]
    @yp = yp

    @channel_id = yp.name + row[NAME] + @id

    # チャンネル名とストリームIDから同定する
    @hash = MD5.hexdigest(@channel_id).to_i(16).truncate_to_fixnum
  end

  def ==(other)
    channel_id == other.channel_id
  end

  # Array#- の為に eql? と hash をオーバーライドする。
  # 両方ともオーバーライドする必要があるらしい。
  def eql?(other)
    self == other
  end

  def chname_proper
    @fields[14].url_decode.force_encoding('utf-8')
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
      Regexp.last_match[1].to_i * 60 + Regexp.last_match[2].to_i
    else
      print "#{name}: failed to parse time #{@fields[15].inspect}\n"
      -1
#      raise "time format error"
    end
  end

  # Over, Free, Open, 2M Over etc.
  def port_stat
    if @detail =~ / - <([A-z ]+)>$/ || @detail =~ /^([A-z ]+)>$/
      '<' + Regexp.last_match[1] + '>'
    else
      nil
    end
  end

  def playlist_url
    "http://#{Settings[:USER_PEERCAST] || '127.0.0.1:7144'}/pls/#{@id}?tip=#{@tip}"
  end

  def stream_url
    "http://#{Settings[:USER_PEERCAST] || '127.0.0.1:7144'}/stream/#{@id}.wmv?tip=#{@tip}"
  end

  def playlist_url_name
    "http://#{to_host(Settings[:USER_PEERCAST] || '127.0.0.1:7144')}/pls/#{@id}?tip=#{@tip}"
  end

  def stream_url_name
    "http://#{to_host(Settings[:USER_PEERCAST] || '127.0.0.1:7144')}/stream/#{@id}.wmv?tip=#{@tip}"
  end

  def playable?
    !tip.empty? &&
      @id !=  '000000000000000000000000000000000' &&
      TypeAssociation.instance.launcher(@type)
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
      t = get_specified_favicon_url("http://jbbs.shitaraba.net/#{Regexp.last_match[1]}/")
      return t if t
    elsif contact_url =~ /^http:\/\/jbbs\.shitaraba\.net\/[a-z]+\/\d+\// # スレやレスでなく掲示板のトップなら
      t = get_specified_favicon_url(contact_url)
      return t if t
    end

    if contact_url =~ /^http:\/\/jbbs\.shitaraba\.net\//
      'http://jbbs.shitaraba.net/favicon.ico'
    else
      begin
        'http://' + URI.parse(contact_url).host / 'favicon.ico'
      rescue
        nil
      end
    end
  end

  # 見つからなければ nil
  def get_specified_favicon_url(url)
    puts 'get_specified_favicon_url'
    p [:get_specified_favicon_url, url]
    buf = WebResource.get_page(url)
    if buf =~ /<link rel="?(shortcut )?icon"? href="([^"]+)"/i
      puts 'found!'
      (URI.parse(url) + Regexp.last_match[2]).to_s
    else
      puts 'not found'
      nil
    end
  end
end
