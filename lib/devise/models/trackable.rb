# frozen_string_literal: true

module Devise
  module Models
    # Track information about your user sign in. It tracks the following columns:
    #
    # * sign_in_count      - Increased every time a sign in is made (by form, openid, oauth)
    # * current_sign_in_at - A timestamp updated when the user signs in
    # * last_sign_in_at    - Holds the timestamp of the previous sign in
    # * current_sign_in_ip - The remote ip updated when the user sign in
    # * last_sign_in_ip    - Holds the remote ip of the previous sign in
    #
    module Trackable
      def self.required_fields(klass)
        [:current_sign_in_at, :current_sign_in_ip, :last_sign_in_at, :last_sign_in_ip, :sign_in_count]
      end

      def update_tracked_fields(request)
        old_current, new_current = self.current_sign_in_at, Time.now.utc
        self.last_sign_in_at     = old_current || new_current
        self.current_sign_in_at  = new_current

        old_current, new_current = self.current_sign_in_ip, extract_ip_from(request)
        self.last_sign_in_ip     = old_current || new_current
        self.current_sign_in_ip  = new_current

        self.sign_in_count ||= 0
        self.sign_in_count += 1
      end

      def update_tracked_fields!(request)
        # We have to check if the user is already persisted before running
        # `save` here because invalid users can be saved if we don't.
        # See https://github.com/heartcombo/devise/issues/4673 for more details.
        return if new_record?

        return if skip_trackable_and_not_active_for_authentication?(request)

        update_tracked_fields(request)
        save(validate: false)
      end

      protected

      def extract_ip_from(request)
        request.remote_ip
      end

      private

      def skip_trackable_and_not_active_for_authentication?(request)
        request.env['devise.skip_trackable'] || !active_for_authentication?
      end
    end
  end
end
