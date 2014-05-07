# -*- coding: utf-8 -*-

require_relative "channel.rb"
require 'shellwords'
require_relative 'child_process'

# アプリケーションローンチャ。変数入りのコマンドラインで初期化して
# spawn で実行する。
class Launcher
  # 定数関数。
  K = lambda { |constant| proc { |ch| constant } }
  # N 番目のフィールドを選択する proc を返す。
  F = lambda { |n| proc { |ch| ch.fields[n] } }
  # PecaRecorder 互換の変数名。
  VAR_DEFINITION = {
    '$\$' => K.('$'),
    '$0' => F.(0),
    '$1' => F.(1),
    '$2' => F.(2),
    '$3' => F.(3),
    '$4' => F.(4),
    '$5' => F.(5),
    '$6' => F.(6),
    '$7' => F.(7),
    '$8' => F.(8),
    '$9' => F.(9),
    '$A' => F.(10),
    '$B' => F.(11),
    '$C' => F.(12),
    '$D' => F.(13),
    '$E' => F.(14),
    '$F' => F.(15),
    '$G' => F.(16),
    '$H' => F.(17),
    '$I' => F.(18),
    '$X' => :playlist_url_name.to_proc,	# Host:Port
    '$x' => :playlist_url.to_proc,	# IP:Port
    '$Y' => :stream_url_name.to_proc,	# Host:Port
    '$y' => :stream_url.to_proc,	# IP:Port
    '$Z' => proc { Settings[:USER_PEERCAST] or '127.0.0.1:7144' },
    '$z' => proc { Settings[:USER_PEERCAST] or '127.0.0.1:7144' },
    '$T' => proc { |ch| ch.type.upcase },
  }
  VAR_PATTERN = Regexp.new( "(" + VAR_DEFINITION.keys.map(& Regexp.method(:escape) ).join("|") + ")")
  
  def initialize(template)
    @template = template
  end

  def interpolate(channel)
    @template.gsub(VAR_PATTERN) { |var|
      fn = VAR_DEFINITION[var]
      raise "unknown variable #{var}" if not fn
      fn.(channel).shellescape
    }
  end

  def spawn(channel)
    cmdline = interpolate(channel).encode(Encoding.default_external)
    return ChildProcess.new(cmdline)
  end
end
