# frozen_string_literal: true

require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  let(:user) do
    User.create!(
      name: "Test User",
      email_address: "user@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  it "uses the configured password reset URL in HTML and text" do
    email = described_class.reset(user)
    url_options = Rails.application.config.action_mailer.default_url_options
    protocol = url_options.fetch(:protocol, "http")
    host = url_options.fetch(:host)
    reset_url_pattern = %r{#{Regexp.escape("#{protocol}://#{host}")}/passwords/[^"\s]+/edit}

    expect(email.html_part.body.decoded).to match(reset_url_pattern)
    expect(email.text_part.body.decoded).to match(reset_url_pattern)
    expect(email.html_part.body.decoded).not_to include("diario.descansoconsciente.com")
    expect(email.text_part.body.decoded).not_to include("diario.descansoconsciente.com")
  end
end
