#!/usr/bin/ruby
# contact.rb

require "rubygems"
require "logger"
require "cgi"
require "yaml"
require "net/smtp"
require "json"
require "RFC2822"

log = Logger.new("../../contact.log")

log.level = Logger::DEBUG

begin
	cgi = CGI.new

	#validate params here
	#if invalid return error 500
	#if ajax return error message through json
	#else redirect to 500.html

	smtp_settings = YAML.load_file("../../smtp_settings.yml")

	#validate settings here
	#if invalid return error 500
	#if ajax return error message through json
	#else redirect to 500.html

	Net::SMTP.start(smtp_settings["smtp"]["address"], smtp_settings["smtp"]["port"], smtp_settings["smtp"]["helo"], smtp_settings["smtp"]["user"], smtp_settings["smtp"]["secret"], :plain) do |smtp|
		smtp.send_message "From: D & G Credit Service Contact Form <contact@dandgcreditservice.com>\nTo: <seaneshbaugh@gmail.com>\nSubject: New Message from dandgcreditservice.com Contact Form\n\n#{cgi.params["name"].to_s}\n#{cgi.params["email_address"].to_s}\n#{cgi.params["phone_number"].to_s}\n#{cgi.params["message"].to_s}", "contact@dandgcreditservice.com", "seaneshbaugh@gmail.com"
	end

	if cgi.params["ajax"].to_s == "1"
		puts "Content-type: application/json\n\n"
		puts cgi.params.to_json
	else
		puts cgi.header("status" => "REDIRECT", "location" => "/thanks.html")
	end
rescue Exception => error
	log.error error.message
	log.error error.backtrace.join("\n")
end

































