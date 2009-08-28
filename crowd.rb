#!/usr/bin/ruby -rubygems

require 'nokogiri'
require 'open-uri'
require 'ruby-debug'

class Crowdsource
  def initialize
    load_leaderboard
    parse_leaders
    #fetch_results
    #cleanup_leaders
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
      entry = tr[0].css('a').attr('href') #inner_html
      correct = tr[1].inner_html
      percent = tr[2].inner_html
      link = tr[3].css('a').attr('href')
      @leaders.push [ entry, correct, percent, link ]
    end
  end

  def cleanup_leaders
    #size = @leaders.size
    #print "size: #{size}\n"
    (40.downto 0).each do |i|
      f = filename(@leaders[i][0])
      lines = `wc -l #{f}`.split(' ')[0].to_i
      if lines != 4788
        print "Removing entry by #{@leaders[i][0]}\n" 
        @leaders.delete_at(i)
      end
    end
  end

  def fetch_results
    @leaders[0..40].each do |leader|
      print "Leader: #{leader[0]}\n"
      print "  determining best commit\n"
      #@doc = Nokogiri::HTML(open("#{leader[3]}/commits/master/results.txt"))
      #@doc = Nokogiri::HTML(open("#{leader[3]}/tree/master"))
      @doc = Nokogiri::HTML(open("http://contest.github.com#{leader[0]}"))
      #a = @doc.css('#commit .group .machine a').first
      #commit = a.attribute('href').to_s.split('/')[-1]
      trs = @doc.css('table')[1].css('tr')
      #debugger
      max = 0
      commit = ''
      trs.each do |tr|
        score = tr.css('td strong').inner_html.to_i
        #print "score: #{score}   "
        if score > max
          commit = tr.css('td')[4].css('a').attr('href').split('/')[-1]
          max = score
        end
      end
      raise "wtf" if commit.empty?
      url = "#{leader[3]}/raw/#{commit}/results.txt"
      print "  fetching #{url}\n"
      begin
        results = open(url).read
      #rescue
      #  print "Whatever HTTP error\n"
      #  results = ''
      end
      File.open(filename(leader[0]), 'w+').write(results)
    end
  end

  def filename(leader)
    "results/#{leader.gsub('/', '-')}.txt"
  end

  def crunchit
    @user_repos = {}
    weight = 1000.0
    @leaders[0..30].each do |leader|
      weight = weight / 1.2
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
          raise "can't be zero" if repo == 0
          @user_repos[user][repo] = 0 unless @user_repos[user].has_key?(repo)
          @user_repos[user][repo] += weight
        end
      end
    end
    #@user_repos.delete(0)
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
      
      

