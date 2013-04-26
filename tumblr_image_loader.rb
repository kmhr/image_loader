#!/usr/bin/env ruby
#-*- coding: utf-8 -*-

require 'rubygems'
require 'tumblr_client'
require 'pstore'
require 'yaml'
require 'yaml/store'
require 'fileUtils'
require 'open-uri'
require 'date'
require 'pp'


class TumblrImageLoader
  DASHBOARD_LIMIT = 50
  MAX_OFFSET_NUM = 10000
  READ_TIMEOUT = 10
  FILENAME_CACHE_SIZE = 5000
  FILENAME_CACHE_FILE = '/var/tmp/_til_fname.cache'

  attr_accessor :conf

  #
  # Configuration
  #
  #   load configuration file
  #
  class Conf
    IMAGE_DIR = '/var/tmp/.til'
    CONF_PATH = File.join(ENV['HOME'], '.til/config.yml')

    attr_accessor :data

    def initialize
      @conf_data = {
        'til' => {
          'consumer_key' => '',
          'consumer_secret' => '',
          'oauth_token' => '',
          'oauth_token_secret' => '',
          'image_dir' => IMAGE_DIR,
          'post_id' => '0',
          'dashboard_limit' => DASHBOARD_LIMIT,
          'max_offset_num' => MAX_OFFSET_NUM,
          'read_timeout' => READ_TIMEOUT,
          'filename_cache_size' => FILENAME_CACHE_SIZE,
          'filename_cache_file' => FILENAME_CACHE_FILE,
        }
      }
      @conf_path = CONF_PATH

      if File.exist?(@conf_path)
        load
      else
        dir = File.dirname(@conf_path)
        unless File.directory?(dir)
          FileUtils.mkdir_p(dir)
        end
        save
      end

      @data = @conf_data['til']
    end

    #
    # load config file
    #
    #   config file
    #   ------------------------------
    #   #
    #   til:
    #      consumer_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    #      consumer_secret: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    #      oauth_token: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    #      oauth_token_secret: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    #      image_dir: /hoge/fuga
    #      post_id: 0
    #      dashboard_limit: 50
    #      max_offset_num: 10000
    #      read_timeout: 10
    #      filename_cache_size: 5000
    #      filename_cache_file: /var/tmp/_til_fname.cache
    #   ------------------------------
    #
    #   see -> https://github.com/tumblr/tumblr_client
    #
    def load
      if File.exist?(@conf_path)
        db = YAML::Store.new(@conf_path)
        db.transaction do
          db['til'].each do |k, v|
            @conf_data['til'][k] = v
          end
        end
      end
    end

    #
    # save config file
    #
    def save
      db = YAML::Store.new(@conf_path)
      db.transaction do
        db['til'] = @conf_data['til']
      end
    end
  end

  #
  # initialize
  #
  def initialize(opt = {})
    @conf = Conf.new

    Tumblr.configure do |config|
      Tumblr::Config::VALID_OPTIONS_KEYS.each do |key|
        config.send(:"#{key}=", @conf.data[key.to_s])
      end
    end
    @tc = Tumblr::Client.new

    @filename_cache = []
    if File.exist?(@conf.data['filename_cache_file'])
      db = YAML::Store.new(@conf.data['filename_cache_file'])
      db.transaction do
        @filename_cache = db['root']
      end
    end
  end

  #
  # check file name
  #
  def samefile?(url)
    if @filename_cache.include?(File.basename(url))
      puts "> skip #{url}"
      return true
    end
    false
  end

  #
  # download image file
  #
  def download(url)
    result = true
    begin
      file_path = "#{@conf.data['image_dir']}/#{Time.now.strftime('%Y%m%d')}/#{File.basename(url)}"
      unless File.directory?(File.dirname(file_path))
        FileUtils.mkdir_p(File.dirname(file_path))
      end
      open(url, :read_timeout => @conf.data['read_timeout']) do |f|
        File.open(file_path, "wb") do |file|
          file.puts f.read
        end
      end
      puts "> #{file_path}"
      @filename_cache.push(File.basename(url))
    rescue Exception => e
      puts ">> #{e}"
      result = false
    end
    result
  end

  #
  # run
  #
  def run
    start_tm = Time.now
    first_id = nil
    offset = 0
    dounload_count = 0
    loop_enable = true

    while loop_enable do
      dashboard = @tc.dashboard({:limit => @conf.data['dashboard_limit'], :offset => offset})
      break if dashboard.nil? || dashboard['posts'].nil? || dashboard['posts'].size == 0
      offset += dashboard['posts'].size

      if offset > @conf.data['max_offset_num'].to_i
        break
      end

      dashboard['posts'].each do |data|
        name = data['blog_name']
        id = data['id']
        first_id = id if first_id.nil?
        if id.to_i <= @conf.data['post_id'].to_i
          loop_enable = false
          break
        end

        if data['photos']
          data['photos'].each do |photo|
            width = photo['original_size']['width']
            height = photo['original_size']['height']
            url = photo['original_size']['url']
            unless samefile?(url)
              if download(url)
                dounload_count += 1
              end
            end
          end
        end
      end

      break if dashboard['posts'].size < @conf.data['dashboard_limit']
    end

    unless first_id.nil?
      @conf.data['post_id'] = first_id
      @conf.save
    end

    msg = "> id:#{first_id} saved"
    if  dounload_count > 0
      msg += ", #{dounload_count} files downloaded"
    end
    msg += ", exec: #{Time.now - start_tm} [sec]"
    puts msg

    @filename_cache.uniq!
    n = @filename_cache.size - @conf.data['filename_cache_size'].to_i
    if n > 0
      (0 ... n).each do
        @filename_cache.shift
      end
    end
    db = YAML::Store.new(@conf.data['filename_cache_file'])
    db.transaction do
      db['root'] = @filename_cache
    end
  end
end

if __FILE__ == $0
  loader = TumblrImageLoader.new
  loader.run
end
