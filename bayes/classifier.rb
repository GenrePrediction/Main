require 'stemmer'

class Classifier

  def initialize()
    @initialized = false

    @count_class = Hash.new
    @count_word = Hash.new
    @word_probabilities = Hash.new 
    @class_probabilities = Hash.new

    @sum_of_words = 0
  end

  def info
    puts "Classifier knows about #{@count_word.keys} categories and it have"
    @count_word.keys.each { |k| puts "#{k} => #{@count_word[k].length}" }
    puts "unique words trained"
  end

  def train(p_class, p_word, count=1)
    @initialized = false

    word = String.new(p_word)
    word = self.prepare_word(word)
    return if word == nil or word.length < 3

#    puts "Training [#{p_class}] class with word: #{word}"

    @count_word[p_class] ||= Hash.new
    @count_word[p_class][p_word.downcase] ||= 0
    @count_word[p_class][p_word.downcase] += count

  end

  def prepare_word(word)
    word.stem.downcase.gsub(/[^a-zA-Z ]/, '')
  end

  def classify(input)
    probabilities = Hash.new
    @count_word.keys.each do |key| 
      probabilities[key] = self.pr_in_category(input, key) 
    end

    return probabilities.sort_by {|k,v| v}.reverse
  end

  def pr_in_category(input, category)
    self.create_classifier if !@initialized
    @initialized = true

    pr = 1
    pr_zero = true
    input_hash = self.preprocess(input)
    #puts "Hash: #{input_hash}"
    input_hash.each do |v_word, v_count|
      next if !@word_probabilities[category].has_key?(v_word)
      if !@word_probabilities[category].has_key?(v_word)
        @word_probabilities[category][v_word] = 1/@sum_of_words
      end

      pr_zero = false
      pr *= @word_probabilities[category][v_word] ** v_count
      #puts "P(#{v_word}|#{category})=#{@word_probabilities[category][v_word]}"     
    end

    if pr_zero 
      return 0
    else
      return @class_probabilities[category] * pr
    end
  end

  #this should be private
  def preprocess(input)

    tmp = String.new(input)
    output = Hash.new

    #print "tmp is '#{tmp}' and its gsub is '#{tmp.gsub(/[^a-zA-Z ]/, ' ')}'"

    tmp.gsub(/[^a-zA-Z ]/, ' ').split.each do |word|
      stem = word.downcase.stem
      next if stem.length < 3
      output[stem] ||= 0
      output[stem] += 1
    end

     return output
  end

  def create_classifier
    puts "Creating classifier"
    
    @sum_of_words = 0
    @count_word.each do |v_class, v_word|
      v_word.each { |v_w, v_num| @sum_of_words += v_num }
    end

    num_of_categories = @count_word.length

    puts "#{@sum_of_words} words in #{num_of_categories} categories to train the classifier"

    @count_word.keys.each { |v_class| self.determine_probabilities(v_class) }
    

  end

  def determine_probabilities(p_class)
    words_in_class = 0
    @count_word[p_class].each { |v_word, v_num| words_in_class += v_num }

    puts "We have #{words_in_class} words in class #{p_class}"

    @word_probabilities[p_class] = Hash.new
    @count_word[p_class].each do |v_word, v_num|
      word_count = 0;
      @count_word.each do |v_class, v_word_hash|
        if v_word_hash.has_key?(v_word)
          word_count += v_word_hash[v_word]
        end
      end
   
      #puts "Word #{v_word} count in class #{p_class} is equal to #{v_num} and in all categories it is equal to #{word_count}"
      @word_probabilities[p_class][v_word] = v_num.to_f / word_count.to_f
    end
    
    #@class_probabilities[p_class] = 1
    @class_probabilities[p_class] = words_in_class /@sum_of_words.to_f 

    #puts "#{@class_probabilities[p_class]} x #{@word_probabilities[p_class]}" 
  end

end
