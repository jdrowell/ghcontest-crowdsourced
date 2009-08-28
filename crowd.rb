#!/usr/bin/ruby -rubygems

require 'nokogiri'
require 'open-uri'
require 'ruby-debug'

class Crowdsource
  def initialize
    load_leaderboard
    parse_leaders
    #fetch_results
    crunchit
  end

  def load_leaderboard
    html = File.open('leaderboard.html').read
    @doc = Nokogiri::HTML(html)
  end

  def parse_leaders
    @leaders = []
    @doc.css('.leaderboard tr')[1..-1].each do |tr|
      tr = tr.css('td')
      entry = tr[0].css('a').inner_html
      correct = tr[1].inner_html
      percent = tr[2].inner_html
      link = tr[3].css('a').attr('href')
      @leaders.push [ entry, correct, percent, link ]
    end
  end

  def fetch_results
    @leaders[2..-1].each do |leader|
      print "Leader: #{leader[0]}\n"
      print "  determining last commit\n"
      #@doc = Nokogiri::HTML(open("#{leader[3]}/commits/master/results.txt"))
      @doc = Nokogiri::HTML(open("#{leader[3]}/tree/master"))
      a = @doc.css('#commit .group .machine a').first
      commit = a.attribute('href').to_s.split('/')[-1]
      url = "#{leader[3]}/raw/#{commit}/results.txt"
      print "  fetching #{url}\n"
      results = open(url).read
      File.open(filename(leader[0]), 'w+').write(results)
    end
  end

  def filename(leader)
    "results/#{leader.gsub('/', '-')}.txt"
  end

  def crunchit
    @user_repos = {}
    weight = 22
    @leaders[0..20].each do |leader|
      weight = weight - 1
      print "\n#{leader[0]}\n"
      f = File.open(filename(leader[0])).read
      f.each_line do |line|
        line = line.chomp
        user, repos = line.split(':')
        user = user.to_i
        repos = "" if repos.nil?
        repos = repos.split(',').map { |x| x.to_i }
        #print "#{leader[0]} --- #{user} : #{repos.join(',')}\n"
        print "."
        @user_repos[user] = {} unless @user_repos.has_key?(user)
        @user_repos[user][:weight] = 0 unless @user_repos[user].has_key?(:weight)
        @user_repos[user][:weight] += weight
        repos.each do |repo|
          @user_repos[user][repo] = 0 unless @user_repos[user].has_key?(repo)
          @user_repos[user][repo] += weight
        end
      end
    end
    @user_repos.delete(0)
    f = File.open('results.txt', 'w+')
    @user_repos.sort_by { |x| -x[0][:weight] }.each do |user, repo_hash|
      repo_hash.delete(:weight)
      repos = repo_hash.sort_by { |x| -x[1] }[0,10].collect { |x| x[0] }
      f.write "#{user}:#{repos.join(',')}\n"
    end
    f.close
  end
end

c = Crowdsource.new
      
      

