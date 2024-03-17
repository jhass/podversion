require "bundler/setup"
Bundler.require :default

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require "podversion/app"

run Podversion::App
