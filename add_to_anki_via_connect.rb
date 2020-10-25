require "httparty"

module AddToAnkiViaConnect
  def self.add(rows)
    json = {
      "action" => "addNotes",
      "version" => 6,
      "params" => {
        "notes" => rows.map do |card|
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
          }.merge(if card[5]
                   { "tags" => [card[5]] }
                  else
                    {}
                  end)
        end
      }
    }
    puts(json.to_json)
    puts(HTTParty.post("http://localhost:8765", body: { "version" => 6, "action" => "sync" }.to_json, headers: { "Content-Type" => "application/json" }))
    sleep(5)
    puts(HTTParty.post("http://localhost:8765", body: json.to_json, headers: { "Content-Type" => "application/json" }))
    puts(HTTParty.post("http://localhost:8765", body: { "version" => 6, "action" => "sync" }.to_json, headers: { "Content-Type" => "application/json" }))
  end
end
