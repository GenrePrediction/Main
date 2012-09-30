require 'stemmer'
require 'sqlite3'

db = SQLite3::Database.new('lyrics.db')
db.results_as_hash = true

words = Hash.new

db.execute('select * from lyrics') do |row|
  begin
    puts "Checking #{row['artist']} - #{row['song']}"
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

db.close

puts "#{words.length} words found"
words.each do |word|
  puts "#{word}"
end
