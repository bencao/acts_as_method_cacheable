acts_as_method_cacheable
========================

Instead of writing def expensive { @cached_expensive ||= original_expensive }, now you can write instance.cache_method(:expensive) instead. Also support nested cache method for associations.