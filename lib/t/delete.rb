require 't/rcfile'
require 'thor'
require 'twitter'

module T
  class Delete < Thor
    DEFAULT_HOST = 'api.twitter.com'
    DEFAULT_PROTOCOL = 'https'

    desc "block USERNAME", "Unblock a user."
    def block(username)
      username = username.strip_at
      client.unblock(username)
      rcfile = RCFile.instance
      rcfile.path = parent_options[:profile] if parent_options[:profile]
      say "@#{rcfile.default_profile[0]} unblocked @#{username}"
      say
      say "Run `#{$0} block #{username}` to block."
    end

    desc "dm", "Delete the last Direct Message sent"
    def dm
      direct_message = client.direct_messages_sent(:count => 1).first
      unless parent_options[:force]
        exit unless yes?("Are you sure you want to permanently delete the direct message to @#{direct_message.recipient.screen_name}: #{direct_message.text}?")
      end
      if direct_message
        direct_message = client.direct_message_destroy(direct_message.id)
        say "@#{direct_message.sender.screen_name} deleted the direct message sent to @#{direct_message.recipient.screen_name}: #{direct_message.text}"
      else
        raise Thor::Error, "No direct message found"
      end
    rescue Twitter::Error::Forbidden => error
      raise Thor::Error, error.message
    end
    map %w(m) => :dm

    desc "favorite USERNAME", "Deletes that user's last Tweet as one of your favorites."
    def favorite(username)
      username = username.strip_at
      status = client.user_timeline(username, :count => 1).first
      if status
        client.unfavorite(status.id)
        rcfile = RCFile.instance
        rcfile.path = parent_options[:profile] if parent_options[:profile]
        say "@#{rcfile.default_profile[0]} unfavorited @#{username}'s latest status: #{status.text}"
        say
        say "Run `#{$0} favorite #{username}` to favorite."
      else
        raise Thor::Error, "No status found"
      end
    end
    map %w(fave) => :favorite

    desc "status", "Delete a Tweet."
    def status
      user = client.user
      unless parent_options[:force]
        exit unless yes?("Are you sure you want to permanently delete the status: #{user.status.text}?")
      end
      if user
        status = client.status_destroy(user.status.id)
        rcfile = RCFile.instance
        rcfile.path = parent_options[:profile] if parent_options[:profile]
        say "@#{rcfile.default_profile[0]} deleted the status: #{status.text}"
      else
        raise Thor::Error, "No status found"
      end
    rescue Twitter::Error::Forbidden => error
      raise Thor::Error, error.message
    end
    map %w(post tweet update) => :status

    no_tasks do

      def base_url
        "#{protocol}://#{host}"
      end

      def client
        rcfile = RCFile.instance
        rcfile.path = parent_options[:profile] if parent_options[:profile]
        Twitter::Client.new(
          :endpoint => base_url,
          :consumer_key => rcfile.default_consumer_key,
          :consumer_secret => rcfile.default_consumer_secret,
          :oauth_token => rcfile.default_token,
          :oauth_token_secret  => rcfile.default_secret
        )
      end

      def host
        parent_options[:host] || DEFAULT_HOST
      end

      def protocol
        parent_options[:no_ssl] ? 'http' : DEFAULT_PROTOCOL
      end

    end
  end
end
