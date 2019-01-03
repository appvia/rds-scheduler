FROM ruby:2.5.0-alpine
LABEL maintainer="info@appvia.io"
LABEL source="https://github.com/appvia/rds-scheduler"

WORKDIR /app

# Update packages in base image
RUN apk update && apk upgrade

# Copy application files into image
COPY lib Gemfile Gemfile.lock /app/

# Create a non-root user and set file permissions
RUN addgroup -S app \
    && adduser -S -g app -u 1000 app \
    && chown -R app:app /app

# Run as the non-root user
USER 1000

# Fetch dependencies
RUN bundle install --deployment --without test

# Set the run command
CMD ["ruby", "run.rb"]
