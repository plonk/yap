# -*- coding: utf-8 -*-
require 'digest/md5'
require_relative 'launcher'
require_relative 'type_association'
require_relative 'extensions'
require_relative 'bayesian'

# チャンネルクラス
class Channel
  attr_reader :genre, :id, :tip, :comment, :contact_url, :type, :detail
  attr_reader :fields
  attr_accessor :yp
  attr_reader :channel_id, :hash

  include Digest

  # 0 | chname, id, ip:port, url, genre,
  # 5 | detail, listener, relay, bitrate, type,
  # 10| nil, nil, nil, nil, chname?,
  # 15| time, click, comment, n
  # A line consists of 19 fields seperated by "<>"
  NAME = 0
  ID = 1 # etc.
  GENRE = 4
  DETAIL = 5
  COMMENT = 17

  FEATURE_DATABASE_FILE = ENV['HOME'] / '.yap/feature_database.dat'
  @@classifier = Classifier.new(FEATURE_DATABASE_FILE)

  def self.save_classifier_state
    @@classifier.save(FEATURE_DATABASE_FILE)
  end

  def initialize(line, source_yp)
    load_line(line)

    @yp = source_yp

    # YPの名前とチャンネル名とストリームIDから同定する
    @channel_id = yp.name + @fields[NAME] + @id
    @hash = MD5.hexdigest(@channel_id).to_i(16).truncate_to_fixnum
  end

  def inspect
    "#<Channel:name=#{name}>"
  end

  def load_line(line)
    @fields = line.split(/<>/, 19).map { |x| x.unescape_html }
    @genre = @fields[4]
    @id = @fields[1]
    @tip = @fields[2]
    @comment = @fields[17]
    @contact_url = @fields[3]
    @type = @fields[9]
    @detail = @fields[5]
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
    "http://#{Settings[:USER_PEERCAST]}/pls/#{@id}?tip=#{@tip}"
  end

  def stream_url
    "http://#{Settings[:USER_PEERCAST]}/stream/#{@id}.wmv?tip=#{@tip}"
  end

  def playlist_url_name
    "http://#{to_host(Settings[:USER_PEERCAST])}/pls/#{@id}?tip=#{@tip}"
  end

  def stream_url_name
    "http://#{to_host(Settings[:USER_PEERCAST])}/stream/#{@id}.wmv?tip=#{@tip}"
  end

  def playable?
    !tip.empty? &&
      @id !=  '000000000000000000000000000000000' &&
      TypeAssociation.instance.launcher(@type).to_bool
  end

  def listener
    @fields[6].to_i
  end

  def relay
    @fields[7].to_i
  end

  def top_page(url)
    # したらばで特定のスレやレスへのリンクである。
    if url =~ %r{^http://jbbs\.shitaraba\.net/bbs/read\.cgi/([a-z]+/\d+)}
      "http://jbbs.shitaraba.net/#{Regexp.last_match[1]}/"
    else
      url
    end
  end

  # 今のところしたらばだけ。
  def favicon_url
    top = top_page(contact_url)

    spec_fav = WebResource.specified_favicon_url(top)
    if spec_fav
      spec_fav
    else
      'http://' + URI.parse(top).host / 'favicon.ico'
    end
  rescue
    nil
  end

  def datum
    @fields.values_at(NAME, GENRE, DETAIL, COMMENT).join(" ").strip
  end

  def score
    @@classifier.score_text(datum)
  end

  def train(category)
    @@classifier.train(datum, category)
  end
end
