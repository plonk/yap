# -*- coding: utf-8 -*-
# このスクリプトを実行している ruby.exe とか rubyw.exe のパスを得る
def get_exec_filename
  if true
    RbConfig.ruby
  else
    require "Win32API"

    buf = "\0" * 256
    Win32API.new("kernel32", "GetModuleFileName", "LPL", "L").call(0, buf, 256)
    return  buf.rstrip
  end
end

# 英字（全半）→かな（全半）→漢字の順でソートされるようにする
def regularize(str)
  return str.tr("Ａ-ｚ", "A-z").tr("A-Z", "a-z").tr("ア-ン", "あ-ん").tr("ｱ-ﾝ", "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよわをん")
end

# Measure width in hankaku, asssuming all non latin characters are 
# zenkaku.
def measure_width(str)
  count = 0
  str.split(//).each do |c|
    if c =~ /[ -~]/
      count += 1
    else
      count += 2
    end
  end
  return count
end

def get_highlighted_markup(txt, term)
  markup = nil
  if term != "" and txt =~ /#{Regexp.escape(term)}/i
    markup = $`.escape_html + "<span foreground=\"black\" font_weight=\"bold\" background=\"yellow\">" + $&.escape_html + "</span>" + $'.escape_html
  else
    markup = txt.escape_html
  end
  return markup
end

require 'resolv'

def to_host str
  if str =~ /\A(\d+\.\d+\.\d+\.\d+)(?::(\d+))?\z/
    begin
      if $2
        Resolv.getname($1) + ":" + $2
      else
        Resolv.getname($1)
      end
    rescue Resolv::ResolvError => e
      STDERR.puts e.message
      str
    end
  else
    STDERR.puts "Warning: to_host: #{str} is not an IP address-port number pair."
    str
  end
end

def to_ip str
  if str =~ /\A(.+?)(?::(\d+))?\z/
    begin
      if $2
        Resolv.getaddress($1) + ":" + $2
      else
        Resolv.getaddress($1)
      end
    rescue Resolv::ResolvError => e
      STDERR.puts e.message
      str
    end
  else
    STDERR.puts "Warning: to_ip: #{str} cannot be converted to an IP address."
    str
  end
end

module Environment
  class << self
    # Open anything
    def open(arg)
      if RUBY_PLATFORM =~ /mingw/
        system("start", arg.encode("cp932"))
      else
        system("xdg-open", arg)
      end
    end
  end
end
