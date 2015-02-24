# Script for searching developers in github and stored in LessAnoyingCMR database

require 'rubygems'
require 'httparty'
require 'json'
require 'uri'

# Search developers in github filtered by location and language
#
class GithubSearch
  @token = 'Your GitHub Outh Token'

  # Get all the users filtered by language and location in an specific page
  #
  def self.get_users(location, language, keyword, page, user_id)
    developers = []
    response = HTTParty.get(
              "https://api.github.com/search/users?q=+location:#{location}+language:#{language}&per_page=20&sort=followers&page=#{page}", 
              :headers => {
                "Authorization" => "token #{@token}",
                "User-Agent" => "juandgirald"
              })
    users = response.parsed_response['items']
    
    if users
      if !users.empty?
        users.each do |user|
          url = user['url']
          developer = get_user_information(url, language, keyword, user_id)
          stars     = developer[:popular_repos].empty? ? 0 : developer[:popular_repos].first[:stars]
          # id        = developer[:last_id]

          if stars >= 5
            developers << developer
          end

          user_id +=1
          
          # repo_id = id != 0 ? id : repo_id
          # repo_id +=1
        end
        developers
      else
        return 'The page is empty'
      end
    end
  end

  # Count the number of developers found
  # location: Country filter
  # language: Code language filter
  #
  def self.total_count_by_country(location, language)
    response = HTTParty.get(
              "https://api.github.com/search/users?q=+location:#{location}+language:#{language}&per_page=1&page=1", 
              :headers => {
                "Authorization" => "token #{@token}",
                "User-Agent" => "juandgirald"
              })
    total_count = response.parsed_response['total_count'] 
  end

  # Get the specific information of the developer
  # Url: Github url of the developer
  # Language: Code language
  #
  def self.get_user_information(url, language, keyword, user_id)
    response = HTTParty.get("#{url}",
              :headers => {
                "Authorization" => "token #{@token}",
                "User-Agent" => "juandgirald"
              })
    
    name         =  response.parsed_response['name']
    email        =  response.parsed_response['email']
    date_joined  =  response.parsed_response['created_at']
    followers    =  response.parsed_response['followers']
    location     =  response.parsed_response['location']
    public_repos =  response.parsed_response['public_repos']

    popular_repos = get_popular_repos(response.parsed_response['login'], keyword)
    if !keyword.empty?
      language = keyword
    end
    # last_id =  popular_repos.empty? ? 0 : popular_repos.last[:id]

    information = {
      id: user_id, 
      name: name, 
      email: email, 
      followers: followers, 
      date_joined: date_joined, 
      location: location, 
      public_repos: public_repos,
      popular_repos: popular_repos,
      language: language
      # last_id: last_id
    }
  end

  # Get the information for the popular repos of the developer found
  # User: Developer
  #
  def self.get_popular_repos(user, keyword)
    response = HTTParty.get(
              "https://api.github.com/search/repositories?q=#{keyword}+user:#{user}&sort=stars&order=desc&per_page=5",
              :headers => {
                "Authorization" => "token #{@token}",
                "User-Agent" => "juandgirald"
              })
    popular_repos = response.parsed_response['items']
    repos = []

    if popular_repos
      popular_repos.each do |repo|
        repos << {
          name:  repo['name'],
          url:   repo['html_url'],
          forks: repo['forks'],
          stars: repo['stargazers_count'],
          size:  repo['size'],
          language: repo['language']
        }
      end
    end
    repos
  end
end

# Save contacts to LessAnoyingCmr
#
class LessAnnoyingCrm

  def initialize
    @apitoken = "Your LessAnnoyingCrm apitoken"
    @usercode = "Your LessAnnoyingCrm usercode"
  end

  def add_contact(name, date_joined, followers, location, public_repos, email, most_popular_repos, repo_url, language)
    contact = {
      :FullName => name, 
      :CustomFields => { 
        :Date_Joined        => date_joined, 
        :Followers          => followers,
        :Location           => location,
        :Public_Repos       => public_repos,
        :Most_Popular_Repo  => most_popular_repos,
        :Repo_Url           => repo_url,
        :Language           => language
      },
      :Email => { 0 => 
        { 
          :Text => email, 
          :Type => "Work" 
        } 
      }
    }
    
    json = URI::encode(contact.to_json)
    
    HTTParty.get("https://api.lessannoyingcrm.com?UserCode=#{@usercode}&APIToken=#{@apitoken}&Function=CreateContact&Parameters=#{json}")
  end
end

# Countries where you want to search developers
#
countries = [
'Jamaica',
'Japan',
'Jordan',
'Kazakhstan',
'Kenya',
'Kiribati',
'Korea',
'Kosovo',
'Kuwait',
'Kyrgyzstan',
'Laos',
'Latvia',
'Lebanon',
'Lesotho',
'Liberia',
'Libya',
'Liechtenstein',
'Lithuania',
'Luxembourg'
]

# Iterates the countries array to provide a country attribute, 
# call the GithubSearch and LessAnnoyingCmr classes 
#
countries.each do |country|
  total_count = GithubSearch.total_count_by_country(country, 'Python') 
  pages = (total_count/20) +  1
  page = 1
  sleep 10

  api   = LessAnnoyingCrm.new()
  begin
    users = GithubSearch.get_users(country, 'Python', '', page, 1) 
    
  if users 
    if users != "The page is empty"
      users.each do |user|
        api.add_contact(user[:name], user[:date_joined], user[:followers], user[:location], user[:public_repos], 
                        user[:email], user[:popular_repos].first[:name], user[:popular_repos].first[:url], user[:language])
      end
      print users.length
    end
  end
    
    page +=1
    sleep 30
  end while page <= pages
end

