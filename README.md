## acts_as_method_cacheable

Instead of writing 
```ruby
class Post < ActiveRecord::Base
  def expensive_method 
    @cached_expensive ||= _expensive_method
  end

  def _expensive_method
    sleep 10
    # blablabla
  end
end
```
now you can write 
```ruby
class Post < ActiveRecord::Base
  def expensive_method
    sleep 10
    # blablabla
  end

  acts_as_method_cacheable :methods => [:expensive_method]
end
```
or cache method for an instance of Post only
```ruby
post = Post.find xxx
post.cache_method(:expensive_method) 
# post has_many comments
post.cache_method(:comments => :comment_expensive_method)
```

*This gem depends on ActiveSupport/ActiveRecord*

## Usage

### cache method in class level, all instances will have the method cached
**NOTE!! MUST put acts_as_method_cacheable in the last of the class file**
```ruby
class Post < ActiveRecord::Base
  def expensive_method
    # balababa
  end
  acts_as_method_cacheable :methods => [:expensive_method]
end
```

### cache methods for an instance only
```ruby
post = Post.find(xxx)
post.cache_method(:expensive_method)
post.cache_method([:expensive_method1, :expensive_method2])
```

### cache methods for an instance and its associations
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

## Installation

Add this line to your application's Gemfile:

    gem 'acts_as_method_cacheable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install acts_as_method_cacheable

## Current Limitation
**ONLY support method with no params**

## Contribute

You're highly welcome to improve this gem.

### Checkout source code to local
say you git clone the source code to /tmp/acts_as_method_cacheable

### Install dev bundle
```bash
$ cd /tmp/acts_as_method_cacheable
$ bundle install
```

### Do some changes
```bash
$ vi lib/acts_as_method_cacheable.rb
```

### Run test
```bash
$ bundle exec rspec spec
```

