require_relative 'classifier'
require 'sqlite3'


db = SQLite3::Database.new('../preprocess/lyrics.db')
db.results_as_hash = true

cl = Classifier.new

puts "Starting training..."

db.execute('SELECT category, word, count FROM words') do |row|
  cl.train(row['category'], row['word'], row['count'])
end

classification = Array.new
db.execute("SELECT genre, lyrics FROM lyrics INNER JOIN links ON lyrics.link=links.link WHERE lang='en' and  (links.id % 10) = 0") do |test_row|
  

  if(cl.classify(test_row['lyrics'])[0][0] == test_row['genre'])
    classification.push(true)
    puts "#{test_row['genre']} = #{cl.classify(test_row['lyrics'])}"
  else
    classification.push(false)
  end
end

db.close

puts "Classified as #{classification} so there was #{classification.count(false)} errors in #{classification.size} length set"


