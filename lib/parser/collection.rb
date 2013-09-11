require 'nokogiri'
require 'json'

module Parser
  class Collection
    def initialize data
      @page = Nokogiri::HTML data
    end

    def get_tracks
      @page.css('.collection-item-container').map do |node|
        track = node.attribute_nodes.select { |n| n.name == 'data-item-json' }.first
        JSON.parse track.value
      end
    end

    def parse
      @tracks = get_tracks
    end
  end
end

