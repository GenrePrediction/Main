require 'sqlite3'
require 'stemmer'

db = SQLite3::Database.new('lyrics.db')
db.results_as_hash = true

genres_count = db.execute("SELECT count(*) AS c FROM (SELECT DISTINCT author, song FROM lyrics WHERE lang='en')")[0]['c']

puts "We have #{genres_count} unique genres"

words_probability = Hash.new
categories_probability = Hash.new
db.execute('SELECT DISTINCT genre FROM links') do |category|
  categories_probability[category['genre']] = db.execute("SELECT count(*) as c FROM (SELECT DISTINCT lyrics.author, lyrics.song FROM lyrics INNER JOIN links ON lyrics.link=links.link WHERE lyrics.lang='en' AND links.genre=#{category['genre']})")[0]['c'].to_f/genres_count.to_f
  puts "P(#{category['genre']})=#{categories_probability[category['genre']]}"

  words_in_category = db.execute("SELECT sum(count) AS c FROM words WHERE category=#{category['genre']}")[0]['c']
  puts "We have #{words_in_category} words in genre #{category['genre']}"
  db.execute("SELECT word,count FROM words WHERE category=#{category['genre']}") do |row|
    words_probability[category['genre']] ||= Hash.new
    words_probability[category['genre']][row['word']] = row['count'].to_f/words_in_category.to_f
    puts "P(#{row['word']}|#{category['genre']})=#{words_probability[category['genre']][row['word']]}"
  end
end


input = "You're a fraud and you know it
But it's too good to throw it all away
Anyone would do the same
You've got 'em going
And you're careful not to show it
Sometimes you even fool yourself a bit
It's like magic
But it's always been a smoke and mirrors game
Anyone would do the same
So now that you've arrived well you wonder
What is it that you've done to make the grade
And should you do the same?
(Is that too easy?)
Are you only trying to please them
(Will they see then?)
You're desperate to deliver
Anything that could give you
A sense of reassurance
When you look in the mirror
Such highs and lows
You put on quite a show
All these highs and lows
And you're never really sure
What you do it for
Well do you even want to know?
You put on quite a show
(Mother)
Are you watching?
Are you watching?
(Mother)
Are you watching?
(Mother)
You're a fraud and you know it
And every night and day you take the stage
And it always entertains
You're giving pleasure
And that's admirable, you tell yourself
And so you'd gladly sell yourself
To others
(Mother)
Are you watching?
(Mother)
Are you watching?
(Mother)
Are you watching?
(Mother)
Are you watching?
Such highs and lows
You put on quite a show
All these highs and lows
And you're never really sure
What you do it for
Well do you even want to know?
Yeah you put on quite a show"

puts "Checking song..."

pr = Hash.new
db.execute('SELECT DISTINCT genre FROM links') do |category|
  tmp = String.new(input)
  puts "Checking genre #{category['genre']}"
  tmp = tmp.gsub!(/[^a-zA-Z ]/, ' ');
  #sputs tmp
  next if tmp == nil

  words = Hash.new
  tmp.split.each do |word|
    stem = word.downcase.stem
 
    next if stem.length < 3

    next if !words_probability[0].has_key?(stem)

    if words.has_key?(stem) then
      words[stem] = words[stem] + 1
    else
      words[stem] = 1
    end

    #puts("pr=#{words_probability[0]}[stem]")
    #pr *= words_probability[0][stem].to_f
  
  end

  
  words.each do |key, value|
    next if !words_probability[category['genre']].has_key?(key)

    pr[category['genre']] ||= 1
    pr[category['genre']] *=  value.to_f * words_probability[category['genre']][key].to_f
  end

  #puts "Pr(#{category['genre']})=#{ pr[category['genre']]}"
end

db.close

puts "Song belongs to this with PR=#{pr.sort_by{|key, value| value}}"
