require 'open-uri'
require 'nokogiri'

require 'pg'

doc = Nokogiri::HTML(open('http://genre.lyricsfreak.com'))

main_genres = Hash.new
genres_parent = Hash.new
genre2link = Hash.new

doc.search("//a").each do |node|
  next if !node['href'].include?('html') or node['href'].include?('.com')
 
  #puts "#{node['href'].split('/').uniq.delete_if {|x| x == ''} }"
  genres = node['href'].split('/').uniq.delete_if {|x| x == ''}
  

  genres.each do |genre|
    
    main_genres[genre.split('.').first] = main_genres.length
    genre2link[genre.split('.').first] = node['href']
    if genre == genres.first
      genres_parent[genre.split('.').first] = nil
    else
      next if genres_parent.has_key?(genre.split('.').first)
      genres_parent[genre.split('.').first] = genres[genres.index(genre) - 1]
    end
  end 
end

puts "Saving in db..."

conn = PGconn.connect("localhost", 5432, '', '', "lyrics", "pgadmin", "postgres")
main_genres.each do |k, v|
  begin
    conn.exec("INSERT INTO genres(id, name, url) VALUES(#{v},'#{k}', '#{genre2link[k]}')")
  rescue Exception => e
    puts "Something goes wrong: '#{e.message}'" 
    next
  end
end

genres_parent.each do |k, v|
  next if v == nil
  begin
   conn.exec("UPDATE genres SET parent=#{main_genres[v]} WHERE id=#{main_genres[k]}")
  rescue Exception => e
    puts "Something goes wrong: '#{e.message}'" 
    next
  end
end

artists = Hash.new
artist_genre = Hash.new
artists_url = Hash.new

#k = 'dance_pop'
main_genres.each do |k, v|
  page = 1
  while true
    #url = "http://genre.lyricsfreak.com/poprock/dance/dance_pop#{page}.html"
    g = genre2link[k].gsub('.html', String.new(page.to_s + '.html'))
    url = "http://genre.lyricsfreak.com#{g}"
    puts "Checking url '#{url}'"
   
    doc = nil
    begin
      doc = Nokogiri::HTML(open(url))
      break if doc.text.include?("We couldn't find the page you were looking for. Please check out:");
    rescue Exception => e
      puts "Something goes wrong: '#{e.message}'" 
      break
    end

    page += 1
    doc.xpath("//a").each do |node|
      next if node['title'] == nil
      artist = node['title'].split('Lyrics').first

      if !artists.has_key?(artist)
        artists[artist] = artists.length
      end

      artist_genre[artist] ||= Array.new
      artist_genre[artist].push(main_genres[k])

     #puts "href: #{node['href']}"
      artists_url[artist] = node['href']
    end
  end
end

artists.each do |k, v|
  next if k == nil
  #puts "#{v},'#{k.gsub(/\\|'/, '')}', '#{artists_url[k]}'"
  begin
    conn.exec("INSERT INTO artists(id, name, url) VALUES(#{v},'#{k.gsub(/\\|'/, '')}', '#{artists_url[k]}')")
  rescue Exception => e
    puts "Something goes wrong: '#{e.message}'" 
    break
  end
end

artist_genre.each do |k,v|
  next if k == nil
  v.each do |g|
    #puts "K: #{artists[k]} G: #{g}"
  begin
    conn.exec("INSERT INTO artists_genres(artist_id, genre_id) VALUES(#{artists[k]}, #{g})")
    rescue Exception => e
      puts "Something goes wrong: '#{e.message}'" 
      break
    end
  end
end

artists.each do |k,v|

  url = artists_url[k]
  #url = 'http://www.lyricsfreak.com/a/amen+corner/'
  doc = nil
  begin
    doc = Nokogiri::HTML(open(url))
rescue Exception => e
    puts "Something goes wrong: '#{e.message}'" 
    next
  end

  next if doc == nil

  doc.search("//a").each do |node|
    next if !node['href'].include?(url) or node['href'] == url
    title = node['title'].to_s.split('Lyrics').first
    song_url = node['href'].to_s

    puts "Saving #{k} - #{title}"  

    song_doc = nil
    begin
      song_doc = Nokogiri::HTML(open(song_url))
    rescue Exception => e
      puts "Something goes wrong: '#{e.message}'" 
      next
    end

    next if song_doc == nil

    song_doc.xpath("//div[@id='content_h']").each do |div|
      text = div.text.split("[ Lyrics").first
      next if text == nil

      if title == nil
        title = 'Untitled'
      end

     #puts "k: #{k}, #{v}, artist: #{artists[k]}"
    
      begin
        conn.exec("INSERT INTO songs(artist_id, name, lyrics, url) VALUES( #{v}, '#{title.gsub(/\\|'/, '')}', '#{text.gsub(/\\|'/, '')}', '#{song_url}')")
      rescue Exception => e
        puts "Something goes wrong: '#{e.message}'" 
        next
      end   
    end
  end
end

conn.close


