#!ruby
# -*- coding: utf-8 -*-
# イエローページビュアーあるいは yap (Yet Another PCYP)
require 'gtk2'
require "resolv"
require "nkf"
require "net/http"
require "csv"
require "dbm"

require_relative 'settings'
require_relative "utility"
require_relative "channel"
require_relative "threadhack"
require_relative "yellowpage"
require_relative "extensions"
require_relative 'resource'

#STDOUT.external_encoding("Shift_JIS")
$log = StringIO.new("", "w")
$real_stdout = $stdout.dup
$RUNNING_ON_RUBYW = false
if File.basename(get_exec_filename).downcase == "rubyw.exe"
  $RUNNING_ON_RUBYW = true
end
if $RUNNING_ON_RUBYW
  $stdout = $log
  $stderr = File.new("errlog.txt", "w")
end
Thread.abort_on_exception = true

$NOTIFICATION_AUTO_CLOSE_TIMEOUT = 15
$ENABLE_VIEWLOG = false

# URL to HTML text
# $PAGE_CACHE = Hash.new 
$PAGE_CACHE = DBM.new(ENV['HOME'] / ".yap/pagecache") # URL to HTML text

$URL2TITLE = Hash.new # URL to page title
$URL2PIXBUF = Hash.new # contact URL to favicon pixbuf

# $FAVICON_CACHE = Hash.new
$FAVICON_CACHE = $PAGE_CACHE

$SIMULTANEOUS_GET = 0

def get_page(url)
  cache = $PAGE_CACHE[url]
  if cache == nil
    puts "MISS: #{url}\n"
    begin
      while $SIMULTANEOUS_GET > 3
        sleep 1
      end
      $SIMULTANEOUS_GET += 1
      res = Net::HTTP.get_response(URI(url))
      if res.is_a? Net::HTTPOK
        $PAGE_CACHE[url] = res.body
        p res.body.size
        return res.body
      end
    rescue
      puts "Error occured, probably connection refusal."
    ensure
      $SIMULTANEOUS_GET -= 1
    end
  else
    puts "HIT: #{url}\n"
    return cache
  end
end

# url で示される .ico 形式のアイコンを取得する
# 失敗したら nil を返す
def get_favicon(url)
  return $FAVICON_CACHE[url] if $FAVICON_CACHE[url]

  res = Net::HTTP.get_response(URI(url))
  if res.is_a? Net::HTTPOK
    p "http ok"
    if res.body[0..3] == "\x00\x00\x01\x00"
      p "its an icon"
      $FAVICON_CACHE[url] = res.body # it's an icon file
    else
      nil
    end
  else
    nil
  end
end

def get_favicon_pixbuf_for(ch, fallback = QUESTION_16)
  pixbuf = fallback

  favicon_url = ch.favicon_url
  if favicon_url
    puts "favicon is specified for #{ch}"
    begin
      Gdk::PixbufLoader.open do |loader|
        loader.write get_favicon(favicon_url)
        loader.close
        pixbuf = loader.pixbuf
      end
    rescue Gdk::PixbufError => e
      if e.code == Gdk::PixbufError::UNKNOWN_TYPE
        puts "Unknown image format"
      else
        raise
      end
    end
  end
  pixbuf
end

def get_page_title(url)
  buf = get_page(url)
  return nil unless buf
  buf = NKF.nkf("-w", buf) # convert to UTF8
  if buf =~ /<title.*>(.*)<\/title>/i
    title = $1
  else
    title = "unknown"
  end
  return title.unescape_html
end

$PIXBUF_CACHE = Hash.new
QUESTION_16 = Gdk::Pixbuf.new Resource["question16.ico"]
QUESTION_64 = Gdk::Pixbuf.new Resource["question64.ico"]
LOADING_16 = Gdk::Pixbuf.new Resource["loading.ico"]

def get_pixbuf_from_url(url)
  if $PIXBUF_CACHE[url]
    return $PIXBUF_CACHE[url] 
  end

  puts "get_pixbuf_from_url(#{url.inspect})"

  begin
    Gdk::PixbufLoader.open do |loader|
      buf = get_favicon(url)
      loader.write(buf)
      loader.close
      $PIXBUF_CACHE[url] = loader.pixbuf
    end
  rescue
    return $PIXBUF_CACHE[url] = QUESTION_64
  end
  return get_pixbuf_from_url(url) # ^^;
end

require_relative "info_dialog"
require_relative "log_dialog"
require_relative "favorite_dialog"
require_relative "settings_dialog"

# ------------------------------------------------------------------

require_relative 'settings'

require_relative "main_window"

window = MainWindow.new
unless defined? Ocra
  window.show_all 
end

begin
  puts "Going into the main loop"
  Gtk.main
rescue Interrupt
  # なんか変だ
  window.finalize
ensure
  if $RUNNING_ON_RUBYW
    File.open("outlog.txt", "w") do |f|
      f.write $log.string
    end
  end
  $PAGE_CACHE.close
end
