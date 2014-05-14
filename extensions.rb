# -*- coding: utf-8 -*-
require 'cgi'

class Object
  # instance tap
  def itap(&blk)
    instance_eval(&blk)
    self
  end

  def to_bool
    self ? true : false
  end
end

class String
  require 'pathname'

  def /(other)
    (Pathname.new(self) + other.remove(/\A\/+/)).to_s
  end

  def remove(pattern)
    gsub(pattern, '')
  end

  def escape_html
    CGI.escapeHTML(self)
  end

  def unescape_html
    CGI.unescapeHTML(self)
  end

  def url_encode
    CGI.escape(self)
  end

  def url_decode
    CGI.unescape(self)
  end
end

class Integer
  MIN_POSITIVE_BIGNUM = 1 << 1.size * 8 - 2

  def truncate_to_fixnum
    if !self.is_a? Fixnum
      self % MIN_POSITIVE_BIGNUM
    else
      self
    end
  end
end

class Array
  # 関数(あるいは to_proc できるオブジェクト)の配列から、適用されるとそ
  # れぞれのオブジェクトを引数に適用する関数を返す。
  #
  # [ :succ, ->(x){x*10} ].juxt.call(1)
  # => [2, 10]
  def juxt
    fs = map(&:to_proc)
    lambda do |*args|
      fs.map { |f| f.call(*args) }
    end
  end
end
