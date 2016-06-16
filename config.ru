#\ -p 9294

require 'bundler'
Bundler.require
require './combine'
require './app'

run App.new

