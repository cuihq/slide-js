################################################################################################
#                                                                                              #
#  Slide                                                                                       #
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
  addClass: (elem, className) -> elem.className += ' ' + className
  removeClass: (elem, className) -> elem.className = elem.className.replace(className, ' ').replace('  ', ' ')
  addEvent: (elem, event, fn) -> if document.addEventListener then elem.addEventListener(event, fn) else elem.attachEvent('on' + event, fn)

class Slide
  constructor: (@config) ->
    @id = @config.id
    @cycle = @config.cycle || true
    @break = (@config.break || 'hr').toUpperCase()
    @node = document.getElementById @id
    @show = new Show(@)
    @control = new Control(@)
    @progress_bar = new ProgressBar(@)

  update_status: ->
    @control.update_status() if @control
    @progress_bar.update_status() if @progress_bar

class Show
  constructor: (@slide) ->
    @index = -1
    @length = -1
    @children = []
    @node = document.createElement 'div'
    @node.className = 'sj-show'
    for child in @slide.node.children
      page = new Page unless page
      if child.tagName is @slide.break
        @add page
        page = new Page
      else
        fragment = new Fragment page
        fragment.add child.cloneNode(true)
        page.add fragment
      child.style.display = 'none'
    @add page
    @slide.node.appendChild @node
    @index = 0 if @length isnt 0

  add: (page) ->
    if page
      @children.push page
      @node.appendChild page.node
      @slide.index = 0
      @length = @children.length

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
  constructor: ->
    @node = document.createElement 'div'
    @node.className = 'sj-page'
    @children = []
    @index = -1
    @total_count = 0

  add: (fragment) ->
    if fragment
      @children.push fragment
      @node.appendChild fragment.node
      @total_count = @children.length

  is_end: -> @index is @total_count - 1

  is_first: -> @index is 0

  next: ->
    index = @index + 1
    if 0 <= index < @total_count
      @children[index].show()
      @index = index

  previous: ->
    if 0 <= @index < @total_count
      @children[@index].hide()
      @index = @index - 1

  show: ->
    @children[i].show() for i in [0..@total_count-1]
    @index = @total_count - 1

  hide: ->
    @children[i].hide() for i in [0..@total_count-1]
    @index = -1 if @total_count > 0

class Fragment
  constructor: ->
    @node = document.createElement 'div'
    @node.className = 'sj-fragment'
    @hide()

  add: (text) -> @node.appendChild text if text

  show: -> @node.style.display = ''

  hide: -> @node.style.display = 'none'

class Control
  constructor: (@slide) ->
    @node = document.createElement 'div'
    @node.className = 'sj-control'
    @previous_page = new PreviousPage(@slide, @)
    @previous_fragment = new PreviousFragment(@slide, @)
    @next_fragment = new NextFragment(@slide, @)
    @next_page = new NextPage(@slide, @)
    @full_screen = new FullScreen(@slide, @)
    @page_info = new PageInfo(@slide, @)
    @slide.node.appendChild @node

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
    Util.addEvent(@node, 'mousedown', (event) -> _button.mouse_down(_button, event)) if @mouse_down
    Util.addEvent(document, 'keyup', (event) -> _button.key_up(_button, event)) if @key_up
    @init(_button) if @init

  mouse_down: (button, event) -> button.run(button, event)

  key_up: (button, event) -> button.run(button, event) if button.keyCode && event.keyCode is button.keyCode

class PreviousPage extends Button
  init: (button)->
    @node.className = 'sj-previous-page'
    @node.innerHTML = '《'
    @node.setAttribute('title', '上一页')
    @keyCode = 37

  visible: -> @slide.length > 0

  enable: -> @slide.cycle || @slide.index isnt 1

  run: (button, event) -> button.slide.show.previous_page()

  update_status: ->

class PreviousFragment extends Button
  init: (button)->
    @node.className = 'sj-previous-fragment'
    @node.innerHTML = '&lt;'
    @node.setAttribute('title', '上一段')
    @keyCode = 38
  
  run: (button, event) -> button.slide.show.previous_fragment()

  update_status: ->

class NextFragment extends Button
  init: (button)->
    @node.className = 'sj-next-fragmet'
    @node.innerHTML = '&gt;'
    @node.setAttribute('title', '下一段')
    @keyCode = 40

  run: (button, event) -> button.slide.show.next_fragment()

  update_status: ->

class NextPage extends Button
  init: (button)->
    @node.className = 'sj-next-page'
    @node.innerHTML = '》'
    @node.setAttribute('title', '下一页')
    @keyCode = 39

  visible: (slide) -> slide.length > 0
  enable: (slide) -> slide.cycle || slide.index isnt slide.length

  run: (button, event) -> button.slide.show.next_page()

  update_status: -> 
    # if @slide.config.cycle || @slide.show.index isnt @slide.show.length
    #   @node.style.display = 'none'

class FullScreen extends Button
  init: (button)->
    @node.className = 'sj-full-screen-button'
    @node.innerHTML = '□'
    @node.setAttribute('title', '全屏')
    for listener_name in ['fullscreenchange','webkitfullscreenchange','mozfullscreenchange']
      Util.addEvent document, listener_name, (event) -> 
        if document.webkitCurrentFullScreenElement
          Util.addClass(button.slide.node, 'sj-full-screen') 
        else
          Util.removeClass(button.slide.node, 'sj-full-screen') 
  run: (button, event) ->
    if document.webkitCurrentFullScreenElement
      request = (document.cancelFullScreen|| document.webkitCancelFullScreen|| document.mozCancelFullScreen|| document.exitFullscreen)
      request.call(document) if request   
    else
      node = button.slide.node
      request = (node.requestFullScreen || node.mozRequestFullScreen || node.webkitRequestFullScreen || node.msRequestFullScreen)
      request.call(node) if request

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
    @outer_node = document.createElement 'div'
    @outer_node.className = 'sj-progress-outer'
    @node.appendChild @outer_node
    @inner_node = document.createElement 'div'
    @inner_node.className = 'sj-progress-inner'
    @outer_node.appendChild @inner_node
    @slide.node.appendChild @node

  update_status: -> @inner_node.style.width = "#{ (@slide.show.index + 1) / @slide.show.length * 100}%" if @slide.show.length isnt -1

window.onload = -> new Slide {id: 'content', cycle: false, break: 'hr'}
