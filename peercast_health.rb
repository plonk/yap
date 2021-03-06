# -*- coding: utf-8 -*-
require 'socket'
require 'timeout'

# peercast ローカルサーバー起動確認クラス
class PeercastHealth
  attr_reader :error_reason

  include Timeout

  HELO = "\x70\x63\x70\x0a\x04\0\0\0\x01\0\0\0\x68\x65\x6c\x6f\0\0\0\x80"

  def initialize(host, port, timeout_seconds = 3)
    @host = host
    @port = port
    @timeout_seconds = timeout_seconds
  end

  def to_s
    "\#<PeercastHealth: P#{@host}:#{@port}>"
  end

  def check
    response = nil
    timeout @timeout_seconds do
      Addrinfo.tcp(@host, @port).connect do |socket|
        socket.write HELO
        response = socket.recv(4)
      end
    end
    response == 'oleh'
  rescue Errno::ECONNREFUSED
    @error_reason = 'connection refused'
    false
  rescue Timeout::Error
    @error_reason = 'connection timed out'
    false
  rescue Errno::EINVAL
    @error_reason = 'invalid argument'
    false
  end
end
