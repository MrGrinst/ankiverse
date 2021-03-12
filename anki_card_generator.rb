FILLER_WORDS = %w[a and or an the of as at in to on by like br it with did].freeze

class AnkiCardGenerator
  attr_accessor :poem, :deck, :options

  def initialize(poem, deck)
    @poem = poem.to_s
    @deck = deck
  end

  def lines
    @lines ||= begin
      poem.strip.split(/\r?\n/).map do |line|
        line.strip
      end
    end
  end

  def generate_prompt(index)
    lines[[0, index - prompt_line_count + 1].max..index].join(" <br/> ") +   # 4 prev lines
      "<br/>" +
      (options[:ellipsis] == false ? "" : "...")
  end

  def generate_overview_card
    [
      lines[0] + " (Full)",
      lines[1..-1].join(" <br/> "),
      "Basic",
      nil,
      deck,
      "overview"
    ]
  end

  def generate_reverse_card
    [
      lines[1..-1].join(" <br/> "),
      lines[0],
      "Basic",
      nil,
      deck
    ]
  end

  def generate_basic_card(index)
    [
      generate_prompt(index),
      lines[index + 1, answer_line_count].join(" <br/> "),
      "Basic",
      nil,
      deck
    ]
  end

  def generate_cloze_card(index)
    text = lines[index + 1, answer_line_count].join(" <br/> ")
    parsed_words = text.split(" ").map do |word|
      without_punctuation = word.gsub(/\W/, "")
      {
        can_be_replaced: FILLER_WORDS.none? { |f| word.downcase.match?(/^([\W\-]+)?#{f}([\W\-]+)?$/) },
        without_punctuation: without_punctuation,
        with_punctuation: word.sub(without_punctuation, "{}")
      }
    end
    can_replace = parsed_words.select { |w| w[:can_be_replaced] }
    to_replace = [((can_replace.length - 1) / 2).ceil, 1].max
    can_replace.sample(to_replace).each do |word|
      word[:without_punctuation] = "{{c1::#{word[:without_punctuation]}}}"
    end
    back = parsed_words.map do |word|
      word[:with_punctuation].sub("{}", word[:without_punctuation])
    end.join(" ")
    [
      generate_prompt(index) + "<br/>" + back,
      nil,
      "Cloze",
      nil,
      deck
    ]
  end

  def generate_type_card(index)
    back_text = lines[index + 1, answer_line_count].join(" <br/> ")
    back_type = lines[index + 1, answer_line_count].map do |line|
      line.split(" ").map do |word|
        word.gsub(/[\W\-]+/, "").downcase[0]
      end.join("")
    end.join("")
    [
      generate_prompt(index),
      back_type,
      "Basic (type in the answer)",
      back_text,
      deck
    ]
  end

  def rows_only(options = {})
    @options = options
    basic_cards = []
    cloze_cards = []
    type_cards = []
    (lines.size - answer_line_count).times do |i|
      basic_cards << generate_basic_card(i)
      cloze_cards << generate_cloze_card(i)
      type_cards << generate_type_card(i)
    end
    all = []
    all.concat(cloze_cards.shift(3))
    basic_cards.length.times do |i|
      all.concat(cloze_cards.shift(1))
      all.concat(basic_cards.shift(1))
      all.concat(type_cards.shift(1))
    end
    all.concat(type_cards.shift(3))
    all.concat([generate_overview_card, generate_reverse_card])
    all
  end

  def csv(options = {})
    CSV.generate do |csv|
      rows_only(options).each { |a| csv << a }
    end
  end

  private

  def prompt_line_count
    @prompt_line_count ||= begin
      pl = options[:lines][0]
      unless (1..20).include?(pl)
        raise ArgumentError, "the numbers of lines need to be numbers"
      end
      if lines.length - pl < 2
        pl = lines.length - 1
      end
      pl
    end
  end

  def answer_line_count
    @answer_line_count ||= begin
      al = options[:lines][1]
      unless (1..20).include?(al)
        raise ArgumentError, "the numbers of lines need to be numbers"
      end
      if lines.length - al < 2
        al = 1
      end
      al
    end
  end
end
