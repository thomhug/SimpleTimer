#!/usr/bin/env ruby
# Query Xcode Cloud build runs via App Store Connect API (Spaceship)
# Usage: ruby scripts/query-builds.rb [limit]

# Load fastlane's bundled gems
$LOAD_PATH.unshift(*Dir["/usr/local/Cellar/fastlane/*/libexec/gems/*/lib"])
Dir["/usr/local/Cellar/fastlane/*/libexec/gems/fastlane-*"].each do |fl|
  %w[spaceship fastlane_core credentials_manager fastlane].each do |sub|
    path = File.join(fl, sub, "lib")
    $LOAD_PATH.unshift(path) if File.directory?(path)
  end
end

require "spaceship"
require "dotenv"
Dotenv.load(File.expand_path("../../.env", __FILE__))

APPLE_ID = ENV.fetch("APPLE_ID")
CI_PRODUCT_ID = ENV.fetch("CI_PRODUCT_ID")

limit = (ARGV[0] || 10).to_i

Spaceship::ConnectAPI.login(APPLE_ID)
client = Spaceship::ConnectAPI.client.tunes_request_client
runs = client.get("v1/ciProducts/#{CI_PRODUCT_ID}/buildRuns", {"limit" => limit})

runs.body["data"].each do |run|
  attrs = run["attributes"]
  num = attrs["number"]
  status = attrs["completionStatus"]
  started = attrs["startedDate"]&.slice(0, 16)&.sub("T", " ")
  commit = attrs.dig("sourceCommit", "commitSha")
  message = attrs.dig("sourceCommit", "message")&.split("\n")&.first
  short_commit = commit ? commit[0..7] : "no commit"

  indicator = case status
              when "SUCCEEDED" then "OK"
              when "FAILED"    then "FAIL"
              else status
              end

  puts "#%-3d %-4s  %s  %s  %s" % [num, indicator, started, short_commit, message]
end
