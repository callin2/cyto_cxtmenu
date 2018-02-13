# cyto_cxtmenu

Context menu for cytoscape.js

- nested menu support.
- no jquery dependency.
- dynamic menu item.
  - `submenu` option can be function or Promise type.
- dynamic menu filter
  - `viewWhen` option also function or Promise type possible.


# Example
```js
import * as cytoscape from 'cytoscape';
const cxtmenu = require('cyto_cxtmenu')

var cy = cytoscape(...)

cy.cxtMenu({
    menuSelectHandler: (evt) => console.log( 'context menu selected!',evt)
        menu: {
            name: "----",
            submenu: [
                "menu #1",
                "----",
                {name: "menu #2", onselect: (evt)=> console.log evt, 'hello from menu #2'},
                {
                    name: "node", viewWhen: 'node', submenu: [
                        "node submenu #1",
                        "node submenu #2"
                    ]
                },
                {
                    name: "edge", viewWhen: ((evt)=> evt.target.isEdge() ), submenu: ()=> [
                        "edge submenu #1",
                        "edge submenu #2"
                    ]
                }
            ]
        }
})
```



#### LICENSE

This software is licensed under the MIT License.

Copyright 임창진, 2018.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.
