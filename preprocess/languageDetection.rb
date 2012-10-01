require 'sqlite3'
require 'wtf_lang'

WtfLang::API.key = '2310f653efdebf2aee5c62c425706206'

db = SQLite3::Database.new('lyrics.db')
db.results_as_hash = true


db.execute('select * from lyrics where lang is null') do |row|
  print 'Checking ', row['author'], ' - ', row['song'], ': '
  begin
    vl = row['lyrics'].lang
    puts vl
    db.execute("update lyrics set lang='#{vl}' where id=#{row['id']}")
  rescue Exception => e
    puts 'Error occured...'
    puts e.message 
  end
end

db.close
