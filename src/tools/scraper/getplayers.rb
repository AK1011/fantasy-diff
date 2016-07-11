#!/usr/bin/ruby
require 'open-uri'

def writeHtmlPage (database)
	i=0
	yahoo_players.each do |player|
		if !fantasypros_players.include? player
			next
		end
		puts "<tr><td>#{player}</td><td>#{i + 1}</td><td style=\"visibility:hidden\">#{i - fantasypros_players.index(player)}</td><td><button onClick=\"rate(this)\">down</button><button onClick=\"rate(this)\">same</button><button onClick=\"rate(this)\">up</button></td></tr>"
		i += 1
	end
end

def loadDatabase (name)
	dates = []
	database = {}
	filename = "../../../db/#{name}_players_database.csv"
	firstLine = true
	if File.file?(filename)
		File.open(filename).read.each_line do |line|
			if firstLine
				dates.concat(line.split(',').drop(1))
				dates = dates.map {|date| date.strip}
				firstLine = false
				next
			end
			stats = line.split(',')
			player = stats[0]
			database[player] = {}
			date = 0
			stats.drop(1).each do |stat|
				database[player][dates[date]] = stat.strip
				date += 1
			end
		end
	end
	return database, dates
end

def addTodaysRankingsFromList (database, site, player_line_delimiter, player_name_match, startAt)
	rank = startAt
	open(site).read.each_line do |line|
		if line.include? player_line_delimiter
			rank += 1

			player = "#{line.match(player_name_match)[1]}"
			if !database.has_key? player
				database[player] = {}
			end

			database[player][Date.today.to_s] = rank.to_s.strip
		end
	end
	return database
end

def writeDatabase (name, database, dates)
	csv = File.open("../../../db/#{name}_players_database.csv", "w")
	
	# write the dates as the column names
	csv.puts "players,#{dates * ","}"

	database.each do |player, stats|
		daily_stats = []
		dates.each do |date|
			if stats.has_key? date
				daily_stats.push(stats[date].to_s.strip)
			else
				daily_stats.push("")
			end
		end
		csv.puts("#{player},#{daily_stats * ","}")
	end
end


### MAIN ###

# load databases
yahoo_db, yahoo_dates = loadDatabase("yahoo")
fp_db, fp_dates = loadDatabase("fantasypros")

# add new fp rankings
new_fp_db = addTodaysRankingsFromList(fp_db, "https://www.fantasypros.com/nfl/rankings/consensus-cheatsheets.php", "fp-player-name", /fp-player-name="(.+)"/, 0)
fp_dates.push(Date.today.to_s) unless fp_dates.include?(Date.today.to_s)

# add new yahoo rankings
new_yahoo_db = {}
i = 0
(0..200).step(50) do |n|
	new_yahoo_db = new_yahoo_db.merge(addTodaysRankingsFromList(yahoo_db, "http://football.fantasysports.yahoo.com/f1/draftanalysis?tab=SD&pos=ALL&sort=DA_AP&count=#{n}", "ysf-player-name", /blank">(.+)<\/a>/, n))
end
yahoo_dates.push(Date.today.to_s) unless yahoo_dates.include?(Date.today.to_s)

# write databases
writeDatabase("yahoo", new_yahoo_db, yahoo_dates)
writeDatabase("fantasypros", new_fp_db, fp_dates)