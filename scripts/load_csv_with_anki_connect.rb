require "csv"
require "httparty"
require "byebug"

cards = CSV.read(ARGV[0])

json = {
  "action" => "addNotes",
  "version" => 6,
  "params" => {
    "notes" => cards.map do |card|
      front = card[0]
      back = card[1]
      type = card[2]
      extra = card[3]
      deckName = card[4]
      {
        "deckName" => deckName,
        "modelName" => type,
        "fields" => if type == "Cloze"
                      {
                        "Text" => front,
                        "Extra" => back || ""
                      }
                    elsif type == "Basic (type in the answer)"
                      {
                        "Front" => front,
                        "Back" => back,
                        "Extra" => extra || ""
                      }
                    else
                      {
                        "Front" => front,
                        "Back" => back
                      }
                    end,
      }
    end
  }
}
HTTParty.post("http://localhost:8765", body: json.to_json, headers: { "Content-Type" => "application/json" })
