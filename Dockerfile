FROM ruby:2.7-alpine
RUN apk add --update-cache git leptonica build-base
RUN bundle config --global frozen 1
WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .
CMD ["rackup"]


