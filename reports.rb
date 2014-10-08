require 'sinatra/base'

require 'erb'
require 'json'
require 'rest-client'

require_relative 'repoman'
require_relative 'summary/issues'
require_relative 'summary/pull_requests'

class Reports < Sinatra::Base
  use Rack::Session::Pool, :cookie_only => false

  enable :sessions
  enable :logging
  enable :inline_templates

  CLIENT_ID = ENV['GITHUB_CLIENT_ID']
  CLIENT_SECRET = ENV['GITHUB_SECRET_ID']
  REPOSITORY = ENV['GITHUB_REPO']
  MILESTONE = "0.4.0"
  KEYWORD = "information"
  NOONE = ""

  def authenticated?
    session[:access_token]
  end

  def authenticate!
    erb :index, :locals => { :client_id => CLIENT_ID }
  end

  get '/' do
    if !authenticated?
      authenticate!
    else
      access_token = session[:access_token]
      scopes = []

      begin
        auth_result = RestClient.get('https://api.github.com/user',
                                     {:params => {:access_token => access_token},
                                      :accept => :json})
      rescue => e
        # request didn't succeed because the token was revoked so we
        # invalidate the token stored in the session and render the
        # index page so that the user can start the OAuth flow again

        session[:access_token] = nil
        return authenticate!
      end

      # the request succeeded, so we check the list of current scopes
      if auth_result.headers.include? :x_oauth_scopes
        scopes = auth_result.headers[:x_oauth_scopes].split(', ')
      end
      auth_result = JSON.parse(auth_result)
      erb :reports, :locals => auth_result
    end
  end

  get '/closeout' do
    repoman = RepoManager.new(session[:access_token])
    issues = repoman.issues(REPOSITORY, MILESTONE)

    complete_list = Array.new

    issues.each do |issue|
      complete_list.push(Summary::Issues.new(issue[:number], issue[:user][:login], issue[:url], 
                                             issue[:title]))
    end
    complete_list.sort!  

    erb :milestonetickets, :locals => { :milestone => MILESTONE, :issues => complete_list }
  end

  get '/patchcand' do
    repoman = RepoManager.new(session[:access_token])
    issues = repoman.issues(REPOSITORY, MILESTONE)

    complete_list = Array.new

    issues.each do |issue|
      labels = issue[:labels]
      labels.each do |label|
        if KEYWORD == label[:name]
          complete_list.push(Summary::Issues.new(issue[:number], issue[:user][:login], issue[:url], 
                                                 issue[:title]))
        end
      end
    end
    complete_list.sort!

    erb :patchtickets, :locals => { :issues => complete_list }
  end

  get '/testing' do
    repoman = RepoManager.new(session[:access_token])
    pull_requests = repoman.pull_requests(REPOSITORY, MILESTONE)

    open_prs = Array.new 
    taken_prs = Array.new
    pull_requests.each do |pull_request|
      creator = pull_request[:user]
      assignee = pull_request[:assignee]
      if assignee
        taken_prs.push(Summary::PullRequests.new(pull_request[:number], 
                                                 creator[:login],
                                                 pull_request[:url], 
                                                 pull_request[:title], 
                                                 assignee[:login]))
      else
        open_prs.push(Summary::PullRequests.new(pull_request[:number], 
                                                creator[:login], 
                                                pull_request[:url], 
                                                pull_request[:title], 
                                                NOONE))
      end
    end

    erb :testingtickets, :locals => { :milestone => MILESTONE, :open_prs => open_prs, :taken_prs => taken_prs }
  end

  get '/callback' do
    # get temporary GitHub code...
    session_code = request.env['rack.request.query_hash']['code']

    # ... and POST it back to GitHub
    result = RestClient.post('https://github.com/login/oauth/access_token',
                            {:client_id => CLIENT_ID,
                             :client_secret => CLIENT_SECRET,
                             :code => session_code},
                             :accept => :json)

    # extract the token and granted scopes
    session[:access_token] = JSON.parse(result)['access_token']

    redirect '/'
  end

end

