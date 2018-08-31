#!/usr/bin/env ruby

require 'open-uri'
require 'optparse'
require 'yaml'

IMAGE_DIRECTORY = File.dirname(__FILE__) + "/cloud-images/"

class Image
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

  def image_url
    base_url + image_file_name
  end
end

# class FedoraImage < Image
#   def initialize(version)
#     @version = version
#   end

#   def image_url
#     # TODO 1.6 and similar versions...
#     base_url + base_url + "Fedora-Cloud-Base-" + 27 + "-1.6.x86_64.qcow2"
#   end

#   def base_url
#     "https://download.fedoraproject.org/pub/fedora/linux/releases/" + 27 + "/CloudImages/x86_64/images/"
#   end
# end

class UbuntuImage < Image
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
    # TODO: once xenial isn't supported this special case can go away.
    # ... or we could store more metadata in the yml file...
    if @version == "xenial"
      return @version + "-server-cloudimg-amd64-disk1.img"
    end
    @version + "-server-cloudimg-amd64.img"
  end
end


options = {}

opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: librarian.rb COMMAND [OPTIONS]"
  opt.separator "  Commands"
  opt.separator "    download: download the latest image for a given named image"
  opt.separator "    download-all: download all images"
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

image_metadata = YAML.load(File.read(File.dirname(__FILE__) + "/cloud-image-library.yml"))

case ARGV[0]
when "list"
  for image in image_metadata["images"]
    puts image["name"]
    i = UbuntuImage.new(image["version"])
    if File.exists?(IMAGE_DIRECTORY + i.image_file_name)
      puts "\t present"
    else
      puts "\t missing"
    end
  end
when "download"
  for name in options[:names]
    found = false
    for image in image_metadata["images"]
      if image["name"] == name
        found = true
        UbuntuImage.new(image["version"]).download
      end
    end
    if not found
      puts name + " not found in the image library"
    end
  end
when "download-all"
  for image in image_metadata["images"]
    UbuntuImage.new(image["version"]).download
  end
else
  puts "Unknown command"
  puts opt_parser
end
