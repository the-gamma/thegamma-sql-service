# `thegamma-sql-service`

A ["REST pivot data service"](http://thegamma.net/publishing/) for [The Gamma](http://thegamma.net)

## Installation

Get [JRuby](http://jruby.org).

- `bundle`
- `JRUBY_OPTS="-G" rackup`

By default, the service connects to an example SQLite database which contains the [olympic medals dataset](https://github.com/the-gamma/thegamma-services/blob/master/data/medals-expanded.csv) used in the examples. It should also work with any database supported by [ActiveRecord JDBC](https://github.com/jruby/activerecord-jdbc-adapter).

## License

License

The MIT License (MIT)

Copyright (c) 2016 Manuel Aristarán

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
