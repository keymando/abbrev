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
        env = {:only => @only||[], :except => @except||[]}
        target = args.first if args
        if block
          Abbrev.abbreviations[src] = env.merge(:cmd => block)
        elsif target.is_a? Proc
          Abbrev.abbreviations[src] = env.merge(:cmd => target)
        elsif target.is_a? String
          Abbrev.abbreviations[src] = env.merge(:cmd => Proc.new { |sequence| send(target) } )
        end
      end
    end
  end

  def event_received(sequence)
 
    unless /^\w$/i.match(sequence)
      # Find exact match 
      Abbrev.abbreviations.each_pair do |key, value|
        if key.to_s == Abbrev.history
          current_app = Accessibility::Gateway.get_active_application.title
          next unless for_application?(current_app, value[:only], value[:except])
          send("<Delete>"*(key.to_s.size))
          value[:cmd].call(sequence)
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

  def for_application?(application, only, except)
    only.each do |regex|
      return false if regex.match(application).nil?
    end

    except.each do |regex|
      return false if regex.match(application)
    end

    return true
  end

end

class String
  def starts_with?(prefix)
    prefix = prefix.to_s
    self[0, prefix.length] == prefix
  end
end
