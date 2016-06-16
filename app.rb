require './combine'

class App < Sinatra::Base
  get '/' do
    <<EOF
<html>
<body>
<form action="/api/process" method="post" enctype="multipart/form-data">
<input type="file" name="file[]" multiple>
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
    Combine.new.process(sources: input_files, destination: tempfile.path)
    send_file tempfile.path, type: :pdf, filename: Time.now.strftime("%Y%m%d-%H%M%S-%L.pdf")
  end
end
