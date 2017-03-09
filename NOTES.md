Build a docker image locally:

```
docker build -t thegamma-sql-service .
```

Start the image, expose ports and run bash. 
This also maps my local path to `/local` so that I can edit the code & restart it:

```
docker run -v c:/Tomas/Public/thegamma/thegamma-sql-service/:/local -p 127.0.0.1:8087:80 -it thegamma-sql-service bash
```

Now, inside Docker, go to my local host-machine version of the code:

```
cd ../local
```

Install packages and then extract `sqljdbc4.jar` to local directory
so that JRuby can load it (there must be a better way to do this...)

```
bundle install --without=development
cp /usr/local/bundle/gems/jdbc-mssql-azure-0.0.2/lib/sqljdbc4.jar
unzip sqljdbc4.jar
rm sqljdbc4.jar
```

Run the service!

```
bundle exec rackup -o 0.0.0.0 -p 80
```
