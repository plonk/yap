# -*- coding: utf-8 -*-
require 'uri'

class WebResourceClass
  include Singleton

  PAGE_CACHE = DBM.new(ENV['HOME'] / '.yap/pagecache') # URL to HTML text
  PIXBUF_CACHE = {}

  def initialize
  end

  def get_page(url)
    cache = PAGE_CACHE[url]
    if cache.nil?
      puts "MISS: #{url}\n"
      begin
        res = Net::HTTP.get_response(URI(url))
        if res.is_a? Net::HTTPOK
          PAGE_CACHE[url] = res.body
          p res.body.size
          return res.body
        end
      rescue
        puts 'Error occured, probably connection refusal.'
      end
    else
      puts "HIT: #{url}\n"
      return cache
    end
  end

  # url で示される .ico 形式のアイコンを取得する
  # 失敗したら nil を返す
  def get_favicon(url)
    data = get_page(url)

    if data && data[0..3] == "\x00\x00\x01\x00"
      data
    else
      nil
    end
  end

  def get_pixbuf(url, fallback = QUESTION_64)
    if PIXBUF_CACHE[url]
      return PIXBUF_CACHE[url]
    else
      begin
        Gdk::PixbufLoader.open do |loader|
          buf = WebResource.get_favicon(url)
          loader.write(buf)
          loader.close
          return PIXBUF_CACHE[url] = loader.pixbuf
        end
      rescue
        return PIXBUF_CACHE[url] = fallback
      end
    end
  end

  # HTML ページから link 要素で指定されたアイコンの URL を得る。
  # 見つからなければ nil
  def specified_favicon_url(url)
    puts 'get_specified_favicon_url'
    buf = get_page(url)
    if buf =~ /<link rel="?(shortcut )?icon"? href="([^"]+)"/i
      (URI.parse(url) + Regexp.last_match[2]).to_s
    else
      nil
    end
  end
end

WebResource = WebResourceClass.instance
