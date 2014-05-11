require 'socket'
require 'timeout'

class PeercastHealth
  attr_reader :error_reason

  include Timeout

  def initialize host, port, timeout_seconds = 3
    @host = host
    @port = port
    @timeout_seconds = timeout_seconds
  end

  def to_s
    "#{@host}:#{@port}"
  end

  def check
    socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
    sockaddr = Socket.sockaddr_in(@port, @host)

    response = nil
    timeout @timeout_seconds do 
      socket.connect sockaddr
      socket.write "\x70\x63\x70\x0a\x04\x00\x00\x00\x01\x00\x00\x00\x68\x65\x6c\x6f\x00\x00\x00\x80"
      response = socket.recv(4)
      socket.close
    end
    response == "oleh"
  rescue Errno::ECONNREFUSED
    @error_reason = "connection refused"
    false
  rescue Timeout::Error
    @error_reason = "connection timed out"
    false
  rescue Errno::EINVAL
    @error_reason = "invalid argument"
    false
  end
end

