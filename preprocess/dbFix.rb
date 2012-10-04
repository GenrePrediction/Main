require 'sqlite3'

db = SQLite3::Database.new('lyrics.db')
db.results_as_hash = true

db.execute("SELECT DISTINCT word  FROM words") do |word_row|
  db.execute("INSERT INTO word_num(word) VALUES( ? )", word_row['word'])
  puts "#{word_row['word']} saved"
end

db.close();
