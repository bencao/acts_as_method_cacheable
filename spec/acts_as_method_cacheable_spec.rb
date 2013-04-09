require 'spec_helper.rb'

class Schema < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :title
      t.string :date
    end

    create_table :comments do |t|
      t.string :content
      t.string :author
      t.string :date
      t.references :post
    end
  end
end
schema = Schema.new
schema.down
schema.up

require 'acts_as_method_cacheable'

class Post < ActiveRecord::Base
  has_many :comments

  def comment_authors
    comments.map(&:author).join(" ")
  end

  def comment_contents
    comments.map(&:content).join(" ")
  end

  def comment_dates
    comments.map(&:date).join(" ")
  end

  def comment_signatures
    comments.map(&:signature).join(" ")
  end

  acts_as_method_cacheable :methods => [:comment_authors, :comment_contents]
end

class Comment < ActiveRecord::Base
  belongs_to :post

  def signature
    sub_signature
  end

  def sub_signature
    "cool!"
  end

  acts_as_method_cacheable
end

describe ActsAsMethodCacheable do

  before(:each) do
    @post = Post.create!(:title => 'test', :date => '2013-04-04')
    @post.comments.create!(:content => 'ct1', :author => 'ben', :date => '2013-04-05')
    @post.comments.create!(:content => 'ct2', :author => 'feng', :date => '2013-04-06')
    @comment1, @comment2 = @post.comments.to_a
  end

  context "class" do
    it "should return the same result as without cache" do
      @post.comment_authors.should == @comment1.author + " " + @comment2.author
      @post.comment_authors.should == @comment1.author + " " + @comment2.author
    end

    it "should return the correct result for multiple cache_method" do
      @post.comment_authors.should == @comment1.author + " " + @comment2.author
      @post.comment_authors.should == @comment1.author + " " + @comment2.author
      @post.comment_contents.should == @comment1.content + " " + @comment2.content
      @post.comment_contents.should == @comment1.content + " " + @comment2.content
    end

    it "should cache method for a class" do
      @comment1.expects(:author).once
      @post.comment_authors
      @comment1.expects(:author).never
      @post.comment_authors
    end

    it "should clear cache when reload" do
      @post.comment_authors
      @post.reload
      @comment1 = @post.comments.to_a.first
      @comment1.expects(:author).once
      @post.comment_authors
    end

    it "should raise exception when trying to cache a non-existing method" do
      expect {
        Post.class_eval do
          acts_as_method_cacheable :methods => [:not_exist_method]
        end
      }.to raise_error(Exception, "not_exist_method not defined in class Post")
    end

    it "should raise exception when trying to cache a method with params" do
      expect {
        Post.class_eval do
          def method_with_params(a, b)
            a + b
          end
          acts_as_method_cacheable :methods => :method_with_params
        end
      }.to raise_error(Exception, "method with params is not supported by acts_as_method_cacheable yet!")
    end
  end

  context "instance" do
    def assert_for_no_cache_case
      post = Post.find(@post.id)
      comment1 = post.comments.to_a.first

      post.comment_dates
      comment1.expects(:date).once
      post.comment_dates

      post.comment_signatures
      comment1.expects(:sub_signature).once
      post.comment_signatures
    end

    it "should return the same result as not cache" do
      post1 = Post.find(@post.id)
      post1.cache_method(:comment_dates)
      post2 = Post.find(@post.id)
      post1.comment_dates.should == post2.comment_dates

      post1 = Post.find(@post.id)
      post1.cache_method({:comments => :signature})
      post2 = Post.find(@post.id)
      post1.comment_signatures.should == post2.comment_signatures
    end

    it "should cache specific method for a instance" do
      post = Post.find(@post.id)
      post.cache_method(:comment_dates)

      comment1, comment2 = post.comments.to_a
      comment1.expects(:date).once
      post.comment_dates
      comment1.expects(:date).never
      post.comment_dates

      assert_for_no_cache_case
    end

    it "should cache methods for a instances and its children instances" do
      post = Post.find(@post.id)
      post.cache_method([:comment_dates, {:comments => :signature}])

      comment1 = post.comments.to_a.first

      comment1.expects(:date).once
      post.comment_dates
      comment1.expects(:date).never
      post.comment_dates

      comment1.expects(:sub_signature).once
      post.comment_signatures
      comment1.expects(:sub_signature).never
      post.comment_signatures

      assert_for_no_cache_case
    end

    it "should clear cached after reload" do
      post = Post.find(@post.id)
      post.cache_method([:comment_dates, {:comments => :signature}])

      comment1, comment2 = post.comments.to_a

      comment1.expects(:date).once
      post.comment_dates

      comment1.expects(:sub_signature).once
      post.comment_signatures

      post.reload
      comment1, comment2 = post.comments.to_a

      comment1.expects(:date).once
      post.comment_dates

      comment1.expects(:sub_signature).once
      post.comment_signatures
    end

    it "should raise exception when trying to cache a non-existing method" do
      expect {
        post = Post.find(@post.id)
        post.cache_method :not_exist_method
      }.to raise_error(Exception, "not_exist_method not defined in class Post")
    end

    it "should raise exception when trying to cache a method with params" do
      expect {
        Post.class_eval do
          def method_with_params(a, b)
            a + b
          end
        end
        post = Post.find(@post.id)
        post.cache_method(:method_with_params)
      }.to raise_error(Exception, "method with params is not supported by acts_as_method_cacheable yet!")
    end
  end
end
