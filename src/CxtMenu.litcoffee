Context menu for cytoscape
==========================

# Features
1. context sensitive menu
2. can customize menu filter
3. add dynamic menu item
4. support nested menu
5. self contained. no other dependencies

# (if you want see uml in chrome browser install https://github.com/callin2/plantUML_everywhere )

css

    require('./cytoscape-context-menus.css');


module name

    MODULE_NAME = "cyto-cxt-menu"

# Option
```uml
@startsalt
{
{T
 + Option
 ++ menuSelectHandler : [Function]
 ++ menu : [Menu]
 +++ name : [String]
 +++ viewWhen : [Boolean|String|Function] optional default true
 +++ onselect : [Function] optional
 +++ submenu : [Array<Menu>] optional
}
}
@endsalt
```

## menuSelectHandler:
- type : `(event: {menuName: string, target: element}) => void`
- 메뉴를 선택했을때 호출되는 event handler. 어떤 메뉴를 선택해도 항상 호출된다. 그래서 event에 `menuName`을 포함하고 있다.

## menu:
- type `string` | `object` | `promise<menu>` | `(cy)=>menu`
  - `string`
    - string인 경우 `menuSelectHandler`를  반드시 설정해야 한다. 그렇지 않으면 메뉴만 표시되고 메뉴를 선택해도 아무일도 일어나지 않는다.
      값이 4자리 이상 연속된 `-` 인 경우 divider를 표시한다. `object` type으로 표현할 경우 `{ name: string}` 과 동일하다
  - `object`
    - 기본적인 메뉴 데이타구조이다. `name`만 필수이고 나머지는 생략 가능하다.
    - `.name`: `string` 메뉴이름 필수항목
    - `.viewWhen`: `boolean|string|({target, cy})=>boolean`  우클릭 했을때 메뉴가 표시될지 말지 결정
      - `boolean` : true면 메뉴를 표시 false면 표시하지 않음
      - `string` : cytoscape selector 로 사용. 이벤트가 발생한 target element가 selector 표현에 해당하면 메뉴표시 아니면 표시안함.
      - `({target, cy})=>boolean` : function호출 결과가 true 이면 메뉴표시 아니면 표시안함.
    - `.onselect`: `(event)=>void` optional
      - 메뉴가 선택되었을때 onselect에 설정된 함수를 호출해 준다.
    - `.submenu` : `menu[] | promise<menu[]> | (event)=>menu[] ` optional
      - ``
  - `promise<menu>`
    - menu 를 resolve 하는 promise. ajax 호출 결과를 가지고 menu를 표시를 하는경우 유용하다.
  - `(cy)=>menu`
    - `menu`를 return 하는 함수. 동적으로 menu를 표시해야 할경우 유용하다.

# Option 기본값

    defaultOption = {
        menuSelectHandler: (evt) -> console.log 'context menu selected!',evt
        menu: {
            name: "----",
            submenu: [
                "menu #1"
                "----"
                {name: "menu #2", onselect: (evt)-> console.log evt, 'hello from menu #2'}
                {
                    name: "node", viewWhen: 'node', submenu: [
                        "node submenu #1"
                        "node submenu #2"
                    ]
                }
                {
                    name: "edge", viewWhen: ((evt)-> evt.target.isEdge?() ), submenu: -> [
                        "edge submenu #1"
                        "edge submenu #2"
                    ]
                }
            ]
        }
    }

utility functions from http://youmightnotneedjquery.com/

    removeDomElem = (el) -> el.parentNode.removeChild(el)
    hasClass = (el, clsName) -> el.classList.contains(clsName)
    toggleClass = (el, clsName) -> el.classList.toggle(clsName)
    addClass = (el, clsName) -> el.classList.add clsName
    removeClass = (el, clsName) -> el.classList.remove(clsName)
    show = (el) -> el.style.display = ''
    hide = (el) -> el.style.display = 'none'
    parents = (el, selector) -> if el.parentNode?.matches(selector) then el.parentNode else parents(el.parentNode, selector)
    offset = (el) ->
        rect = el.getBoundingClientRect();
        {
            top: rect.top + document.body.scrollTop,
            left: rect.left + document.body.scrollLeft
        }

    isPromise = (obj)->!!obj && (typeof obj == 'object' || typeof obj == 'function') && typeof obj.then == 'function'

for UMD. borrowed from https://gist.github.com/bcherny/6567138

    UMD = (fn) ->
        if typeof exports is 'object'
            module.exports = fn
        else if typeof define is 'function' and define.amd
            define(MODULE_NAME, -> fn)
        else
            @[MODULE_NAME] = fn(cytoscape ? null)

cytoscape에 익스텐션을 등록하는데 사용되는 함수

    register =  (cytoscape)->
        return if not cytoscape

        cytoscape 'core', "cxtMenu", (options = null) ->
            cy = @
            if options
                cy.scratch(MODULE_NAME)?.destroy?()
                cy.scratch(MODULE_NAME, new CxtMenu(cy, options))
            return cy.scratch(MODULE_NAME)

레지스터 함수를 UMD 모듈로 등록

    UMD register

context menu class

    class CxtMenu

        constructor: (@cy, options) ->
            @options = Object.assign({}, defaultOption, options)
            @options.menuTemplate ?= @_mkMenuContent
            #console.log("@cy.container().parentNode", @cy.container().parentNode)

            @cxtMenuRootElem = document.createElement('div')
            document.body.appendChild(@cxtMenuRootElem)
            addClass @cxtMenuRootElem , 'menu'
            addClass @cxtMenuRootElem , 'root'
            @initEventHandler()

        destroy: ->
            @cy = null
            @options = null
            removeDomElem @cxtMenuRootElem
            @cxtMenuRootElem = null

메뉴 하나를 초기화 하는 함수. 서브 메뉴를 포함하는 경우 서브 메뉴의 개개 항목에 대해 이 함수를 재귀적으로 호출한다.
menu 정보를 바탕으로 dom 을 만들고 parentElem 에 추가 한다.

- `parentElem` [DomElement]
- `menu` [Menu]
- `menuDepth` [Number] default 1
- `noNeedNewElem` [Boolean]

        initMenu: (parentElem, menu, menuDepth = 1, noNeedNewElem = false) ->
            if noNeedNewElem
                _rootEl = parentElem
            else
                _rootEl = document.createElement('div')
                addClass(_rootEl, "menu")
                parentElem.appendChild _rootEl

            console.log('_rootEl', _rootEl)

            #-------------------------------------------------------------

            menu = {name:menu, viewWhen:true} if typeof menu == 'string'

            if typeof menu == 'function'
                @initMenu(_rootEl, menu(@cy), menuDepth, true)
            else if isPromise(menu)
                menu
                    .then (mnu)=> @initMenu(_rootEl, mnu, menuDepth, true)
                    .catch (err)-> console.error "error in  menu info!", err
            else if menu instanceof Object
                viewWhen = @_checkViewWhen(menu)
                return removeDomElem(_rootEl) if not viewWhen

                _rootEl.innerHTML = @options.menuTemplate.call(@, menu)
                addClass(_rootEl, "depth_" + menuDepth)

                _rootEl.__menu = menu

                if menu.submenu
                    addClass(_rootEl, "menugroup")
                    addClass(_rootEl, "fold")

                    if isPromise(menu.submenu)
                        menu.submenu
                            .then (mlist)=> @initMenu(_rootEl, m, menuDepth + 1) for m in mlist
                            .catch (err)-> console.error "error in  menu info!", err
                    else if typeof menu.submenu == 'function'
                        @initMenu(_rootEl, m, menuDepth + 1) for m in menu.submenu(@cy)
                    else if menu.submenu instanceof Array
                        @initMenu(_rootEl, m, menuDepth + 1) for m in menu.submenu
                    else
                        console.error('unsupported submenu type', menu.submenu)

            return _rootEl

        initEventHandler: ->
            @cy.on('cxttap',    @_cxtTapHandler.bind(@))
            @cy.on('tapstart',  @_hideCxtMenu.bind(@))
            @cxtMenuRootElem.addEventListener('click', => @_menuSelectHandler(window.event))

        _checkViewWhen: (menu) ->
            return true if menu.viewWhen == undefined
            return menu.viewWhen if typeof menu.viewWhen == 'boolean'

            if typeof menu.viewWhen == 'function'
                return menu.viewWhen @cy.scratch('cxtEvent')
            else if typeof menu.viewWhen == 'string'
                evt = @cy.scratch('cxtEvent')
                return (evt.cy == evt.target) if menu.viewWhen == 'core'
                return evt.target.filter(menu.viewWhen).size() == 1
            else
                console.error '.viewWhen type error', menu.viewWhen

        _hideCxtMenu: ->
            hide @cxtMenuRootElem
            removeDomElem(@_tmp_menu_root) if @_tmp_menu_root
            @_tmp_menu_root = null

        _cxtTapHandler: (event) ->
            console.log event
            @cy.scratch('cxtEvent', event)

            removeDomElem(@_tmp_menu_root) if @_tmp_menu_root
            @_tmp_menu_root = @initMenu(@cxtMenuRootElem, @options.menu)
            removeClass(@_tmp_menu_root, 'fold')

            containerPos = offset @cy.container()
            renderedPos = event.renderedPosition

            left = containerPos.left + renderedPos.x
            top = containerPos.top + renderedPos.y

            @cxtMenuRootElem.style.left = left + 'px'
            @cxtMenuRootElem.style.top = top + 'px'

            show @cxtMenuRootElem

        _menuSelectHandler: (event)->
            if hasClass(event.target, 'groupname')
                toggleClass(event.target.parentElement,  'fold')
            else if hasClass(event.target, 'item')
                @options.menuSelectHandler({
                    menuName: event.target.textContent
                    target: @cy.scratch('cxtEvent').target
                })

                menuItemParent = parents(event.target, '.menu')
                menuItemParent.__menu.onselect?({
                    menuName: event.target.textContent
                    target: @cy.scratch('cxtEvent').target
                })

                hide @cxtMenuRootElem

`menuInfo`를 가지고 html string 만드든 template 함수

        _mkMenuContent: (menuInfo) ->
            if menuInfo.name.startsWith('----')
                "<div class='divider'></div>"
            else
                "<button class='item #{if menuInfo.submenu then 'groupname' else ''}'>#{menuInfo.name}</button>"
