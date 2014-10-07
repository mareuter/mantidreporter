require_relative 'issues'

module Summary
  class PullRequests < Issues
    include Comparable

    attr_reader :assignee

    def initialize(number, creator, url, title, assignee)
      super(number, creator, url, title)
      @assignee = assignee
    end

    def print
      puts @assignee, @number, @creator, @url, @title
    end

    def <=>(other)
      self.assignee <=> other.assignee and self.number <=> other.number
    end
  end
end

