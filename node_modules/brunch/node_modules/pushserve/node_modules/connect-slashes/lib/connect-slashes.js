/**
 * connect-slashes
 * Trailing slash redirect middleware for Connect
 * https://github.com/avinoamr/connect-slashes
 *
 * The MIT License
 *
 * Copyright (c) 2010-2012 Roi Avinoam <avinoamr@gmail.com> and connect-slashes authors.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

// Only create RegExp objects once
var reQuery = /[\?\&]+/;
var reAbsolute = /^(\/\/+)/;

var slashes = function( append ) {
    ( append === false ) || ( append = true ); // default to append slashes mode

    return function( req, res, next ) {

        if ( "GET" == req.method ) {
            var url = req.url.split( reQuery )
              , location = url[ 0 ]
              , redirect;

            // Prevent redirect to absolute URLs (see issue #2)
            location = location.replace( reAbsolute, "/" );

            if ( append && "/" != location[ location.length - 1 ] ) {

                // append slashes
                redirect = location + "/"; 

            } else if ( !append && "/" == location[ location.length - 1 ] && "/" != location ) {

                // remove slashes
                redirect = location.slice( 0, location.length - 1 ); 

            }

            // complete the redirect url
            if ( redirect ) {
                if ( url.length > 1 ) {
                    redirect += "?" + url.slice( 1 ).join( "&" );
                }

                res.writeHead( 301, { "Location": redirect } );
                res.end();
                return;

            }

        }
        next();

    };

};

//
module.exports = slashes;
