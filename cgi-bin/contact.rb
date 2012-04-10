#!/usr/bin/ruby
# contact.rb

require "rubygems"
require "logger"
require "cgi"
require "erb"
require "active_support/inflector"
require "yaml"
require "net/smtp"
require "json"
require "RFC2822"

log = Logger.new("../../contact.log")

log.level = Logger::DEBUG

begin
	cgi = CGI.new

	ajax = cgi.params["ajax"].to_s == "1"
	test = cgi.params["test"].to_s == "1"

	log.info "New contact form request from #{cgi.remote_addr}.\nAjax: #{ajax}\nTest: #{test}"

	if cgi.request_method != "POST"
		error_type = "Error 405 - Method Not Allowed"
		error_message = "Hey! You're not supposed to be here! You've most likely reached this page because you tried to use a GET instead of a POST. If you have no idea what that means don't worry. Just go <a href=\"/\">home</a> and everything will be alright."

		if ajax
			puts cgi.header("status" => "METHOD_NOT_ALLOWED", "type" => "application/json")
			puts({ :response_title => error_type, :response_message => error_message }.to_json)
		else
			puts cgi.header("status" => "METHOD_NOT_ALLOWED", "type" => "text/html")
			puts File.open("error.html.erb") { |file| ERB.new(file.read) }.result(binding)
		end

		log.error "Error 405 - Method Not Allowed\n#{cgi.remote_addr} attempted to send a #{cgi.request_method} request when a POST was expected."

		exit
	end

	params = { "name" => "", "email_address" => "", "phone_number" => "", "message" => "" }

	params.each do |key, value|
		params[key] = cgi.params[key].to_s

		log.debug "#{ActiveSupport::Inflector.titleize(key)}: #{params[key]}"

		if params[key] == ""
			error_type = "Error 400 - Bad Request"
			error_message = "Looks like you've forgotten to include your #{ActiveSupport::Inflector.titleize(key).downcase}! Your best bet is to go <a href=\"/\">back</a> and try again."

			if ajax
				puts cgi.header("status" => "BAD_REQUEST", "type" => "application/json")
				puts({ :response_title => error_type, :response_message => error_message }.to_json)
			else
				puts cgi.header("status" => "BAD_REQUEST", "type" => "text/html")
				puts File.open("error.html.erb") { |file| ERB.new(file.read) }.result(binding)
			end

			log.error "Error 400 - Bad Request\n#{cgi.remote_addr} attempted to send a request without their #{ActiveSupport::Inflector.titleize(key).downcase}.\n#{cgi.params.inspect}"

			exit
		end
	end

	if params["name"].length > 255
		params["name"] = params["name"][0, 255]

		log.warn "#{cgi.remote_addr} attempted to send a request with a name that was too long and was truncated."
	end

		if params["email_address"].match(RFC2822::EmailAddress).nil?
		error_type = "Error 400 - Bad Request"
		error_message = "That's clearly not an email address. If you want our advice, <a href=\"/\">turn around</a> and try again with something that isn't gibberish."

		if ajax
			puts cgi.header("status" => "BAD_REQUEST", "type" => "application/json")
			puts({ :response_title => error_type, :response_message => error_message }.to_json)
		else
			puts cgi.header("status" => "BAD_REQUEST", "type" => "text/html")
			puts File.open("error.html.erb") { |file| ERB.new(file.read) }.result(binding)
		end

		log.error "Error 400 - Bad Request\n#{cgi.remote_addr} attempted to send a request with an invalid email address.\n#{cgi.params.inspect}"

		exit
	end

	if params["phone_number"].match(/^((([0-9]{1})*[- .(]*([0-9]{3})[- .)]*[0-9]{3}[- .]*[0-9]{4})+)*$/).nil?
		error_type = "Error 400 - Bad Request"
		error_message = "Hello? Oops, wrong number! Actually, that's not a phone number at all! Let's try <a href=\"/\">redialing</a> with a real U.S. phone number this time."

		if ajax
			puts cgi.header("status" => "BAD_REQUEST", "type" => "application/json")
			puts({ :response_title => error_type, :response_message => error_message }.to_json)
		else
			puts cgi.header("status" => "BAD_REQUEST", "type" => "text/html")
			puts File.open("error.html.erb") { |file| ERB.new(file.read) }.result(binding)
		end

		log.error "Error 400 - Bad Request\n#{cgi.remote_addr} attempted to send a request with an invalid phone number.\n#{cgi.params.inspect}"

		exit
	end

	if params["message"].length > 65535
		params["message"] = params[:message][0, 65535]

		params["message"] << "\n\nThis message was too long to display in its entirety and has been truncated."

		log.warn "#{cgi.remote_addr} attempted to send a request with a message that was too long and was truncated."
	end

	smtp_settings = YAML.load_file("../../smtp_settings.yml")

	log.debug smtp_settings.inspect

	#validate settings here, maybe

	unless test
		Net::SMTP.start(smtp_settings["smtp"]["address"], smtp_settings["smtp"]["port"], smtp_settings["smtp"]["helo"], smtp_settings["smtp"]["user"], smtp_settings["smtp"]["secret"], :plain) do |smtp|
			smtp.send_message "From: D & G Credit Service Contact Form <contact@dandgcreditservice.com>\nTo: <seaneshbaugh@gmail.com>\nSubject: New Message from D & G Credit Service Contact Form\n\nName: #{params["name"]}\nEmail: #{params["email_address"]}\nPhone: #{params["phone_number"]}\nMessage:\n#{params["message"]}", "contact@dandgcreditservice.com", "dana@dandgcreditservice.com"

			log.info "Email sent to admin with request information.\n#{cgi.params.to_s}"

			smtp.send_message "From: D & G Credit Service <contact@dandgcreditservice.com>\nTo: <#{params["email_address"]}>\nSubject: D & G Credit Service Contact Form Confirmation\n\nThis message has been sent to confirm your contact request with D & G Credit Service (http://dandgcreditservice.com/). We appreciate your interest and will respond as soon as possible (usually within a business day).\n\nIf you received this message in error please don't hesitate to send a reply to contact@dandgcreditservice.com and let us know someone goofed.", "contact@dandgcreditservice.com", params["email_address"]

			log.info "Email sent to sender with request confirmation.\n#{cgi.params.to_s}"
		end
	else
		log.debug "Contact form test."
	end

	if ajax
		puts cgi.header("status" => "OK", "type" => "application/json")
		puts({ :response_title => "Message Sent!", :response_message => "Thanks! Your message has been sent. You should receive a response shortly." }.to_json)
	else
		puts cgi.header("status" => "REDIRECT", "location" => "/thanks.html")
	end
rescue Exception => error
	log.error "#{error.message}\nBacktrace:\n#{error.backtrace.join("\n")}"
end
