# -*- coding: utf-8 -*-

require_relative 'channel.rb'
require 'shellwords'
require_relative 'child_process'

# アプリケーションローンチャ。変数入りのコマンドラインで初期化して
# spawn で実行する。
class Launcher
  # 定数関数。
  K = lambda { |constant| lambda { |_ch| constant } }
  # N 番目のフィールドを選択する proc を返す。
  F = lambda { |n| lambda { |ch| ch.fields[n] } }
  # PecaRecorder 互換の変数名。
  VAR_DEFINITION = {
    '$\$' => K.call('$'),
    '$0' => F.call(0),
    '$1' => F.call(1),
    '$2' => F.call(2),
    '$3' => F.call(3),
    '$4' => F.call(4),
    '$5' => F.call(5),
    '$6' => F.call(6),
    '$7' => F.call(7),
    '$8' => F.call(8),
    '$9' => F.call(9),
    '$A' => F.call(10),
    '$B' => F.call(11),
    '$C' => F.call(12),
    '$D' => F.call(13),
    '$E' => F.call(14),
    '$F' => F.call(15),
    '$G' => F.call(16),
    '$H' => F.call(17),
    '$I' => F.call(18),
    '$X' => :playlist_url_name.to_proc,	# Host:Port
    '$x' => :playlist_url.to_proc,	# IP:Port
    '$Y' => :stream_url_name.to_proc,	# Host:Port
    '$y' => :stream_url.to_proc,	# IP:Port
    '$Z' => proc { Settings[:USER_PEERCAST] },
    '$z' => proc { Settings[:USER_PEERCAST] },
    '$T' => proc { |ch| ch.type.upcase }
  }

  def self.var_pattern
    regexp = '(' + VAR_DEFINITION.keys.map(&Regexp.method(:escape)).join('|') + ')'
    Regexp.new regexp
  end

  VAR_PATTERN = var_pattern

  def initialize(template)
    @template = template
  end

  def interpolate(channel)
    @template.gsub(VAR_PATTERN) do |var|
      fn = VAR_DEFINITION[var]
      fail "unknown variable #{var}" unless fn
      fn.call(channel).shellescape
    end
  end

  def spawn(channel)
    cmdline = interpolate(channel).encode(Encoding.default_external)
    ChildProcess.new(cmdline)
  end
end
