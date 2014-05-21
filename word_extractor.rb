# -*- coding: utf-8 -*-

class RegexpJapaneseAwareWordExtractor
  def simple_split(str)
    case str
    when /([\x21-\x7e]+|\p{Hiragana}+|(\p{Katakana}|ー)+|\p{Han}+)/
      [$&] + simple_split($')
    else
      []
    end
  end

  OKURI_REGEXP =  /^( [いきしちみり たすてぬ うくすつぬふむゆる] | った | って | んだ | ます)$/x

  def append_okurigana(words)
    # 赤い 青き 青し 待ち 死に? ひX 掴み 寄り
    # 似た 足す? 似て
    (words + ['']).each_cons(2).flat_map do |left, right|
      if left =~ OKURI_REGEXP
        []
      elsif right =~ OKURI_REGEXP
        [left + right]
      else
        [left]
      end
    end
  end

  def separate_particle(words)
    words.flat_map do |word|
      case word
      when /^(や | の | は | が | を | に | で | と | だ | する | です | ます | ません | こと)(.+)$/x
        [$1] + separate_particle([$2])
      when /^(.+?)(や | の | は | が | を | に | で | と | だ | する | です | ます | ません | こと)$/x
        [$1] + separate_particle([$2])
      else
        [word]
      end
    end
  end

  FUNCTION_WORDS = %w(や の は が を に で と です ます だ ません して する こと)
  MISC_STOP_WORDS = %w(- <Free> <Open> <Over>)

  def delete_stop_words(words)
    words - FUNCTION_WORDS - MISC_STOP_WORDS
  end

  def call(str)
    delete_stop_words word_baggify separate_particle append_okurigana simple_split str
  end

  def word_baggify(words)
    words.sort.uniq
  end
end

# word_extractor = RegexpJapaneseAwareWordExtractor.new
# p word_extractor.call "青い花"
# p word_extractor.call 'このファイルがあるフォルダーをファイルマネージャーで表示します。'
# p word_extractor.call 'アスカ裏白盾縛り練習'
