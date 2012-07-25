module Echelon
  # Class allows async task to be proxied
  class AsyncProxy < BasicObject
    # AsyncProxy(User, 10, :pri => 1000, :ttr => 1000)
    # Options include `pri` (priority), `delay` (delay in secs), `ttr` (time to respond)
    def initialize(klazz, id=nil, opts={})
      @klazz, @id, @opts = klazz, id, opts
    end

    # Enqueue when a method is called
    def method_missing(method, *args, &block)
      ::Echelon::Worker.enqueue(@klazz, [@id, method, *args], @opts)
    end
  end

  module Performable
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.send(:include, Echelon::Job)
      base.extend ClassMethods
    end

    module InstanceMethods
      # @model.async(:pri => 1000).do_something("foo")
      def async(opts={})
        Echelon::AsyncProxy.new(self.class, self.id, opts)
      end
    end # InstanceMethods

    module ClassMethods
      # Model.async(:ttr => 300).do_something("foo")
      def async(opts={})
        Echelon::AsyncProxy.new(self, nil, opts)
      end

      # perform(55, :do_something, "foo", "bar")
      def perform(id, method, *args)
        if id # instance
          find(id).send(method, *args)
        else # class method
          send(method, *args)
        end
      end # perform
    end # ClassMethods
  end # Performable
end # Echelon
