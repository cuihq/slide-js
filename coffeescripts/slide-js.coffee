config = { id: 'content', cycle: true }

class Slide
  constructor: (@parent) ->
    @node = document.createElement 'div'
    @node.className = 'slide'
    @children = []
    @current_number = -1
    @total_count = 0

  add: (page) ->
    if page
      @children.push page
      @node.appendChild page.node
      @current_number = 1
      @total_count = @children.length

  run: ->
    @parent.appendChild @node
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

  next_page: ->
    if 1 <= @current_number < @total_count
      if @children[@current_number - 1].is_end()
        @children[@current_number - 1].hide()
        @current_number += 1
        @children[@current_number - 1].show()
      else
        @children[@current_number - 1].show() 
    else if @current_number is @total_count && config.cycle
      if @children[@current_number - 1].is_end()
        @children[@current_number - 1].hide()
        @current_number = 1
        @children[@current_number - 1].show()
      else
        @children[@current_number - 1].show()

  previous_page: ->
    if 1 < @current_number <= @total_count
      @children[@current_number - 1].hide()
      @current_number -= 1
      @children[@current_number - 1].show()
    else if @current_number is 1 && config.cycle
      @children[@current_number - 1].hide()
      @current_number = @total_count
      @children[@current_number - 1].show()

  next_fragment: ->
    if @current_number is @total_count && @children[@current_number - 1].is_end() && config.cycle
      @children[@current_number - 1].hide()
      @current_number = 1
      @children[@current_number - 1].show()
    else if 1 <= @current_number < @total_count && @children[@current_number - 1].is_end()
      @children[@current_number - 1].hide()
      @current_number += 1
      @children[@current_number - 1].next()
    else if 1 <= @current_number <= @total_count
      @children[@current_number - 1].next()

  previous_fragment: ->
    if @current_number is 1 && @children[@current_number - 1].is_first() && config.cycle
      @children[@current_number - 1].hide()
      @current_number = @total_count
      @children[@current_number - 1].show()
    else if 1 < @current_number <= @total_count && @children[@current_number - 1].is_first()
      @children[@current_number - 1].hide()
      @current_number -= 1
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

window.onload = ->
  content = document.getElementById config.id
  slide = new Slide content
  for child in content.children
    if child
      page = new Page unless page
      if child.tagName is 'hr'.toUpperCase()
        slide.add page
        page = new Page
      else
        fragment = new Fragment page
        fragment.add child.cloneNode(true)
        page.add fragment
      child.style.display = 'none'
  slide.add page
  slide.run()  
