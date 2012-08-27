![status](https://secure.travis-ci.org/wearefractal/warlock.png?branch=master)

## Information

<table>
<tr>
<td>Package</td>
<td>warlock</td>
</tr>
<tr>
<td>Description</td>
<td>DSTM/Atomic transactions via WebSockets</td>
</tr>
<tr>
<td>Node Version</td>
<td>>= 0.6</td>
</tr>
</table>

Warlock uses ES5 features so be sure to include es5shim on your page.

## Example

### Server

```coffeescript
Warlock = require "warlock"
server = http.createServer().listen 8080
lock = Warlock.createServer server: server

lock.add
  planet:
    name: "Mars"
```

### Client

```coffeescript
lock = Warlock.createClient()

addMarsSize = lock.atomic ->
  planetName = @get "planet.name"
  if planetName is "Mars"
    @set "planet.equator.size", 3396
    @done()
  else
    #Wait until another transaction happens then try again
    @retry()

addMarsSize.run (err) ->

  # err will exist if the transaction was aborted
```

## Server Usage

### Create

```
-- Options --
resource - change to allow multiple servers on one port (default: "default")
```

```javascript
Warlock = require 'warlock'
lock = Warlock.createServer {options}
```

## Client Usage

### Create

```
-- Options --
host - server location (default: window.location.hostname)
port - server port (default: window.location.port)
secure - use SSL (default: window.location.protocol)
resource - change to allow multiple servers on one port (default: "default")
```

```javascript
lock = Warlock.createClient {options}
```

## LICENSE

(MIT License)

Copyright (c) 2012 Fractal <contact@wearefractal.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
