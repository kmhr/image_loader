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
  MAX_LOAD_IMAGE_NUM = 500
  READ_TIMEOUT = 10
  CHECK_DAYS = 7

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
          'max_load_image_num' => MAX_LOAD_IMAGE_NUM,
          'read_timeout' => READ_TIMEOUT,
          'check_days' => CHECK_DAYS,
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
    #      max_load_image_num: 500
    #      read_timeout: 10
    #      check_days: 7
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
  end

  #
  # check file name
  #
  def samefile?(url)
    today = DateTime.now
    dir = @conf.data['image_dir']
    fname = File.basename(url)

    result = false
    (0 ... @conf.data['check_days']).each do |i|
      file_path = "#{dir}/#{(today - i).strftime('%Y%m%d')}/#{fname}"
      if File.exist?(file_path)
        result = true
        puts "> skip #{file_path}"
        break
      end
    end
    result
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
    first_id = nil
    offset = 0
    dounload_count = 0
    loop_enable = true

    while loop_enable do
      dashboard = @tc.dashboard({:limit => @conf.data['dashboard_limit'], :offset => offset})
      break if dashboard.nil? || dashboard['posts'].nil? || dashboard['posts'].size == 0
      offset += dashboard['posts'].size

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
                if dounload_count >= @conf.data['max_load_image_num']
                  loop_enable = false
                  break
                end
              end
            end
          end
        end

        break if loop_enable == false
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
    puts msg
  end
end

if __FILE__ == $0
  loader = TumblrImageLoader.new
  loader.run
end
