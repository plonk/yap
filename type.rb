#!/usr/bin/ruby
# encoding: utf-8

module Type
  # Type#is_type?(constraint)
  #
  # Returns true if the receiver satisfies the type and
  # structural constraint expressed by _constraint_,
  # false otherwise.
  #
  # _constraint_ is specified by a class (e.g. String)
  # or by an instance thereof ('abc'), or a combination
  # of these by way of Array's and Hash's.
  #
  # Example:
  #   []           => Array of anything (same as [Object]).
  #   ['']         => Array of (any number of) String's (same as [String]).
  #   [0.0,'']     => size 2 Array of Float and String (same as [Float,String]).
  #   [Integer]*64 => size 64 Array of Integers.
  #   ['John','Smith',64,:male]
  #                => same as [String,String,Fixnum,Symbol].
  #   {1=>'one'}   => Hash with Fixnum keys and String values.
  def is_type?(constraint)
    if constraint.is_a? Array
      ary = constraint
      if ary == []
        self.is_a? Array 
      elsif ary.size == 1
        elementExample = ary[0]
        self.is_a? Array and self.all? {|e| e.is_type? elementExample }
      else
        tuple = ary
        self.is_a? Array and self.size == tuple.size and self.zip(ary).all? {|e,x| e.is_type? x }
      end
    elsif constraint.is_a? Hash
      hash = constraint
      if hash == {}
        self.is_a? Hash
      else
        raise ArgumentError.new('Hash constraint contains >1 key-value pairs') unless hash.size == 1
        key = hash.keys[0]
        value = hash.values[0]
        self.is_a? Hash and self.all? {|k,v| k.is_type? key and v.is_type? value }
      end
    elsif constraint.is_a? Module
      self.is_a? constraint
    else
      self.is_a? constraint.class
    end
  end

  def as(constraint)
    unless self.is_type? constraint
      raise TypeError, "#{self.inspect} is not of the expected type #{constraint}"
    end
    self
  end
end

class Object
  include Type
end
