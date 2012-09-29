require 'open-uri'
require 'nokogiri'

require 'sqlite3'

require 'set'

links = Set.new

genre = 30
page = 0
step = 20

begin
  doc = Nokogiri::HTML(open('http://www.lyrics.com/tophits/genres/' + page.to_s + '/' + genre.to_s))
  newLinks = Set.new

  doc.xpath('//a').each do |node|
    newLinks.add(node['href']) if node['href'].include? 'http' and node['href'].include? 'html'
  end

  links.merge(newLinks)
  puts 'Actual found ' + links.count.to_s + ' links' + ' (' + newLinks.size.to_s + ' new) at page ' + page.to_s
  page = page + step
end while newLinks.size > 0

puts 'Unique links found: ' + links.size.to_s

puts 'Saving in database'
db = SQLite3::Database.new('lyrics.db')
#db.execute('CREATE TABLE links(id INTEGER PRIMARY KEY, genre NUMERIC, link TEXT)')

links.each do |link|
  db.execute("insert into links(genre, link) values(?, ?)", genre.to_s, link) 
end

puts 'Done!'





