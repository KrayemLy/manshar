#!/bin/env ruby
# encoding: utf-8

class Comment < ActiveRecord::Base
  belongs_to :user, :counter_cache => true
  belongs_to :article, :counter_cache => true

  has_many :notifications, -> { where notified_object_type: 'Comment'},
      foreign_key: :notified_object_id

  after_commit :create_notification, on: :create

  # TODO(mkhatib): Link to the specific location of the comment and handle it
  # on the webclient to open the drawer on that comment and highlight it.
  def create_notification
    host = ENV['WEB_CLIENT_HOST']
    url = "http://#{host}/articles/#{article.id}"

    # Notify the article author of the new comment
    subject = "#{user.name} علق على مقالك '#{article.title}'"
    body = "#{user.name} ترك تعليق على مقالك <a href='#{url}' target='blank'>'#{article.title}'</a>. التعليق هو:\n#{body}\n"
    if not user.id.equal? article.user.id
      article.user.notify(subject, body, self)
    end

    # Notify any users who have commented on the same section (i.e. guid).
    past_commenters = Comment.where(
        guid: guid).includes(:user).collect(&:user).uniq
    body = "#{user.name} ترك تعليق على مقالك <a href='#{url}' target='blank'>'#{article.title}'</a> بعد تعليقك. التعليق هو:\n#{body}\n"
    past_commenters.each do |commenter|
      # Don't notify the owner of the article they already have been notified.
      if not commenter.id.equal? article.user.id
        commenter.notify(subject, body, self)
      end
    end

  end

end
