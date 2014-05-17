# -*- coding: utf-8 -*-
## ベイジアンフィルター
## 「Practical Common Lisp」から。
require_relative 'jwords'

class Classifier
  require 'mathn'

  def initialize(dat_file = nil)
    if dat_file
      begin
        @feature_database = Marshal.load(File.read(dat_file))
      rescue
        @feature_database = {}
      end
    else
      @feature_database = {}
    end
    @total_spams = 0
    @total_hams = 0

    @max_ham_score = 0.4
    @min_spam_score = 0.6

    @max_chars = 10 * 1024
    @corpus = []
  end

  def save(dat_file)
    File.open(dat_file, 'w') do |out|
      out.write Marshal.dump @feature_database
    end
  end

  def classify text
    # Classify the text of a message as :spam, :ham, or :unsure.
    classification score extract_features text
  end

  class WordFeature
    # The word this feature represents.
    attr_accessor :word
    # Number of spams we have seen this feature in.
    attr_accessor :spam_count
    # Number of hams we have seen this feature in.
    attr_accessor :ham_count

    def initialize params
      raise "Must supply :word" unless params[:word]

      @word = params[:word]
      @spam_count = params[:spam_count] || 0
      @ham_count = params[:ham_count] || 0
    end

    def inspect
      "#<#{self.class} #{word} :hams #{ham_count} :spams #{spam_count}>"
    end
  end

  def intern_feature word
    @feature_database[word] ||= WordFeature.new(word: word)
  end

  def extract_words text
    return text.split.flat_map do |span|
      if span =~ /\A[\x21-\x7e]+\z/
        [span]
      else
        span.jwords
      end
    end
  end

  def extract_features text
    extract_words(text).map(&method(:intern_feature))
  end

  def train text, type
    extract_features(text).each do |feature|
      increment_count feature, type
    end
    increment_total_count type
  end

  def increment_count feature, type
    case type
    when :ham then feature.ham_count += 1
    when :spam then feature.spam_count += 1
    else
      raise "unknown type"
    end
  end

  def increment_total_count type
    case type
    when :ham then @total_hams += 1
    when :spam then @total_spams += 1
    else
      raise "unknown type"
    end
  end

  def clear_database
    @feature_database = {}
    @total_spams = 0
    @total_hams = 0
  end

  def spam_probability feature
    # Basic robability that a feature with the given relative
    # frequencies will appear in a spam assuming spams and hams are
    # otherwise equally probable. One of the two frequencies must be
    # non-zero.
    spam_frequency = feature.spam_count / [1,@total_spams].max
    ham_frequency = feature.ham_count / [1,@total_hams].max
    spam_frequency / (spam_frequency + ham_frequency)
  end

  def bayesian_spam_probability feature, assumed_probability = 1/2, weight = 1
    # Bayesian adjustment of a given probability given the number of
    # data points that went into it, an assumed probability, and a
    # weight we give that assumed probability.
    basic_probability = spam_probability feature
    data_points = feature.spam_count + feature.ham_count
    (weight * assumed_probability +
     data_points * basic_probability) / (weight + data_points)
  end

  def score features
    spam_probs = []
    ham_probs = []
    number_of_probs = 0

    features.each do |feature|
      unless untrained? feature
        spam_prob = bayesian_spam_probability(feature).to_f
        spam_probs.unshift spam_prob
        ham_probs.unshift(1 - spam_prob)
        number_of_probs += 1
      end
    end
    h = 1 - fisher(spam_probs, number_of_probs)
    s = 1 - fisher(ham_probs, number_of_probs)
    ((1 - h) + s).fdiv(2)
  end

  def untrained? feature
    feature.spam_count==0 and feature.ham_count==0
  end

  def fisher probs, number_of_probs
    # Fisher computation described by Robinson.
    inverse_chi_square(-2 * probs.map(&Math.method(:log)).inject(0,:+),
                       2 * number_of_probs)
  end

  def inverse_chi_square value, degrees_of_freedom
    # Probability that chi_square >= value with given
    # degrees_of_freedom.  Based on Gary Robinson's Python
    # implementation.
    unless degrees_of_freedom.even?
      raise "not even degrees of freedom"
    end

    # Due to rounding errors in the multiplication and exponentiation
    # the sum computed in the loop may end up a shade above 1.0 which we
    # can't have since it's supposed to represent a probability.
    sum = 0
    m = value / 2
    prob = Math::E ** -m
    i = 0
    while i < degrees_of_freedom / 2
      sum += prob

      i += 1
      prob *= m/i
    end
    [1.0, sum].min
  end

  def classification score
    [ if score <= @max_ham_score then :ham
      elsif score >= @min_spam_score then :spam
      else :unsure end,
      score ]
  end
end
