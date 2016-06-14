require 'pp'
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

  before do
    @tempfile = Tempfile.new
  end
  
  post '/api/process' do
    input_files = params[:file].sort_by do |f|
      f[:filename]
    end.map do |f|
      f[:tempfile].path
    end
    Combine.new.process(sources: input_files, destination: @tempfile.path)
    send_file @tempfile.path, type: :pdf
  end

  #TODO: Cleanup of tempfiles
end
