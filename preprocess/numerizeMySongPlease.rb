require 'sqlite3'
require 'stemmer'

db = SQLite3::Database.open('lyrics.db')
db.results_as_hash = true

word2id = Hash.new

puts 'Creating temporary mapping'

db.execute("SELECT * FROM word_num") do |word_row|
  word2id[word_row['word']] = word_row['id']
end


puts 'Temporary mapping created'

songs = Hash.new

db.execute("select id, lyrics from lyrics") do |lyric|
 begin
    numeric_song = ""
    lyric['lyrics'].gsub!(/[^a-zA-Z ]/, ' ').split.each do |word|
      stem = word.downcase.stem
 
      next if stem.length < 3

      numeric_song = "#{numeric_song} #{word2id[stem]}"
      
    end

    db.execute("UPDATE lyrics SET numerized='#{numeric_song}' WHERE id=#{lyric['id']}");

    #songs[lyric['id']] = numeric_song
  rescue Exception => e
    puts "Something goes wrong for #{lyric['id']}"
    puts e.message
  end

  puts "song #{lyric['id']} transformed"

end

db.close
