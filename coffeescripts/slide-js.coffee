class Slide
  constructor: (@config) ->
    @parent = document.getElementById @config.id
    @title_node = document.createElement 'div'
    @title_node.className = 'slide-title'
    @title_node.innerHTML = @config.title || 'slide'
    @node = document.createElement 'div'
    @node.className = 'slide'
    @children = []
    @current_number = -1
    @total_count = 0
    for child in @parent.children
      if child
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
    @parent.appendChild @title_node
    @parent.appendChild @node

    @control_node = document.createElement 'div'
    @control_node.className = 'control'

    _slide = @
    @previous_page_node = document.createElement 'div'
    @previous_page_node.className = 'previous-page'
    @previous_page_node.innerHTML = '《'
    @previous_page_node.onclick = -> _slide.previous_page()
    @control_node.appendChild @previous_page_node

    @previous_fragment_node = document.createElement 'div'
    @previous_fragment_node.className = 'previous-fragment'
    @previous_fragment_node.innerHTML = '&lt;'
    @previous_fragment_node.onclick = -> _slide.previous_fragment()
    @control_node.appendChild @previous_fragment_node

    @next_fragment_node = document.createElement 'div'
    @next_fragment_node.className = 'next-fragment'
    @next_fragment_node.innerHTML = '&gt;'
    @next_fragment_node.onclick = -> _slide.next_fragment()
    @control_node.appendChild @next_fragment_node

    @next_page_node = document.createElement 'div'
    @next_page_node.className = 'next-page'
    @next_page_node.innerHTML = '》'
    @next_page_node.onclick = -> _slide.next_page()
    @control_node.appendChild @next_page_node

    @progress_bar_node = document.createElement 'div'
    @progress_bar_node.className = 'progress-bar'
    @progress_outer_node = document.createElement 'div'
    @progress_outer_node.className = 'progress-outer'
    @progress_bar_node.appendChild @progress_outer_node
    @progress_inner = document.createElement 'div'
    @progress_inner.className = 'progress-inner'
    @progress_outer_node.appendChild @progress_inner
    @control_node.appendChild @progress_bar_node

    @page_info_node = document.createElement 'div'
    @page_info_node.className = 'page-info'
    @current_page_node = document.createElement 'span'
    @current_page_node.className = 'current-page'
    @current_page_node.innerHTML = @current_number
    @page_info_node.appendChild @current_page_node
    @delimiter = document.createElement 'span'
    @delimiter.className = 'delimiter'
    @delimiter.innerHTML = '/'
    @page_info_node.appendChild @delimiter
    @total_page = document.createElement 'span'
    @total_page.className = 'total_page'
    @total_page.innerHTML = @total_count
    @page_info_node.appendChild @total_page
    @control_node.appendChild @page_info_node

    @full_screen_node = document.createElement 'div'
    @full_screen_node.className = 'full-screen'
    @full_screen_node.innerHTML = '□'
    @full_screen_node.onclick = ->
      request = (_slide.parent.requestFullScreen || _slide.parent.mozRequestFullScreen || _slide.parent.webkitRequestFullScreen)
      request.call(_slide.parent) if request
    @control_node.appendChild @full_screen_node

    @parent.appendChild @control_node
    @set_current_number(1) if @total_count isnt 0

  add: (page) ->
    if page
      @children.push page
      @node.appendChild page.node
      @current_number = 1
      @total_count = @children.length

  run: ->
    _slide = @
    if document.body.addEventListener
      window.addEventListener('keyup', (event) ->
        switch event.keyCode
          when 39 then _slide.next_page()
          when 37 then _slide.previous_page()
          when 32, 40 then _slide.next_fragment()
          when 38 then _slide.previous_fragment() 
      )
    else
      document.body.attachEvent('onkeyup', (event) ->
        switch event.keyCode
          when 39 then _slide.next_page()
          when 37 then _slide.previous_page()
          when 32, 40 then _slide.next_fragment()
          when 38 then _slide.previous_fragment() 
      )
    @children[0].show() if @total_count > 0

  set_current_number: (value) ->
    @current_number = value
    @current_page_node.innerHTML = value
    if @total_count isnt 0
      @progress_inner.style.width = "#{@current_number / @total_count * 100}%"

  next_page: ->
    if 1 <= @current_number < @total_count
      if @children[@current_number - 1].is_end()
        @children[@current_number - 1].hide()
        @set_current_number(@current_number + 1)
        @children[@current_number - 1].show()
      else
        @children[@current_number - 1].show() 
    else if @current_number is @total_count && config.cycle
      if @children[@current_number - 1].is_end()
        @children[@current_number - 1].hide()
        @set_current_number(1)
        @children[@current_number - 1].show()
      else
        @children[@current_number - 1].show()

  previous_page: ->
    if 1 < @current_number <= @total_count
      @children[@current_number - 1].hide()
      @set_current_number(@current_number - 1)
      @children[@current_number - 1].show()
    else if @current_number is 1 && config.cycle
      @children[@current_number - 1].hide()
      @current_number = @total_count
      @children[@current_number - 1].show()

  next_fragment: ->
    if @current_number is @total_count && @children[@current_number - 1].is_end() && config.cycle
      @children[@current_number - 1].hide()
      @set_current_number(1)
      @children[@current_number - 1].show()
    else if 1 <= @current_number < @total_count && @children[@current_number - 1].is_end()
      @children[@current_number - 1].hide()
      @set_current_number(@current_number + 1)
      @children[@current_number - 1].next()
    else if 1 <= @current_number <= @total_count
      @children[@current_number - 1].next()

  previous_fragment: ->
    if @current_number is 1 && @children[@current_number - 1].is_first() && config.cycle
      @children[@current_number - 1].hide()
      @set_current_number(@total_count)
      @children[@current_number - 1].show()
    else if 1 < @current_number <= @total_count && @children[@current_number - 1].is_first()
      @children[@current_number - 1].hide()
      @set_current_number(@current_number - 1)
      @children[@current_number - 1].show()
    else if 1 <= @current_number <= @total_count
      @children[@current_number - 1].previous()

class Page
  constructor: ->
    @node = document.createElement 'div'
    @node.className = 'page'
    @children = []
    @current_number = -1
    @total_count = 0

  add: (fragment) ->
    if fragment
      @children.push fragment
      @node.appendChild fragment.node
      @current_number = 0
      @total_count = @children.length

  is_end: -> @current_number is @total_count

  is_first: -> @current_number is 1

  next: ->
    index = @current_number + 1
    if 1 <= index <= @total_count
      @children[index - 1].show()
      @current_number = index

  previous: ->
    if 1 <= @current_number <= @total_count
      @children[@current_number - 1].hide()
      @current_number = @current_number - 1

  show: ->
    @children[i - 1].show() for i in [1..@total_count]
    @current_number = @total_count

  hide: ->
    @children[i - 1].hide() for i in [1..@total_count]
    @current_number = 0 if @total_count > 0

class Fragment
  constructor: ->
    @node = document.createElement 'div'
    @node.className = 'fragment'
    @hide()

  add: (text) ->
    @node.appendChild text if text

  show: -> @node.style.display = ''

  hide: -> @node.style.display = 'none'

config =
  id: 'content'
  cycle: true
  title: '幻灯片Demo'

window.onload = ->
  slide = new Slide config
  slide.run()  
