class Abbrev < Plugin

  requires_version '1.0.3'

  @abbreviations = {}
  @history = ''

  class << self
    attr_accessor :abbreviations, :history
  end

  def before
    Kernel.class_eval do
      def abbrev(src, *args, &block)
        target = args.first if args
        if block
          Abbrev.abbreviations[src] = block
        elsif target.is_a? Proc
          Abbrev.abbreviations[src] = target
        elsif target.is_a? String
          Abbrev.abbreviations[src] =  Proc.new do |sequence|
            send(target)
          end  
        end
      end
    end
  end

  def event_received(sequence)
 
    unless /^\w$/i.match(sequence)
      # Find exact match 
      Abbrev.abbreviations.each_pair do |key, value|
        if key.to_s == Abbrev.history
          send("<Delete>"*(key.to_s.size))
          value.call(sequence)
          Abbrev.history = ''
          return false
        end
      end
        Abbrev.history = ''
        return false
    end

    Abbrev.history += sequence

    # Do possible matches exists?
    Abbrev.abbreviations.each_pair do |key, value|
      if key.to_s.starts_with?(Abbrev.history)
        return false
      end
    end

    Abbrev.history = ''
    return false
  end


end

class String
  def starts_with?(prefix)
    prefix = prefix.to_s
    self[0, prefix.length] == prefix
  end
end
