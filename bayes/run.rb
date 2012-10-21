require_relative 'classifier'
require 'pg'

conn = PGconn.connect("localhost", 5432, '', '', "lyrics", "pgadmin", "postgres")
#95% ~40sec
#test_str = "'power_metal', 'blues_rock'"
#50% ~1m25sec
#test_str = "'power_metal', 'blues_rock', 'thrash'"
#36% ~1m36
#test_str = "'power_metal', 'blues_rock', 'alternative_metal'"
#30% ~2m19
#test_str = "'power_metal', 'blues_rock', 'alternative_metal', 'thrash'"
#55% ~1m34
#test_str = "'alternative_metal', 'thrash'"
#25%  45%  55% 3m24
#test_str = "'alternativeindie_rock', 'art_rockexperimental', 'dance',
#            'folcountry_rock', 'hard_rock', 'punknew_wave', 
#            'rock_rollroots', 'psychedelicgarage', 'europop',
#            'british_invasion', 'big_bandswing', 'cool', 'free_jazz',
#            'fusion', 'hard_bop', 'new_orleansclassic_jazz', 'soul_jazzgroove',
#            'hip_hopurban', 'rbsoul', 'alternative_country', 
#            'contemporary_country', 'country_pop', 'honky_tonk',
#            'progressive_country', 'traditional_country', 'western_swing',            
#            'chicago_clues', 'country_blues', 'delta_blues', 
#            'east_coast_blues', 'modern_electric_blues', 'electric_blues',           
#            'jump_bluespiano_blues', 'worldbeat', 'africa',
#            'australasia', 'celticbritish_isles', 'reggaecaribbean',
#            'central_asia', 'latin_america', 'mediterranean', 'middle_east'   
#            'scandinavia', 'western_europe', 'tropical', 'electronica'"

#43% 60%  75% 2m31 
#test_str = "'alternativeindie_rock', 'art_rockexperimental', 'dance',
#            'folcountry_rock', 'hard_rock', 'punknew_wave', 
#            'rock_rollroots', 'psychedelicgarage', 'europop',
#            'hip_hopurban', 'rbsoul', 'alternative_country', 
#            'contemporary_country', 'country_pop', 'honky_tonk',          
#            'east_coast_blues', 'modern_electric_blues', 'electric_blues',           
#            'jump_bluespiano_blues', 'worldbeat', 'africa',
#            'australasia', 'celticbritish_isles', 'reggaecaribbean',  
#            'scandinavia', 'western_europe', 'tropical', 'electronica'"

#fast
test_str = "'poprock', 'jazz', 'rb', 'country', 'blues', 'world', 'electronica'"

query = "SELECT DISTINCT genres.name, songs.lyrics FROM artists_genres 
  INNER JOIN genres ON artists_genres.genre_id=genres.id
  RIGHT JOIN songs ON songs.artist_id=artists_genres.artist_id 
  WHERE genres.name IN ( #{test_str} )"
puts query

categories = Hash.new
conn.exec(query).each do |row|
  
  categories[row['name']] ||= Array.new
  categories[row['name']].push(row['lyrics'])
end

conn.close

probes = 5
probe_size = 0
categories2test = Hash.new

categories.keys.each do |k|
  c = categories[k].length/probes
  puts "Saving #{c} training songs for category #{k}"
  while c > 0
    categories2test[k] ||= Array.new
    categories2test[k].push(categories[k].shuffle!.first)
    categories[k].delete_at(0)
    c -= 1
    probe_size += 1
  end
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

classified = 0
classified_as2 = 0
classified_as3 = 0

puts "Classifying"
categories2test.each do |k,v|
  v.each do |song| 
    classification = cl.classify(song)
    
    classified     += 1 if classification[0][0] == k 
    classified_as2 += 1 if classification[1][0] == k
    next if categories2test.keys.length < 3
    classified_as3 += 1 if classification[2][0] == k
  end
end

puts ""
hit_rate = (classified).to_f/(probe_size.to_f)
puts "Proper classification HitRate: #{classified}/#{probe_size} => #{hit_rate}"

hit_rate = (classified + classified_as2).to_f/(probe_size.to_f)
puts "Classified int TOP2: #{classified_as2} =>  #{hit_rate}"

return if categories2test.keys.length < 3
hit_rate = (classified + classified_as2 +classified_as3).to_f/(probe_size.to_f)
puts "Classified int TOP3: #{classified_as3} =>  #{hit_rate}"






