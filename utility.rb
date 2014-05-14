# -*- coding: utf-8 -*-
# このスクリプトを実行している ruby.exe とか rubyw.exe のパスを得る
def exec_filename
  if true
    RbConfig.ruby
  else
    require 'Win32API'

    buf = "\0" * 256
    Win32API.new('kernel32', 'GetModuleFileName', 'LPL', 'L').call(0, buf, 256)
    return  buf.rstrip
  end
end

# 英字（全半）→かな（全半）→漢字の順でソートされるようにする
def regularize(str)
  str.tr('Ａ-ｚ', 'A-z')
    .tr('A-Z', 'a-z')
    .tr('ア-ン', 'あ-ん')
    .tr('ｱ-ﾝ', 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよわをん')
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
  count
end

def get_highlighted_markup(txt, term)
  span_begin = '<span foreground="black" font_weight="bold" background="yellow">'
  span_end = '</span>'
  if term != '' && txt =~ /#{Regexp.escape(term)}/i
    $`.escape_html + span_begin + $&.escape_html + span_end + $'.escape_html
  else
    txt.escape_html
  end
end

require 'resolv'

def to_host(str)
  if str =~ /\A(\d+\.\d+\.\d+\.\d+)(?::(\d+))?\z/
    begin
      if Regexp.last_match[2]
        Resolv.getname(Regexp.last_match[1]) + ':' + Regexp.last_match[2]
      else
        Resolv.getname(Regexp.last_match[1])
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

def to_ip(str)
  if str =~ /\A(.+?)(?::(\d+))?\z/
    begin
      if Regexp.last_match[2]
        Resolv.getaddress(Regexp.last_match[1]) + ':' + Regexp.last_match[2]
      else
        Resolv.getaddress(Regexp.last_match[1])
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
        system('start', arg.encode('cp932'))
      else
        system('xdg-open', arg)
      end
    end
  end
end
