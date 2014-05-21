module Relation
  IDENTITY_FUNCTION = lambda { |x| x }

  def relation(code)
    lhs, pred, rhs = code.split(/\s+/)
    fail unless pred == 'mimics'
    listener, writer = parse_specifier_writer(lhs)
    subject, reader = parse_specifier_reader(rhs)
    subject.add_observer self, :relation_update
    do_add_relation listener, writer, subject, reader, IDENTITY_FUNCTION
  end

  def compute(code, &block)
    lhs, pred, rhs = code.split(/\s+/)
    fail unless pred == 'from' && block
    listener, writer = parse_specifier_writer(lhs)
    subject, reader = parse_specifier_reader(rhs)
    subject.add_observer self, :relation_update
    do_add_relation listener, writer, subject, reader, block
  end

  def relation_update
    @_relations.each do |dest, writer, subject, reader, transform|
      dest.__send__(writer, transform.call(subject.__send__(reader)))
    end
  end

  private

  def do_add_relation(listener, writer, subject, reader, transform)
    @_relations ||= []
    # first sync
    listener.__send__(writer, transform.call(subject.__send__(reader)))
    @_relations << [listener, writer, subject, reader, transform]
  end

  def parse_specifier_writer(str)
    obj, sym = parse_specifier str
    [obj, (sym.to_s.sub(/[?=]$/, '') + '=').to_sym]
  end

  def parse_specifier_reader(str)
    parse_specifier str
  end

  def parse_specifier(str)
    thing, property = str.split('.', 2)
    [eval(thing), property.to_sym]
  end

  def dissolve_relations
    @_relations.each do |_dest, _writer, subject, _reader, _transform|
      subject.delete_observer(self)
    end
    @_relations.clear
  end
end
