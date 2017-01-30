FROM jruby

ENV SERVICE /service
RUN mkdir $SERVICE
WORKDIR $SERVICE

ADD . $SERVICE
RUN bundle install --without=development

EXPOSE 80

CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0", "-p", "80"]
