#!/usr/bin/ruby

require 'open-uri'

#today = Time.new.strftime("%Y-%m-%d")
today = Date.today

# Set up player database in memory
yahoo_players_database = {}
File.open("../../../db/yahoo_players_database.csv").read.each_line do |line|
	stats = line.split(',')
	player = stats[0]
	yahoo_players_database[player] = {}
	stats.drop(1).each do |stat|
		date = stat.split(':')[0].strip
		position = stat.split(':')[1].strip
		yahoo_players_database[player][date] = position
	end
end

# run through today's yahoo stats
yahoo_players = []
i = 0
(0..200).step(50) do |n|
	open("http://football.fantasysports.yahoo.com/f1/draftanalysis?tab=SD&pos=ALL&sort=DA_AP&count=#{n}").read.each_line do |line|
		if line.include? "ysf-player-name"
			i += 1
			player = "#{line.match(/blank">(.+)<\/a>/)[1]}"
			if !yahoo_players_database.has_key? player
				yahoo_players_database[player] = {}
			end
			yahoo_players.push(player)
			yahoo_players_database[player][today] = i.to_s.strip
		end
	end
end

# run through today's fp stats
fantasypros_players = []
open("https://www.fantasypros.com/nfl/rankings/consensus-cheatsheets.php").read.each_line do |line|
	if line.include? "fp-player-name"
		fantasypros_players.push("#{line.match(/fp-player-name="(.+)"/)[1]}")
	end
end

# print out the stat comparison in table format for html
i=0
yahoo_players.each do |player|
	if !fantasypros_players.include? player
		next
	end
	#puts "<tr><td>#{player}</td><td>#{i + 1}</td><td style=\"visibility:hidden\">#{i - fantasypros_players.index(player)}</td><td><button onClick=\"rate(this)\">down</button><button onClick=\"rate(this)\">same</button><button onClick=\"rate(this)\">up</button></td></tr>"
	i += 1
end

# write to csv file for latest "db" update
database = File.open("../../../db/yahoo_players_database.csv", "w")
yahoo_players_database.each do |player, stats|
	line = "#{player}"
	stats.each do |date, stat|
		line += ",#{date}:#{stat}"
	end
	database.puts("#{line}")
end