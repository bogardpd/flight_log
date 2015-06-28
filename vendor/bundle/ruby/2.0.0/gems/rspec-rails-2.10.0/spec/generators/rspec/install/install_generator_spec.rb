require 'spec_helper'
require 'generators/rspec/install/install_generator'

describe Rspec::Generators::InstallGenerator do
  destination File.expand_path("../../../../../tmp", __FILE__)

  before { prepare_destination }

  it "generates .rspec" do
    run_generator
    file('.rspec').should exist
  end

  it "generates spec/spec_helper.rb" do
    run_generator
    File.read( file('spec/spec_helper.rb') ).should =~ /^require 'rspec\/autorun'$/m
  end
end
