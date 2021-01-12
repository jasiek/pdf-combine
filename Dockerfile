FROM ruby:2.7-alpine
RUN apk add --update-cache git leptonica build-base tiff-tools ocrmypdf tesseract-ocr-data-pol
RUN bundle config --global frozen 1
WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY *.r* ./
COPY CHECKS ./
EXPOSE 5000
CMD ["rackup", "--host", "0.0.0.0", "--port", "5000"]


