require './combine'

class App < Sinatra::Base
  get '/robots.txt' do
    <<EOF
User-Agent: *
Disallow: /
EOF
  end
  
  get '/' do
    <<EOF
<html>
<body>
<h1>PDF Optimizer</h1>
<form action="/api/process" method="post" enctype="multipart/form-data">
<input type="file" name="file[]" multiple>
<input type="checkbox" name="ocr" id="ocr" value="yes">
<label for="ocr">OCR?</label>
<input type="submit">
</form>
</body>
</html>
EOF
  end

  post '/api/process' do
    # Looks like tempfiles are automatically removed by the GC via a finalizer.
    tempfile = Tempfile.new("pdf-combine")
    input_files = params[:file].sort_by do |f|
      f[:filename]
    end.map do |f|
      f[:tempfile].path
    end
    Combine.new.process(sources: input_files, destination: tempfile.path, ocr: params[:ocr])
    send_file tempfile.path, type: :pdf, filename: Time.now.strftime("%Y%m%d-%H%M%S-%L.pdf")
  end
end
