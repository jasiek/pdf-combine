require 'bundler'
Bundler.require
require 'tempfile'

class Combine
  FORMAT = Leptonica::FILE_FORMAT_MAPPING[:tiff_rle]
  TIFF_FORMATS = Leptonica::FILE_FORMAT_MAPPING[:tiff]..Leptonica::FILE_FORMAT_MAPPING[:tiff_zip]

  def initialize
    @tempfiles = []
  end
  
  def process(sources:, destination:, ocr:)
    raise TypeError unless sources.is_a?(Array)
    
    tiff = convert_to_multipage_tiff(sources)
    pdf = convert_to_pdf(tiff)
    pdf = ocr_my_pdf(pdf) if ocr
    
    FileUtils.mv(pdf, destination)
  ensure
    @tempfiles.each do |t|
      t.unlink
    end
  end

  def with_tempfile
    tempfile = Tempfile.new
    tempfile.close
    @tempfiles << tempfile
    yield destination = tempfile.path
    destination
  end

  def binarize_single(pix)
    input = Leptonica::Pix.new(LeptonicaFFI.pixConvertTo32(pix))
    output = Leptonica::Pix.new(LeptonicaFFI.pixConvertRGBToGray(input.pointer, 0, 0, 0))
    output = Leptonica::Pix.new(LeptonicaFFI.pixContrastNorm(nil, output.pointer, 100, 100, 55, 1, 1))
    LeptonicaFFI.pixSauvolaBinarizeTiled(output.pointer, 8, 0.34, 1, 1, nil, pix_ptr = FFI::MemoryPointer.new(:pointer))
    pix_ptr
  end

  def convert_to_multipage_tiff(sources)
    with_tempfile do |destination|
      # If this is a multi-page tiff, then process it differently.
      LeptonicaFFI.findFileFormat(sources.first, format = FFI::MemoryPointer.new(:int32))
      format = format.read(:int32)
      if sources.size == 1 && TIFF_FORMATS.include?(format)
        pixa = LeptonicaFFI.pixaReadMultipageTiff(sources.first)
        size = LeptonicaFFI.pixaGetCount(pixa)
        binarized_tiffs = size.times.map do |i|
          binarize_single(LeptonicaFFI.pixaGetPix(pixa, i, Leptonica::L_CLONE))
        end
      elsif sources.size == 1 && format == 16
        raise "Unsupported format"
      else
        binarized_tiffs = sources.map do |source_filename|
          raise ArgumentError unless File.exists?(source_filename)
          
          input = Leptonica::Pix.read(source_filename)
          
          next input if input.depth == 1
          binarize_single(input.pointer)
        end
      end
      binarized_tiffs.each_with_index do |pix, index|
        LeptonicaFFI::pixWriteTiff(destination, pointer(pix), FORMAT, index == 0 ? "w" : "a")
      end
    end
  end

  def pointer(pix)
    if pix.respond_to? :pointer
      pix.pointer
    else
      pix.get_pointer(0)
    end
  end

  def convert_to_pdf(source)
    with_tempfile do |destination|
      Process.wait(Process.spawn({}, "tiff2pdf -n -o #{destination} #{source}"))
    end
  end

  def ocr_my_pdf(source)
    with_tempfile do |destination|
      Process.wait(Process.spawn({}, "ocrmypdf -l eng+pol --rotate-pages --deskew --jobs 4 --output-type pdfa #{source} #{destination}"))
    end
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
