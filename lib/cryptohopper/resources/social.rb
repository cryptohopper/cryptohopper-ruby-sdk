# frozen_string_literal: true

module Cryptohopper
  module Resources
    # `client.social` — profiles, feed, posts, conversations, social graph.
    # Largest resource in the SDK (27 methods).
    class Social
      def initialize(client)
        @client = client
      end

      # ─── Profiles ─────────────────────────────────────────────────────

      def get_profile(alias_or_id)
        @client._request("GET", "/social/getprofile",
                         params: { alias: alias_or_id })
      end

      def edit_profile(data)
        @client._request("POST", "/social/editprofile", body: data)
      end

      def check_alias(alias_str)
        @client._request("GET", "/social/checkalias",
                         params: { alias: alias_str })
      end

      # ─── Feed / discovery ─────────────────────────────────────────────

      def get_feed(**params)
        @client._request("GET", "/social/getfeed",
                         params: params.empty? ? nil : params)
      end

      def get_trends
        @client._request("GET", "/social/gettrends")
      end

      def who_to_follow
        @client._request("GET", "/social/whotofollow")
      end

      def search(query)
        @client._request("GET", "/social/search", params: { q: query })
      end

      # ─── Notifications ────────────────────────────────────────────────

      def get_notifications(**params)
        @client._request("GET", "/social/getnotifications",
                         params: params.empty? ? nil : params)
      end

      # ─── Conversations / messages ─────────────────────────────────────

      def get_conversation_list
        @client._request("GET", "/social/getconversationlist")
      end

      def get_conversation(conversation_id)
        @client._request("GET", "/social/loadconversation",
                         params: { conversation_id: conversation_id })
      end

      def send_message(data)
        @client._request("POST", "/social/sendmessage", body: data)
      end

      def delete_message(message_id)
        @client._request("POST", "/social/deletemessage",
                         body: { message_id: message_id })
      end

      # ─── Posts ────────────────────────────────────────────────────────

      def create_post(data)
        @client._request("POST", "/social/post", body: data)
      end

      def get_post(post_id)
        @client._request("GET", "/social/getpost",
                         params: { post_id: post_id })
      end

      def delete_post(post_id)
        @client._request("POST", "/social/deletepost",
                         body: { post_id: post_id })
      end

      def pin_post(post_id)
        @client._request("POST", "/social/pinpost", body: { post_id: post_id })
      end

      # ─── Comments ─────────────────────────────────────────────────────

      def get_comment(comment_id)
        @client._request("GET", "/social/getcomment",
                         params: { comment_id: comment_id })
      end

      def get_comments(post_id)
        @client._request("GET", "/social/getcomments",
                         params: { post_id: post_id })
      end

      def delete_comment(comment_id)
        @client._request("POST", "/social/deletecomment",
                         body: { comment_id: comment_id })
      end

      # ─── Media ────────────────────────────────────────────────────────

      def get_media(media_id)
        @client._request("GET", "/social/getmedia",
                         params: { media_id: media_id })
      end

      # ─── Social graph ─────────────────────────────────────────────────

      def follow(alias_or_id)
        @client._request("POST", "/social/follow", body: { alias: alias_or_id })
      end

      def get_followers(alias_or_id)
        @client._request("GET", "/social/followers",
                         params: { alias: alias_or_id })
      end

      def get_following(alias_or_id)
        @client._request("GET", "/social/following",
                         params: { alias: alias_or_id })
      end

      def get_following_profiles(alias_or_id)
        @client._request("GET", "/social/followingprofiles",
                         params: { alias: alias_or_id })
      end

      # ─── Engagement ───────────────────────────────────────────────────

      def like(post_id)
        @client._request("POST", "/social/like", body: { post_id: post_id })
      end

      def repost(post_id)
        @client._request("POST", "/social/repost", body: { post_id: post_id })
      end

      # ─── Moderation ───────────────────────────────────────────────────

      def block_user(alias_or_id)
        @client._request("POST", "/social/blockuser",
                         body: { alias: alias_or_id })
      end
    end
  end
end
