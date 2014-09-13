####################################################
#                                                  #
#  Slide(.sj-slide)                                #
#                                                  #
#  ##############################################  #
#  #                                            #  #
#  #  Show                                      #  #
#  #   - Page                                   #  #
#  #     - Fragment                             #  #
#  #                                            #  #
#  ##############################################  #
#  #                                            #  #
#  #  Control                                   #  #
#  #   - Button | Button | Button     PageInfo  #  #
#  #                                            #  #
#  ##############################################  #
#  #                                            #  #
#  #  ProgressBar                               #  #
#  #                                            #  #
#  ##############################################  #
#                                                  #
####################################################

class Slide
  constructor: (@config) ->
    @node = document.getElementById @config.id
    @show = new Show(@)
    @control = new Control(@)
    @page_info = @control.page_info
    @progress_bar = new ProgressBar(@)

  update_status: ->
    @page_info.update_status() if @page_info
    @progress_bar.update_status() if @progress_bar

class Show
  constructor: (@slide) ->
    @index = -1
    @length = -1
    @children = []
    @node = document.createElement 'div'
    @node.className = 'slide'
    for child in @slide.node.children
      page = new Page unless page
      if child.tagName is 'hr'.toUpperCase()
        @add page
        page = new Page
      else
        fragment = new Fragment page
        fragment.add child.cloneNode(true)
        page.add fragment
      child.style.display = 'none'
    @add page
    @slide.node.appendChild @node
    @set_index(0) if @length isnt 0

  add: (page) ->
    if page
      @children.push page
      @node.appendChild page.node
      @slide.index = 0
      @length = @children.length

  set_index: (value) ->
    @index = value
    @slide.update_status()

  next_page: ->
    if 0 <= @index < @length - 1
      if @children[@index].is_end()
        @children[@index].hide()
        @set_index(@index + 1)
        @children[@index].show()
      else
        @children[@index].show() 
    else if @index is @length - 1 && @slide.config.cycle
      if @children[@index].is_end()
        @children[@index].hide()
        @set_index(0)
        @children[@index].show()
      else
        @children[@index].show()

  previous_page: ->
    if 0 < @index < @length
      @children[@index].hide()
      @set_index(@index - 1)
      @children[@index].show()
    else if @index is 0 && @slide.config.cycle
      @children[@index].hide()
      @set_index(@length - 1)
      @children[@index].show()

  next_fragment: ->
    if @index is @length - 1 && @children[@index].is_end() && @slide.config.cycle
      @children[@index].hide()
      @set_index(0)
      @children[@index].show()
    else if 0 <= @index < @length && @children[@index].is_end()
      @children[@index].hide()
      @set_index(@index + 1)
      @children[@index].next()
    else if 0 <= @index < @length
      @children[@index].next()

  previous_fragment: ->
    if @index is 0 && @children[@index].is_first() && @slide.config.cycle
      @children[@index].hide()
      @set_index(@length - 1)
      @children[@index].show()
    else if 0 <= @index < @length && @children[@index].is_first()
      @children[@index].hide()
      @set_index(@index - 1)
      @children[@index].show()
    else if 0 <= @index < @length
      @children[@index].previous()

class Page
  constructor: ->
    @node = document.createElement 'div'
    @node.className = 'page'
    @children = []
    @index = -1
    @total_count = 0

  add: (fragment) ->
    if fragment
      @children.push fragment
      @node.appendChild fragment.node
      @index = 0
      @total_count = @children.length

  is_end: -> @index is @total_count

  is_first: -> @index is 1

  next: ->
    index = @index + 1
    if 1 <= index <= @total_count
      @children[index - 1].show()
      @index = index

  previous: ->
    if 1 <= @index <= @total_count
      @children[@index - 1].hide()
      @index = @index - 1

  show: ->
    @children[i - 1].show() for i in [1..@total_count]
    @index = @total_count

  hide: ->
    @children[i - 1].hide() for i in [1..@total_count]
    @index = 0 if @total_count > 0

class Fragment
  constructor: ->
    @node = document.createElement 'div'
    @node.className = 'fragment'
    @hide()

  add: (text) ->
    @node.appendChild text if text

  show: -> @node.style.display = ''

  hide: -> @node.style.display = 'none'

class Control
  constructor: (@slide) ->
    @node = document.createElement 'div'
    @node.className = 'control'
    @previous_page = new PreviousPageButton(@slide, @)
    @previous_fragment = new PreviousFragmentButton(@slide, @)
    @next_fragment = new NextFragmentButton(@slide, @)
    @next_page = new NextPageButton(@slide, @)
    @full_screen = new FullScreenButton(@slide, @)
    @page_info = new PageInfo(@slide, @)
    @slide.node.appendChild @node

class Button
  constructor: (@slide, @parent) ->
    @show = @slide.show
    @node = document.createElement 'div'
    _button = @
    if @mouse_down
      if document.addEventListener
        @node.addEventListener('mousedown', (event) -> _button.mouse_down(_button, event)) 
      else
        @node.attachEvent('onmousedown', (event) -> _button.mouse_down(_button, event))
    if @key_up
      if document.addEventListener
        document.addEventListener('keyup', (event) -> _button.key_up(_button, event))
      else
        document.attachEvent('onkeyup', (event) -> _button.key_up(_button, event))
    @parent.node.appendChild @node
    @init() if @init

  mouse_down: (button, event) -> button.run(button, event)

  key_up: (button, event) -> button.run(button, event) if button.keyCode && event.keyCode is button.keyCode

class PreviousPageButton extends Button
  init: ->
    @node.className = 'control-action previous-page-action'
    @node.innerHTML = '《'
    @node.setAttribute('title', '上一页')
    @keyCode = 37

  visible: -> @slide.length > 0

  enable: -> @slide.cycle || @slide.index isnt 1

  run: (button, event) -> button.slide.show.previous_page()

class PreviousFragmentButton extends Button
  init: ->
    @node.className = 'control-action previous-fragment-action'
    @node.innerHTML = '&lt;'
    @node.setAttribute('title', '上一段')
    @keyCode = 38
  
  run: (button, event) -> button.slide.show.previous_fragment()

class NextFragmentButton extends Button
  init: ->
    @node.className = 'control-action next-fragment-action'
    @node.innerHTML = '&gt;'
    @node.setAttribute('title', '下一段')
    @keyCode = 40

  run: (button, event) -> button.slide.show.next_fragment()

class NextPageButton extends Button
  init: ->
    @node.className = 'control-action next-page-action'
    @node.innerHTML = '》'
    @node.setAttribute('title', '下一页')
    @keyCode = 39

  visible: (slide) -> slide.length > 0
  enable: (slide) -> slide.config.cycle || slide.index isnt slide.length

  run: (button, event) -> button.slide.show.next_page()

class FullScreenButton extends Button
  init: ->
    @node.className = 'control-action full-screen-action'
    @node.innerHTML = '□'
    @node.setAttribute('title', '全屏')
    if document.addEventListener
      for listener_name in ['fullscreenchange','webkitfullscreenchange','mozfullscreenchange']
        document.addEventListener(listener_name, (event) -> 
          if document.webkitCurrentFullScreenElement 
            slide.parent.classList.add('full-screen')
          else
            slide.parent.classList.remove('full-screen')
        )

  run: (button, event) ->
    if document.webkitCurrentFullScreenElement
      request = (document.cancelFullScreen|| document.webkitCancelFullScreen|| document.mozCancelFullScreen|| document.exitFullscreen)
      request.call(document) if request   
    else
      request = (slide.parent.requestFullScreen || slide.parent.mozRequestFullScreen || slide.parent.webkitRequestFullScreen || slide.parent.msRequestFullScreen)
      request.call(slide.parent) if request

class PageInfo
  constructor: (@slide, @parent) ->
    @node = document.createElement 'div'
    @node.className = 'page-info'
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
    @node.className = 'progress-bar'
    @outer_node = document.createElement 'div'
    @outer_node.className = 'progress-outer'
    @node.appendChild @outer_node
    @inner_node = document.createElement 'div'
    @inner_node.className = 'progress-inner'
    @outer_node.appendChild @inner_node
    @slide.node.appendChild @node

  update_status: -> @inner_node.style.width = "#{ (@slide.show.index + 1) / @slide.show.length * 100}%" if @slide.show.length isnt -1

window.onload = -> new Slide {id: 'content', cycle: true}
