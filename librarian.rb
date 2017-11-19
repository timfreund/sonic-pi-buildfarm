#!/usr/bin/env ruby

require 'open-uri'
require 'optparse'
require 'yaml'

IMAGE_DIRECTORY = File.dirname(__FILE__) + "/cloud-images/"

class Downloader
  def download
    if not Dir.exist?(IMAGE_DIRECTORY)
      Dir.mkdir(IMAGE_DIRECTORY)
    end

    download_location = IMAGE_DIRECTORY + image_file_name
    if File.exist?(download_location)
      puts download_location + " already exists; delete it to get a fresh copy"
    else
      # data = open(image_url)
      # IO.copy_stream(data, image_file_name)
      # using curl for better user feedback during potentially long downloads
      system "curl -o " + download_location + " " + image_url
    end
  end
end

class FedoraDownloader < Downloader
  def initialize(version)
    @version = version
  end
  
  def image_url
    # TODO 1.6 and similar versions... 
    base_url + base_url + "Fedora-Cloud-Base-" + 27 + "-1.6.x86_64.qcow2"
  end
  
  def base_url
    "https://download.fedoraproject.org/pub/fedora/linux/releases/" + 27 + "/CloudImages/x86_64/images/"
  end
end

class UbuntuDownloader < Downloader
  def initialize(version)
    @version = version
  end

  def base_url
    "https://cloud-images.ubuntu.com/" + @version + "/current/"
  end

  def hash_url
    base_url + "SHA256SUMS"
  end

  def image_file_name
    @version + "-server-cloudimg-amd64.img"
  end 
  
  def image_url
    base_url + image_file_name
  end
end


options = {}

opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: librarian.rb COMMAND [OPTIONS]"
  opt.separator "  Commands"
  opt.separator "    download: download the latest image for a given named image"
  opt.separator "    list: list all known image (from images.yml)"
  opt.separator ""
  opt.separator "Options"
  
  opt.on("-n", "--name [NAME]", "Image name to act on") do |name|
    if options[:names].nil?
      options[:names] = []
    end
    options[:names].push(name)
  end
end.parse!

image_metadata = YAML.load(File.read(File.dirname(__FILE__) + "/image_library.yml"))

case ARGV[0]
when "list"
  for image in image_metadata["images"]
    puts image["name"]
  end
when "download"
  for name in options[:names]
    found = false
    for image in image_metadata["images"]
      if image["name"] == name
        found = true
        UbuntuDownloader.new(image["version"]).download
      end
    end
    if not found
      puts name + " not found in the image library"
    end
  end
else
  puts "Unknown command"
  puts opt_parser
end
