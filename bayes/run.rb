require_relative 'classifier'
require 'pg'

conn = PGconn.connect("localhost", 5432, '', '', "lyrics", "pgadmin", "postgres")


categories = Hash.new
conn.exec("SELECT DISTINCT genres.name, songs.lyrics FROM artists_genres 
  INNER JOIN genres ON artists_genres.genre_id=genres.id
  RIGHT JOIN songs ON songs.artist_id=artists_genres.artist_id 
  WHERE genres.name IN ('dance', 'hard_rock') 
  AND genres.name IS NOT NULL 
  AND songs.lyrics IS NOT NULL").each do |row|
  
  categories[row['name']] ||= Array.new
  categories[row['name']].push(row['lyrics'])

end



cl = Classifier.new
puts "Starting training..."

categories.each do |category, songs|
  songs.each do |song|
    song.gsub(/\W+/, ' ').split(' ').each do |word|
     cl.train(category, word)
    end
  end
end

cl.info

puts "Classifying"

conn.exec("SELECT DISTINCT genres.name, songs.lyrics FROM artists_genres 
  INNER JOIN genres ON artists_genres.genre_id=genres.id
  RIGHT JOIN songs ON songs.artist_id=artists_genres.artist_id 
  WHERE genres.name IN ('hard_rock') LIMIT 1").each do |row|
 
  puts "Classified as: #{cl.classify(row['lyrics'])}"

end

conn.close

#db.execute('SELECT category, word, count FROM words') do |row|
#  cl.train(row['category'], row['word'], row['count'])
#end

#classification = Array.new
#db.execute("SELECT genre, lyrics FROM lyrics INNER JOIN links ON lyrics.link=links.link WHERE lang='en' and  (links.id % 10) = 0") do |test_row|
  

#  if(cl.classify(test_row['lyrics'])[0][0] == test_row['genre'])
#    classification.push(true)
#  else
#    puts "#{test_row['genre']} = #{cl.classify(test_row['lyrics'])}"
#    classification.push(false)
#  end
#end

#db.close

#puts "Classified as #{classification} so there was #{classification.count(false)} errors in #{classification.size} length set"


