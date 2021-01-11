require 'bundler'
Bundler.require(:development)
require './combine'
require 'test-unit'
require 'tempfile'

class CombineTest < Test::Unit::TestCase
  def setup
    @tempfile = Tempfile.new
    @tempfile.close
    @combine = Combine.new
  end

  def files(format)
    Dir["test_data/x*.#{format}"]
  end

  def test_single_jpeg
    @combine.process(sources: files('jpeg').take(1), destination: @tempfile.path)
    assert File.exists?(@tempfile.path)
  end

  def test_many_jpeg
    @combine.process(sources: files('jpeg'), destination: @tempfile.path)
  end

  def test_single_tiff
    @combine.process(sources: files('tif').take(1), destination: @tempfile.path)
  end

  def test_many_tiff
    @combine.process(sources: files('tif'), destination: @tempfile.path)
  end

  def test_multipage_tiff
    @combine.process(sources: ['test_data/multi.tif'], destination: @tempfile.path)
  end
end
