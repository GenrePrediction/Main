require 'sqlite3'
require 'open-uri'
require 'nokogiri'

def getLyric(link, db)

  puts 'getting ' + link

  artist = String.new
  song = String.new
  lyrics = String.new

  begin
    doc = Nokogiri::HTML(open(link))

    doc.xpath('//h1').each do |node|
       data = node.text.split('by ')
       artist = data[1]
       song = data[0]
    end

    doc.xpath('//div').each do |node|
      if node['id'] == 'lyrics_outer'
        lyrics = node.text.strip! 
        lyrics = lyrics.slice(0..(lyrics.index('---Lyrics')-1))
      end
    end

    puts 'Saving in database ( ' + artist + ' - ' + song + ' )'

    db.execute("INSERT INTO lyrics(link, author, song, lyrics) VALUES(?, ?, ?, ?)", link, artist, song, lyrics)
  rescue Exception => e
    puts 'Cannot parse that...'
    puts e.message 
  end
end


db = SQLite3::Database.new('lyrics.db')
db.results_as_hash = true

#db.execute('CREATE TABLE lyrics(id INTEGER PRIMARY KEY, link TEXT, author TEXT, song TEXT, lyrics TEXT)')

db.execute('select * from links where genre>20') do |row|
  getLyric(row['link'], db)
end

