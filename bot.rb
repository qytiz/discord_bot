
require 'discordrb'
require 'audioinfo'
require 'byebug'
require 'redis'

bot = Discordrb::Commands::CommandBot.new token: ENV['BOT_TOKEN']
redis = Redis.new

bot.message(content: 'turn music on') do |event|
  channel = event.user.voice_channel
  bot.voice_connect(channel)

  redis.del(event.server.id.to_s+'song_looped')
  voice_bot = event.voice
  redis.del(event.server.id.to_s + 'song_id')
  played_songs = [0]
  voice_bot.adjust_offset = 10
  time_until_end = 0
  
  while played_songs.length < file_counter do
    server_id = event.server.id.to_s
    looped_song(redis.get(server_id+'song_id'), server_id,voice_bot) if redis.get(event.server.id.to_s+'song_looped')
    song_id = rand_song_id(played_songs)
    played_songs << song_id
    event.respond 'Now play:'
    event.respond get_song_name(song_id)
    redis.set(server_id+'song_id',song_id)
    voice_bot.play_file("./music/#{song_id}.mp3") #ToDo: change logic to dynamicly get mp3 fyles from repository
  end
  redis.del(event.server.id.to_s+'song_id')
  redis.del(event.server.id.to_s+'song_looped')
end

bot.message(content:'loop') do |event|
  song = redis.get(event.server.id.to_s+'song_id')
  unless song
    return event.respond 'No music played' 
    break
  end

  if redis.get(event.server.id.to_s+'song_looped')
    redis.del(event.server.id.to_s+'song_looped')
    event.respond 'song unlooped'
    break
  end

  redis.set(event.server.id.to_s+'song_looped',true)
  event.respond 'song looped'
end

bot.message(content: 'time') do |event|
  voice_bot = event.voice
  time_total = song_time_simplified(redis.get(event.server.id.to_s+'song_id'))
  time = [ voice_bot.stream_time.to_i / 60 % 60, voice_bot.stream_time.to_i % 60].map{|t| t.to_s.rjust(2,'0')}.join(':')
  if time_total
    event.respond "#{time}/#{ time_total }" 
  else 
    event.respond "No music now"
  end
end

bot.message(content: 'time left') do |event|
  voice_bot = event.voice
  time_total = get_song_time(redis.get(event.server.id.to_s+'song_id'))
  time = voice_bot.stream_time.to_i
  time_result = time_total-time
  time_left = [ time_result / 60 % 60, time_result % 60].map{|t| t.to_s.rjust(2,'0')}.join(':')
  if time_total
    event.respond "left: #{time_left}" 
  else 
    event.respond "No music now"
  end
end

bot.message(content: 'Get out') do |event|
  voice_bot = event.voice
  voice_bot.destroy
  redis.del(event.server.id.to_s+'song_looped')
end

bot.message(content: 'Come in') do |event|

  channel = event.user.voice_channel

  event.respond "You're not in any voice channel!" unless channel

  bot.voice_connect(channel)
  event.respond "Connected to voice channel: #{channel.name}"
end

def rand_song_id(played_songs)
  begin
    song_id = rand(1-file_counter)
  end until ! played_songs.include? song_id
  song_id
end

def song_time_simplified(song_id) 
  time_until_end = get_song_time(song_id)
  [ time_until_end / 60 % 60, time_until_end % 60].map{|t| t.to_s.rjust(2,'0')}.join(':')
end

def get_song_time(song_id)
  time_until_end = 0
  AudioInfo.open("./music/#{song_id}.mp3") do |info| #ToDo: change logic to dynamicly get mp3 fyles from repository
    time_until_end = info.length 
  end
end

def get_song_name(song_id)
  song_name = nil
  AudioInfo.open("./music/#{song_id}.mp3") do |info| 
  song_name = "#{info.artist} - #{info.title} "
  end
  song_name + song_time_simplified(song_id).to_s
end

def file_counter
  dir = './music'

  @file_counter ||= Dir[File.join(dir, '**', '*')].count { |file| File.file?(file) }
end

def looped_song(song_id,server_id,voice_bot)
  
  while looped?(server_id)
    voice_bot.play_file("./music/#{song_id}.mp3")
  end
end

def looped?(server_id)
  redis=Redis.new
  looped_song = redis.get(server_id+'song_looped')
  redis.close
  false unless looped_song
  true
end

bot.run