require 'spec_helper'

describe ProtrackerModule do
  before do
    File.open(File.join(Rails.root,'spec','fixtures','hbt.chip-munch.mod'), 'rb') do |f|
      @module = ProtrackerModule.read(f)
    end
  end


  describe "metadata" do
    it "should load module name" do
      @module.name.should == 'hbt.chip-munch'     
    end
    it "should load magick cookie" do
       @module.cookie.should == 'M.K.'
    end
  end

  describe "pattern data" do
    it "should load ALL THE PATTERNS" do
      @module.patterns.length.should == 40
    end
    it "should load the notes correctly" do
      @module.patterns[0].rows[0].notes[0].period.should == 428
    end
    it "should load the commands correctly" do
      @module.patterns[0].rows[0].notes[0].command.should == 12
      @module.patterns[0].rows[0].notes[0].command_params.should == 32
    end
  end

  describe "sample data" do
    it "should load the samples correctly" do
      @module.sample_data[0].length.should == 1682
    end
  end

end
