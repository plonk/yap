require 'cgi'

class Object
  # instance tap
  def itap &blk
    instance_eval &blk
    self
  end
end

class String
  require 'pathname'

  def / other
    (Pathname.new(self) + other.remove(/\A\/+/)).to_s
  end

  def remove(pattern)
    gsub(pattern, '')
  end

  def escape_html
    CGI::escapeHTML(self)
  end

  def unescape_html
    CGI::unescapeHTML(self)
  end

  def url_encode
    CGI::escape(self)
  end

  def url_decode
    CGI::unescape(self)
  end
end

class Integer
  MIN_POSITIVE_BIGNUM = 1 << 1.size*8-2

  def truncate_to_fixnum
    if not self.is_a? Fixnum
      self % MIN_POSITIVE_BIGNUM
    else
      self
    end
  end
end
