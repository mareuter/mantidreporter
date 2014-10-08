require 'octokit'

class RepoManager < Object

  def initialize(access_token)
    @client = Octokit::Client.new(:access_token => access_token)
    @ms_number = 1
    @milestones = nil
    @repo_name = nil
  end

  def issues(repo_name, milestone_name)
    setup(repo_name, milestone_name)
    return @client.list_issues(@repo_name, :milestone => @ms_number, :state => "closed")
  end

  def pull_requests(repo_name, milestone_name)
    setup(repo_name, milestone_name)
    prs = @client.pull_requests(@repo_name, :state => "closed")
    pull_requests = []
    prs.each do |pr|
      milestone = pr[:milestone]
      # Only get those associated with current milestone
      if nil != milestone && milestone_name == milestone[:title]
        pull_requests.push(pr)
      end
    end
    return pull_requests
  end

  def user_fullname(login)
    response = @client.user(login)
    return response[:name]
  end

  private
    def setup(repo_name, milestone_name)
      if repo_name != @repo_name
        @repo_name = repo_name
        # Get all milestones
        @milestones = @client.list_milestones(@repo_name)
        @milestones.concat(@client.list_milestones(@repo_name, :state => "closed"))

      end
      find_ms_number(milestone_name)
    end

    def find_ms_number(milestone_name)
      @milestones.each do |milestone|
        if milestone_name == milestone[:title]
          @ms_number = milestone[:number]
          break
        end
      end
    end

end
