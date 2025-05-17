FROM ruby:3.4.4
COPY . /app
WORKDIR /app
RUN bundle config set --local deployment true; \
  bundle config set --local without 'development test'; \
  bundle install
ENV PORT=3000
ENV RACK_ENV=production
USER nobody
CMD [ "bundle", "exec", "puma"]