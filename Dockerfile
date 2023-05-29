FROM ruby:3.1-alpine AS builder
RUN apk add --update-cache git leptonica build-base
WORKDIR /usr/src/app
COPY Gemfile Gemfile.lock ./
RUN bundle install --path vendor

FROM ruby:3.1-alpine AS deployment
RUN apk add --no-cache leptonica tiff-tools ocrmypdf tesseract-ocr-data-pol py3-pip
RUN pip3 install --upgrade pytest-metadata pluggy
COPY --from=builder /usr/src/app /usr/src/app
WORKDIR /usr/src/app
RUN bundle config set --local path vendor

COPY *.r* ./
COPY CHECKS ./
EXPOSE 5000
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "--port", "5000"]


