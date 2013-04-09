## acts_as_method_cacheable

Instead of writing def expensive { @cached_expensive ||= original_expensive }, now you can write instance.cache_method(:expensive) instead. Also support nested cache method for associations.
*This gem depend on ActiveSupport/ActiveRecord*

## Currernt Limitation
*ONLY support method with no params*

## Installation

Add this line to your application's Gemfile:

    gem 'acts_as_method_cacheable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install acts_as_method_cacheable

## Usage

### cache method in class level, all instances will have the method cached
*NOTE!! MUST put acts_as_method_cacheable in the last of the class file*
```ruby
class Post < ActiveRecord::Base
  def expensive_method
    # balababa
  end
  acts_as_method_cacheable :methods => :expensive_method
end
```

### cache methods for a instance only
```ruby
post = Post.find(xxx)
post.cache_method(:expensive_method)
post.cache_method([:expensive_method1, :expensive_method2])
```

### cache methods for a instance and its associations
```ruby
post = Post.find(xxx)
post.cache_method([:expensive_method3, :comments => :comment_expensive_method])
```

### reload - will clear cache of all cached methods(both class/instance level)
```ruby
post = Post.find(xxx)
post.cache_method(:expensive_method)
post.expensive_method  # expensive
post.expensive_method  # cheap!
post.reload
post.expensive_method  # expensive
```

### reset cached method for a instance
```ruby
post = Post.find(xxx)
post.cache_method(:expensive_method)
post.expensive_method  # expensive
post.expensive_method  # cheap!
post.reset_cache(:expensive_method)
post.expensive_method  # expensive
```
