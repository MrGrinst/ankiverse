#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'sinatra/base'
require 'yaml'
require 'csv'

require './anki_card_generator'
require './esv_api_request'
require './sentence_splitter'
require './add_to_anki_via_connect'

class AnkiVerse < Sinatra::Base

  get '/' do
    erb :index
  end

  post '/' do
    if !ENV["ANKI_PASSWORD"] || params["password"] != ENV["ANKI_PASSWORD"]
      redirect '/unauthorized'
    elsif params["put_into_anki"]
      rows = AnkiCardGenerator.new(params["poem"], params["deck"]).
               rows_only(:lines => params["lines"].map(&:to_i),
                         :ellipsis => !!params["ellipsis"])
      AddToAnkiViaConnect.add(rows)
      redirect '/'
    else
      response['Content-Type'] = "text/csv; charset=utf-8"
      response['Content-Disposition'] = "attachment; filename=ankiverse.csv"
      AnkiCardGenerator.new(params["poem"], params["deck"]).
        csv(:lines => params["lines"].map(&:to_i),
            :ellipsis => !!params["ellipsis"])
    end
  end

  get '/bible/:passage/:verse_numbers?' do
    options = {
      :key => "IP",
      :output_format => "plain-text",
      :line_length => 0,
      :dont_include => %w(
        passage-references
        first-verse-numbers
        footnotes
        footnote-links
        headings
        subheadings
        audio-link
        short-copyright
        passage-horizontal-lines
        heading-horizontal-lines
        verse_numbers
      )
    }

    response = EsvApiRequest.execute(:passageQuery,
      options.merge(:passage => params[:passage]))

    text = "#{params[:passage]}\n#{response}"

    @passage = params[:passage]
    @poem = SentenceSplitter.new(text).lines_of(5..12).join("\n")
    erb :index
  end

end
