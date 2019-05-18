FROM ruby:2.6.2-alpine

RUN apk add
RUN apk add --no-cache libstdc++

RUN gem update --system
RUN gem update bundler
# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

EXPOSE 8080

COPY Gemfile Gemfile.lock ./
RUN apk --update add --virtual build-dependencies g++ musl-dev make \
    && bundle install \
    && apk del build-dependencies

COPY config.ru thin.yml ./

ARG TAG_NAME
RUN echo $TAG_NAME > ./TAGNAME

CMD ["bundle", "exec", "thin", "start", "-C", "thin.yml"]
