require 'stemmer'
require 'sqlite3'

db = SQLite3::Database.new('lyrics.db')
db.results_as_hash = true

db.execute("select genre from links group by genre") do |genre_row|
 
  words = Hash.new
  
  db.execute("SELECT links.genre, lyrics.author, lyrics.song, lyrics.lyrics FROM lyrics INNER JOIN links ON lyrics.link=links.link WHERE lang='en' and genre=#{genre_row['genre']} and (links.id % 10) != 0") do |row|

  begin
    puts "Checking #{row['author']} - #{row['song']}"
    row['lyrics'].gsub!(/[^a-zA-Z ]/, ' ').split.each do |word|
      stem = word.downcase.stem
 
      next if stem.length < 3

      if words.has_key?(stem) then
        words[stem] = words[stem] + 1
      else
        words[stem] = 1
      end
    end
  rescue
    puts "Something goes wrong for #{row['author']} - #{row['song']}"
  end

  end

  puts "#{words.length} words found in category #{genre_row['genre']}"
  words.each do |word|
    db.execute("INSERT INTO words(category, word, count) VALUES(?, ?, ?)", genre_row['genre'], word[0], word[1])
  end

end

db.close






