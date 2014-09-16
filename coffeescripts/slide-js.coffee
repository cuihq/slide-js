################################################################################################
#                                                                                              #
#  Slide(.sj)                                                                                  #
#                                                                                              #
#  ##########################################################################################  #
#  #                                                                                        #  #
#  #  Show(.sj-show)                                                                        #  #
#  #   - Page(.sj-page)                                                                     #  #
#  #     - Fragment(.sj-fragment)                                                           #  #
#  #                                                                                        #  #
#  ##########################################################################################  #
#  #                                                                                        #  #
#  #  Control(.sj-control)                                                                  #  #
#  #   - PreviousPage(.sj-previous-page) | PreviousFragment(.sj-previous-fragment)          #  #
#  #  | NextFragment(.sj-next-fragmet) | NextPage(.sj-next-page)                            #  #
#  #  | FullScreen(.sj-full-screen)   PageInfo(.sj-page-info)                               #  #
#  #                                                                                        #  #
#  ##########################################################################################  #
#  #                                                                                        #  #
#  #  ProgressBar(.sj-progress-bar)                                                         #  #
#  #                                                                                        #  #
#  ##########################################################################################  #
#                                                                                              #
################################################################################################
Util =
  has_class: (elem, cls) -> (' ' + elem.className+ ' ').indexOf(' ' + cls + ' ') > -1
  add_class: (elem, cls) -> elem.className += ' ' + cls unless @has_class(elem, cls)
  remove_class: (elem, cls) -> elem.className = elem.className.replace(cls, ' ').replace('  ', ' ') if @has_class(elem, cls)
  add_event: (elem, event, fn) -> if document.addEventListener then elem.addEventListener(event, fn) else elem.attachEvent('on' + event, fn) 
  full_screen: (elem = document.documentElement) ->
    if elem.requestFullscreen
      elem.requestFullscreen()
    else if elem.mozRequestFullScreen
      elem.mozRequestFullScreen()
    else if elem.webkitRequestFullscreen
      elem.webkitRequestFullscreen()
    else if elem.msRequestFullscreen
      elem.msRequestFullscreen()

class Slide
  constructor: (@config) ->
    @id = @config.id
    @cycle = @config.cycle
    @break = (@config.break || 'hr').toUpperCase()
    @height = (@config.height || 600) + 'px'
    @node = document.getElementById @id
    Util.add_class(@node, 'sj')
    @show = new Show(@)
    if @show.length isnt - 1
      @control = new Control(@)
      @progress_bar = new ProgressBar(@)
    @enable = false

  is_enable: -> @enable

  start: ->
    unless @enable
      @enable = true
      @show.start()
      @control.start()
      @progress_bar.start()
      @update_status()  

  stop: ->
    if @enable
      @enable = false
      @show.stop()
      @control.stop()
      @progress_bar.stop()

  update_status: ->
    if @enable
      @control.update_status() if @control
      @progress_bar.update_status() if @progress_bar

class Show
  constructor: (@slide) ->
    @index = -1
    @length = -1
    @children = []
    @original_children = []
    @node = document.createElement 'div'
    @node.className = 'sj-show'
    @node.style.height = @slide.height
    @node.style.display = 'none'
    for child in @slide.node.children
      page = new Page(@slide) unless page
      if child.tagName is @slide.break
        @add page
        page = new Page @slide
      else
        fragment = new Fragment @slide
        fragment.add child.cloneNode(true)
        page.add fragment
      @original_children.push child
    @add page
    @index = 0 if @length isnt 0
    _show = @
    Util.add_event(@node, 'mousedown', (event) -> _show.next_fragment())
    if @node.addEventListener
      @node.addEventListener('touchstart', (event) -> 
        _show.touchstart(event)
      , false)
      @node.addEventListener('touchend', (event) ->
        _show.touchend(event)
      , false)
    @beginX = 0
    @beginY = 0
    @endX = 0
    @endY = 0
    @slide.node.appendChild @node

  start: ->
    for child in @original_children
      child.style.display = 'none'
    @node.style.display = 'block'

  stop: ->
    @node.style.display = 'none'
    for child in @original_children
      child.style.display = ''

  touchstart: (event) ->
    if @slide.enable && Util.has_class(@slide.node, 'sj-full-screen')
      @beginX = event.touches[0].clientX
      @beginY = event.touches[0].clientY
    else
      @beginX = 0
      @beginY = 0
      @endX = 0
      @endY = 0

  touchend: (event) ->
    if @slide.enable && Util.has_class(@slide.node, 'sj-full-screen')
      @endX = event.changedTouches[0].clientX
      @endY = event.changedTouches[0].clientY
      lengthX = @endX - @beginX
      lengthY = @endY - @beginY
      if Math.abs(lengthX) > Math.abs(lengthY)
        if lengthX >= 100
          @previous_fragment()
        else if lengthX <= -100
          @next_fragment()
      else
        if lengthY >= 100
          @previous_page() 
        else if lengthY <= -100
          @next_page()
    @beginX = 0
    @beginY = 0
    @endX = 0
    @endY = 0

  add: (page) ->
    if page
      @children.push page
      @node.appendChild page.node
      @slide.index = 0
      @length = @children.length

  is_first_page: -> @index is 0

  is_last_page: -> @index is @length - 1

  is_first_fragment: -> @is_first_page() && @children[@index].is_first()

  is_last_fragment: -> @is_last_page() && @children[@index].is_end()

  next_page: ->
    if 0 <= @index < @length - 1
      if @children[@index].is_end()
        @children[@index].hide()
        @index = @index + 1
        @children[@index].show()
      else
        @children[@index].show() 
    else if @index is @length - 1 && @slide.cycle
      if @children[@index].is_end()
        @children[@index].hide()
        @index = 0
        @children[@index].show()
      else
        @children[@index].show()
    @slide.update_status()

  previous_page: ->
    if 0 < @index < @length
      @children[@index].hide()
      @index = @index - 1
      @children[@index].show()
    else if @index is 0 && @slide.cycle
      @children[@index].hide()
      @index = @length - 1
      @children[@index].show()
    @slide.update_status()

  next_fragment: ->
    if @index is @length - 1 && @children[@index].is_end()
      if @slide.cycle
        @children[@index].hide()
        @index = 0
        @children[@index].next()
    else if 0 <= @index < @length && @children[@index].is_end()
      @children[@index].hide()
      @index = @index + 1
      @children[@index].next()
    else if 0 <= @index < @length
      @children[@index].next()
    @slide.update_status()

  previous_fragment: ->
    if @index is 0 && @children[@index].is_first()
      if @slide.cycle
        @children[@index].hide()
        @index = @length - 1
        @children[@index].show()
    else if 0 <= @index < @length && @children[@index].is_first()
      @children[@index].hide()
      @index = @index - 1
      @children[@index].show()
    else if 0 <= @index < @length
      @children[@index].previous()
    @slide.update_status()

class Page
  constructor: (@slide) ->
    @node = document.createElement 'div'
    Util.add_class(@node, 'sj-page')
    @children = []
    @index = -1
    @total_count = 0

  add: (fragment) ->
    if fragment
      @children.push fragment
      @node.appendChild fragment.node
      @total_count = @children.length
      @hide()

  is_end: -> @index is @total_count - 1

  is_first: -> @index is 0 || @index is -1

  next: ->
    @node.style.display = 'block'
    index = @index + 1
    if 0 <= index < @total_count
      @children[index].show()
      @index = index

  previous: ->
    if 0 <= @index < @total_count
      @children[@index].hide()
      @index = @index - 1

  show: ->
    @node.style.display = 'block'
    @children[i].show() for i in [0..@total_count-1]
    @index = @total_count - 1

  hide: ->
    @children[i].hide() for i in [0..@total_count-1]
    @index = -1 if @total_count > 0
    @node.style.display = 'none'

class Fragment
  constructor: (@slide) ->
    @node = document.createElement 'div'
    Util.add_class(@node, 'sj-fragment')
    Util.add_class(@node, 'sj-fade') if @slide.fade
    @hide()

  add: (text) -> @node.appendChild text if text

  show: -> @node.style.display = 'block'

  hide: -> @node.style.display = 'none'

class Control
  constructor: (@slide) ->
    @node = document.createElement 'div'
    @node.className = 'sj-control'
    @node.style.display = 'none'
    @page_info = new PageInfo(@slide, @)
    @previous_page = new PreviousPage(@slide, @)
    @previous_fragment = new PreviousFragment(@slide, @)
    @next_fragment = new NextFragment(@slide, @)
    @next_page = new NextPage(@slide, @)
    @full_screen = new FullScreen(@slide, @)
    @slide.node.appendChild @node

  start: -> @node.style.display = 'block'

  stop: -> @node.style.display = 'none'

  update_status: ->
    @previous_page.update_status() if @previous_page
    @previous_fragment.update_status() if @previous_fragment
    @next_fragment.update_status() if @next_fragment
    @next_page.update_status() if @next_page
    @full_screen.update_status() if @full_screen
    @page_info.update_status() if @page_info

class Button
  constructor: (@slide, @parent) ->
    @show = @slide.show
    @node = document.createElement 'div'
    @parent.node.appendChild @node
    _button = @
    Util.add_event(@node, 'mousedown', (event) -> _button.mouse_down(_button, event)) if @mouse_down
    Util.add_event(document, 'keyup', (event) -> _button.key_up(_button, event)) if @key_up
    @init(_button) if @init

  mouse_down: (button, event) -> button.run(button, event) if @slide.enable

  key_up: (button, event) -> button.run(button, event) if @slide.enable && @keyCode && event.keyCode is @keyCode

class PreviousPage extends Button
  init: (button)->
    @node.className = 'sj-previous-page-button'
    @node.setAttribute('title', '上一页')
    @keyCode = 37

  run: (button, event) -> button.slide.show.previous_page()

  update_status: ->
    if not @slide.cycle && @slide.show.is_first_page() 
      Util.add_class(@node, 'sj-button-disable')
    else
      Util.remove_class(@node, 'sj-button-disable')

class PreviousFragment extends Button
  init: (button)->
    @node.className = 'sj-previous-fragment-button'
    @node.setAttribute('title', '上一段')
    @keyCode = 38
  
  run: (button, event) -> button.slide.show.previous_fragment()

  update_status: ->
    if not @slide.cycle && @slide.show.is_first_fragment()
      Util.add_class(@node, 'sj-button-disable')
    else
      Util.remove_class(@node, 'sj-button-disable')

class NextFragment extends Button
  init: (button)->
    @node.className = 'sj-next-fragmet-button'
    @node.setAttribute('title', '下一段')
    @keyCode = 40

  run: (button, event) -> button.slide.show.next_fragment()

  update_status: ->
    if not @slide.cycle && @slide.show.is_last_fragment()
      Util.add_class(@node, 'sj-button-disable')
    else
      Util.remove_class(@node, 'sj-button-disable')

class NextPage extends Button
  init: (button)->
    @node.className = 'sj-next-page-button'
    @node.setAttribute('title', '下一页')
    @keyCode = 39

  run: (button, event) -> button.slide.show.next_page()

  update_status: ->
    if not @slide.cycle && @slide.show.is_last_page()
      Util.add_class(@node, 'sj-button-disable')
    else
      Util.remove_class(@node, 'sj-button-disable')

class FullScreen extends Button
  init: (button)->
    @node.className = 'sj-full-screen-button'
    @node.setAttribute('title', '全屏')
    @is_full_screen = false
    for listener_name in ['fullscreenchange', 'webkitfullscreenchange', 'mozfullscreenchange']
      Util.add_event(document, listener_name, (event) ->
        if button.is_full_screen
          Util.add_class(button.slide.node, 'sj-full-screen')
        else
          Util.remove_class(button.slide.node, 'sj-full-screen')
        button.is_full_screen = false
      )
       
  run: (button, event) ->
    Util.full_screen(button.slide.node)
    @is_full_screen = true

  update_status: ->

class PageInfo
  constructor: (@slide, @parent) ->
    @node = document.createElement 'div'
    @node.className = 'sj-page-info'
    @current_page_node = document.createElement 'span'
    @current_page_node.className = 'current-page'
    @current_page_node.innerHTML = @slide.index
    @node.appendChild @current_page_node
    @delimiter_node = document.createElement 'span'
    @delimiter_node.className = 'delimiter'
    @delimiter_node.innerHTML = '/'
    @node.appendChild @delimiter_node
    @total_page_node = document.createElement 'span'
    @total_page_node.className = 'total_page'
    @total_page_node.innerHTML = @slide.show.length
    @node.appendChild @total_page_node
    @parent.node.appendChild @node

  update_status: ->
    @current_page_node.innerHTML = @slide.show.index + 1

class ProgressBar
  constructor: (@slide) ->
    @node = document.createElement 'div'
    @node.className = 'sj-progress-bar'
    @node.style.display = 'none'
    @inner_node = document.createElement 'div'
    @inner_node.className = 'sj-progress-inner'
    @node.appendChild @inner_node
    @slide.node.appendChild @node

  start: -> @node.style.display = 'block'

  stop: -> @node.style.display = 'none'

  update_status: -> @inner_node.style.width = "#{ @slide.show.index / (@slide.show.length - 1) * 100}%" if @slide.show.length isnt -1

window.Slide = Slide