require "acts_as_method_cacheable/version"

module ActsAsMethodCacheable
  extend ActiveSupport::Concern

  included do
    def self.acts_as_method_cacheable(opts = {})
      unless class_variable_defined?(:@@class_level_cached_methods)
        include Internal
        cattr_accessor :class_level_cached_methods
        self.class_level_cached_methods = []
        attr_accessor :instance_level_cached_methods
        extend_reload_with_cacheable_support
      end
      [opts[:methods]].compact.flatten.each do |method|
        cache_method(method)
      end
    end
  end

  module Internal
    extend ActiveSupport::Concern

    module ClassMethods
      # currently don't support method with params, it's complex to serialize params as a key
      # no param method covers most of our use cases
      private
      def cache_method(method)
        return unless self.new.before_cache_method(method, true)
        define_method "#{method}_with_cacheable" do
          cache_var_set(method, send("#{method}_without_cacheable".to_sym)) unless cache_var_defined?(method)
          cache_var_get(method)
        end
        alias_method_chain method, :cacheable
      end

      def extend_reload_with_cacheable_support
        define_method "reload_with_cacheable" do |*params|
          class_level_cached_methods.each { |method| reset_cache(method) }
          self.instance_level_cached_methods && self.instance_level_cached_methods.each { |method| reset_cache(method) }
          reload_without_cacheable(params)
        end
        alias_method_chain :reload, :cacheable
      end
    end

    def reset_cache(method)
      remove_instance_variable(cache_var_name(method)) if cache_var_defined?(method)
    end

    def cache_method(params)
      normalize_cachable_params(params) do |self_methods, association_methods|
        self_methods.each { |method| _cache_method(method) }
        association_methods.each{ |pair| cache_association_method(*pair.shift) }
      end
      self
    end

    def before_cache_method(method, class_level=false)
      raise "#{method} not defined in class #{self.class.to_s}" unless self.class.method_defined?(method)
      raise "method with params is not supported by acts_as_method_cacheable yet!" unless method(method.to_sym).arity === 0
      self.instance_level_cached_methods ||= []
      return false if class_level_cached_methods.include?(method)
      return false if self.instance_level_cached_methods.include?(method)
      (class_level ? class_level_cached_methods : self.instance_level_cached_methods).push(method)
      true
    end

    private

    def normalize_cachable_params(params, &block)
      normalized_params = params.is_a?(Array) ? params : [params]
      self_methods = normalized_params.select{ |item| item.is_a?(Symbol) }
      association_methods = normalized_params.select{ |item| item.is_a?(Hash) }
      yield self_methods, association_methods
    end

    def cache_association_method(association, association_params)
      instances = send(association)
      (instances.respond_to?(:each) ? instances : [instances]).each do |instance|
        instance.cache_method(association_params)
      end
    end

    # method which only accept a symbol as parameter
    def _cache_method(method)
      return unless before_cache_method(method)

      instance_eval <<-CACHEEND, __FILE__, __LINE__ + 1
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
  end
end

ActiveRecord::Base.send(:include, ActsAsMethodCacheable)
