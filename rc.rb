# -*- coding: utf-8 -*-
#### Ruby コンパイラー。require_relative を展開する。
####
#### TODO: インタプリタのパスを指定するオプションを作る。

require 'optparse'

def main(file, options)
  @loaded = []

  input = File.new(file, 'r')
  if options[:outputfile]
    out = File.new(options[:outputfile], 'w', 0777)
  else
    out = STDOUT
  end
  out.puts('#!/usr/bin/env ruby')
  out.puts('# encoding: utf-8')
  expand(input, out)
end

def expand(input, out)
  input.each_line do |line|
    line = line.chomp.sub(/\ufeff/, '')

    if line =~ /^\s*\#/
      next
    elsif line =~ /^require_relative\b(.*)$/
      path = eval(Regexp.last_match[1])
      path += '.rb' if path !~ /\.rb\z/

      unless @loaded.include? path
        @loaded << path
        File.open(path, 'r') do |subfile|
          expand(subfile, out)
        end
      end
    else
      out.puts line
    end
  end
end

def init
  options = {}

  OptionParser.new.instance_eval do
    self.banner = "Usage: #{$PROGRAM_NAME} [options] SOURCE_FILE"
    on('-s', 'strip') do
      options[:strip] = true
    end
    on('-o FILENAME', 'outputfile') do |fn|
      options[:outputfile] = fn
    end

    begin
      parse!
      if ARGV.size != 1
        puts help
        exit 1
      end
    rescue OptionParser::MissingArgument
      puts 'missing argument'
      puts help
      exit 1
    end
  end
  main(ARGV[0], options)
end

init
