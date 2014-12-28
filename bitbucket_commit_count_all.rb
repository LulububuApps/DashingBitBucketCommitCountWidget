#!/usr/bin/env ruby
require 'net/http'
require "net/https"
require 'json'

# This job will count the commits of a all your bitbucket projects

# Config
bitbucket_repo_username = ""
bitbucket_username = ""
bitbucket_password = ""

# Function
def getCommitCount (repo_username, username, password, repo_name = nil)
	commit_count = 0
	
	next_page = "/api/2.0/repositories/#{repo_username}?page=1"
	
	while next_page != nil do
		puts "Loading #{next_page}"
	
		http = Net::HTTP.new("bitbucket.org", Net::HTTP.https_default_port())
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?
		req = Net::HTTP::Get.new(next_page)
		req.basic_auth username, password
		response = http.request(req)
	  
		if response.code != "200" && response.code != 200
			puts "bitbucket api error (status-code: #{response.code})\n#{response.body}"
		else
			data = JSON.parse(response.body)
		
			next_page = data.has_key?("next") ? data["next"] : nil;
			
			data['values'].each do |repository|
				puts "Loading #{repository['full_name']} (\"/api/1.0/repositories/#{repository['full_name']}/changesets/\")"
				http_repo = Net::HTTP.new("bitbucket.org", Net::HTTP.https_default_port())
				http_repo.use_ssl = true
				http_repo.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?
				req_repo = Net::HTTP::Get.new("/api/1.0/repositories/#{repository['full_name']}/changesets/")
				req_repo.basic_auth username, password
				response_repo = http_repo.request(req_repo)
			
				if response_repo.code != "200" && response_repo.code != 200
					puts "bitbucket api error level 2 (status-code: #{response_repo.code})\n#{response_repo.body}"
				else		
					data_repo = JSON.parse(response_repo.body)
				
					commit_count += data_repo['count']
					
					puts "#{repository['full_name']} --> #{data_repo['count']}"
				end
			end
		end
	end

	return commit_count;
end

# getCommitCount(bitbucket_repo_username, bitbucket_username, bitbucket_password)

SCHEDULER.every '5m', :first_in => 0 do |job|
	count = getCommitCount(bitbucket_repo_username, bitbucket_username, bitbucket_password)
 
	send_event('bitbucket_commit_count_all', current: count)
end