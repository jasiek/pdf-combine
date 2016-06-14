require 'bundler'
Bundler.require

require 'tempfile'


class Combine
  FORMAT = Leptonica::FILE_FORMAT_MAPPING[:tiff_rle]
  
  def process(sources:, destination:)
    tempfile = Tempfile.new
    tempfile.close
    
    convert_to_multipage_tiff(sources, tempfile.path)
    convert_to_pdf(tempfile.path, destination)
  ensure
    tempfile.unlink
  end

  def convert_to_multipage_tiff(sources, destination)
    binarized_tiffs = sources.map do |source_filename|
      input = Leptonica::Pix.read(source_filename)
      output = Leptonica::Pix.new(LeptonicaFFI.pixConvertRGBToGray(input.pointer, 0, 0, 0))
      output = Leptonica::Pix.new(LeptonicaFFI.pixContrastNorm(nil, output.pointer, 100, 100, 55, 1, 1))
      LeptonicaFFI.pixSauvolaBinarizeTiled(output.pointer, 8, 0.34, 1, 1, nil, pix_ptr = FFI::MemoryPointer.new(:pointer))
      pix_ptr
    end
    binarized_tiffs.each_with_index do |pix, index|
      LeptonicaFFI::pixWriteTiff(destination, pix.get_pointer(0), FORMAT, index == 0 ? "w" : "a")
    end
  end

  def convert_to_pdf(source, destination)
    Process.wait(Process.spawn({}, "tiff2pdf -o #{destination} #{source}"))
  end
end

if __FILE__ == $0
  sources = ARGV.take(ARGV.size - 1)
  destination = ARGV.last

  if sources.empty? || destination.nil?
    puts "usage: combine.rb image1.jpg image2.jpg image3.jpg ... outputfile.pdf"
    exit 1
  end
  
  retval = Combine.new.process(sources: sources, destination: destination)
  exit retval
end
