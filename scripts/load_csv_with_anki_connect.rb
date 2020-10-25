require "csv"
require "../add_to_anki_via_connect"

AddToAnkiViaConnect.add(CSV.read(ARGV[0]))
