module Summary
  class Issues < Object
    include Comparable

    attr_reader :number, :creator, :url, :title

    def initialize(number, creator, url, title)
      # Instance variables
      @number = number
      @creator = creator
      @url = url
      @title = title
    end

    def print
      puts @number, @creator, @url, @title
    end

    # Comparison operator
    def <=>(other)
      self.creator <=> other.creator and self.number <=> other.number
    end
  end
end

