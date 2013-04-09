require "acts_as_method_cacheable/version"

module ActsAsMethodCacheable
  extend ActiveSupport::Concern

  included do
    def self.acts_as_method_cacheable(opts = {})
      unless class_variable_defined?(:@@cached_methods)
        cattr_accessor :cached_methods
        self.cached_methods = []

        attr_accessor :instance_cache_methods

        define_method "reload_with_cacheable" do |*params|
          cached_methods.each { |method| reset_cache(method) }
          self.instance_cache_methods && self.instance_cache_methods.each { |method| reset_cache(method) }
          reload_without_cacheable(params)
        end

        alias_method_chain :reload, :cacheable

        include Internal
      end
      [opts[:methods]].compact.flatten.each do |method|
        cache_method(method)
      end
    end
  end

  module Internal
    extend ActiveSupport::Concern

    module ClassMethods
      # cache_method :expensive_method
      #
      # currently don't support method with params, it's complex to serialize params as a key
      # no param method covers most of our use cases
      private
      def cache_method(method)
        raise "#{method} not defined in class #{self.to_s}" unless method_defined?(method)
        raise "method with params is not supported by acts_as_method_cacheable yet!" unless self.new.method(method.to_sym).arity === 0

        return if self.cached_methods.include?(method)

        self.cached_methods.push(method)

        define_method "#{method}_with_cacheable" do
          unless cache_var_defined?(method)
            cache_var_set(method, send("#{method}_without_cacheable".to_sym))
          end
          cache_var_get(method)
        end
        alias_method_chain method, :cacheable
      end

    end

    def reset_cache(method)
      remove_instance_variable(cache_var_name(method)) if cache_var_defined?(method)
    end

    # instance version cache_method
    # cache_method(:expensive_method)
    # cache_method([:expensive_method, :expensive_method2])
    # cache_method([:expensive_method, :expensive_method2])
    # cache_method([:expensive_method, :sub_associations => :expensive_method2])
    def cache_method(args)
      normalized_args = args.is_a?(Array) ? args : [args]

      self_items = normalized_args.select{ |item| item.is_a?(Symbol) }
      self_items.each { |self_item| _cache_method(self_item) }

      children_items = normalized_args.select{ |item| item.is_a?(Hash) }
      children_items.each do |child_item|
        child, child_args = child_item.keys.first, child_item.values.first
        child_instances = send(child)
        child_instances = [child_instances] unless child_instances.respond_to?(:each)
        child_instances.each do |instance|
          instance.cache_method(child_args)
        end
      end
      self
    end

    private

    def cache_var_name(method)
      "@cached_var_for_method_#{method}".to_sym
    end

    def cache_var_set(method, value)
      instance_variable_set(cache_var_name(method), value)
    end

    def cache_var_get(method)
      instance_variable_get(cache_var_name(method))
    end

    def cache_var_defined?(method)
      instance_variable_defined?(cache_var_name(method))
    end

    # method which only accept a symbol as parameter
    def _cache_method(method)
      raise "#{method} not defined in class #{self.class.to_s}" unless self.class.method_defined?(method)
      raise "method with params is not supported by acts_as_method_cacheable yet!" unless method(method.to_sym).arity === 0

      return if cached_methods.include?(method)

      self.instance_cache_methods ||= []

      return if self.instance_cache_methods.include?(method)

      self.instance_cache_methods.push(method)

      self.instance_eval <<-CACHEEND, __FILE__, __LINE__ + 1
        class << self
          def #{method}
            unless cache_var_defined?(:#{method})
              cache_var_set(:#{method}, super)
            end
            cache_var_get(:#{method})
          end
        end
      CACHEEND
    end
  end

end

ActiveRecord::Base.send(:include, ActsAsMethodCacheable)
