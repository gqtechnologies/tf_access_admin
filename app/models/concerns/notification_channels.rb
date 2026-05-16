# frozen_string_literal: true

# Allowed +notifications.channel+ and optional +announcement_reads.channel+.
module NotificationChannels
  EMAIL   = "email"
  PUSH    = "push"
  SMS     = "sms"
  IN_APP  = "in_app"
  WEBHOOK = "webhook"
  OTHER   = "other"

  ALL = [ EMAIL, PUSH, SMS, IN_APP, WEBHOOK, OTHER ].freeze
end
