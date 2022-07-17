
require 'discordrb'
require 'audioinfo'
require 'byebug'

bot = Discordrb::Commands::CommandBot.new token: ENV["BOT_TOKEN"]



bot.message(content: 'turn music on') do |event|
  channel = event.user.voice_channel
  bot.voice_connect(channel)

  voice_bot = event.voice
  played_songs = [0]
  voice_bot.adjust_offset = 10
  time_until_end = 0
  
  while played_songs.length < 43 do #ToDo: change counter to dynamic count of files at repository
    song_id = rand_song_id(played_songs)
    played_songs << song_id
    #time_until_end = get_song_time(song_id) #ToDo:add automatic counter to show how much time left before end track
    voice_bot.play_file("./music/#{song_id}.mp3") #ToDo: change logic to dynamicly get mp3 fyles from repository
  end
end

bot.message(content: 'Get out') do |event|
  voice_bot = event.voice
  voice_bot.destroy
end

bot.message(content: 'Come in') do |event|

  channel = event.user.voice_channel

  next "You're not in any voice channel!" unless channel

  bot.voice_connect(channel)
  "Connected to voice channel: #{channel.name}"
end

def rand_song_id(played_songs)#ToDo: change counter to dynamic count of files at repository
  begin
    song_id = rand(1-43)
  end until ! played_songs.include? song_id
  song_id
end

def get_song_time(song_id) # method for calculating time for file work
  time_until_end = 0
  AudioInfo.open("./music/#{song_id}.mp3") do |info| #ToDo: change logic to dynamicly get mp3 fyles from repository
    time_until_end = info.length 
  end
  time_until_end
end

bot.run