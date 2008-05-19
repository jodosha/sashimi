$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'uri'
require 'yaml'
require 'fileutils'
require 'rubygems'
require 'activesupport'
require 'sashimi/plugin'
require 'sashimi/repositories'
require 'sashimi/version'
