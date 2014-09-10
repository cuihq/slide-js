ACTIONS = [
  { 
    cls: 'previous-page-action',    
    val: '《' ,
    key: 37,
    title: '上一页'  
    run: (slide) ->
      if 1 < slide.current_number <= slide.length
        slide.children[slide.current_number - 1].hide()
        slide.set_current_number(slide.current_number - 1)
        slide.children[slide.current_number - 1].show()
      else if slide.current_number is 1 && config.cycle
        slide.children[slide.current_number - 1].hide()
        slide.current_number = slide.length
        slide.children[slide.current_number - 1].show()
  },
  { 
    cls: 'previous-fragment-action', 
    val: '&lt;',
    key: 38,
    title: '上一段'
    run: (slide) ->
      if slide.current_number is 1 && slide.children[slide.current_number - 1].is_first() && config.cycle
        slide.children[slide.current_number - 1].hide()
        slide.set_current_number(slide.length)
        slide.children[slide.current_number - 1].show()
      else if 1 < slide.current_number <= slide.length && slide.children[slide.current_number - 1].is_first()
        slide.children[slide.current_number - 1].hide()
        slide.set_current_number(slide.current_number - 1)
        slide.children[slide.current_number - 1].show()
      else if 1 <= slide.current_number <= slide.length
        slide.children[slide.current_number - 1].previous()
  },
  {     
    cls: 'next-fragment-action',    
    val: '&gt;',
    key: 40, 
    title: '下一段'
    run: (slide) ->
      if slide.current_number is slide.length && slide.children[slide.current_number - 1].is_end() && config.cycle
        slide.children[slide.current_number - 1].hide()
        slide.set_current_number(1)
        slide.children[slide.current_number - 1].show()
      else if 1 <= slide.current_number < slide.length && slide.children[slide.current_number - 1].is_end()
        slide.children[slide.current_number - 1].hide()
        slide.set_current_number(slide.current_number + 1)
        slide.children[slide.current_number - 1].next()
      else if 1 <= slide.current_number <= slide.length
        slide.children[slide.current_number - 1].next() 
  },
  {      
    cls: 'next-page-action',     
    val: '》',
    key: 39, 
    title: '下一页' 
    run: (slide) ->
      if 1 <= slide.current_number < slide.length
        if slide.children[slide.current_number - 1].is_end()
          slide.children[slide.current_number - 1].hide()
          slide.set_current_number(slide.current_number + 1)
          slide.children[slide.current_number - 1].show()
        else
          slide.children[slide.current_number - 1].show() 
      else if slide.current_number is slide.length && config.cycle
        if slide.children[slide.current_number - 1].is_end()
          slide.children[slide.current_number - 1].hide()
          slide.set_current_number(1)
          slide.children[slide.current_number - 1].show()
        else
          slide.children[slide.current_number - 1].show()
  },
  {
    cls: 'full-screen-action',
    val: '□',
    key: 122,
    title: '全屏'
    init: (slide) ->
      if document.addEventListener
        document.addEventListener('fullscreenchange', (event) -> 
          if document.webkitCurrentFullScreenElement 
            slide.parent.classList.add('full-screen')
          else
            slide.parent.classList.remove('full-screen')
        )
        document.addEventListener('webkitfullscreenchange', (event) ->  
          if document.webkitCurrentFullScreenElement 
            slide.parent.classList.add('full-screen')
          else
            slide.parent.classList.remove('full-screen')
        )
        document.addEventListener('mozfullscreenchange', (event) ->  
          if document.webkitCurrentFullScreenElement 
            slide.parent.classList.add('full-screen')
          else
            slide.parent.classList.remove('full-screen')
        )
    run: (slide) ->
      if document.webkitCurrentFullScreenElement
        request = (document.cancelFullScreen|| document.webkitCancelFullScreen|| document.mozCancelFullScreen|| document.exitFullscreen)
        request.call(document) if request   
      else
        request = (slide.parent.requestFullScreen || slide.parent.mozRequestFullScreen || slide.parent.webkitRequestFullScreen || slide.parent.msRequestFullScreen)
        request.call(slide.parent) if request
  }
]

class Action
  constructor: (parent, slide, config) ->
    node = document.createElement 'button'
    node.className = 'control-action ' + config.cls
    node.innerHTML = config.val if config.val
    node.setAttribute('title', config.title) if config.title
    node.onclick = -> config.run(slide)
    if document.addEventListener
      document.addEventListener('keyup', (event) -> config.run(slide) if config.key is event.keyCode)
    else
      document.attachEvent('onkeyup', (event) -> config.run(slide) if config.key is event.keyCode )
    parent.appendChild node
    config.init(slide) if config.init


class Slide
  constructor: (@config) ->
    @parent = document.getElementById @config.id
    @title_node = document.createElement 'div'
    @title_node.className = 'slide-title'
    @title_node.innerHTML = @config.title || 'slide'
    @slide_node = document.createElement 'div'
    @slide_node.className = 'slide'
    @children = []
    @current_number = -1
    @length = 0
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
    @parent.appendChild @slide_node

    @control_node = document.createElement 'div'
    @control_node.className = 'control'

    new Action(@control_node, @, action) for action in ACTIONS

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
    @total_page.innerHTML = @length
    @page_info_node.appendChild @total_page
    @control_node.appendChild @page_info_node

    @parent.appendChild @control_node
    @set_current_number(1) if @length isnt 0
    @children[0].show() if @length > 0

  add: (page) ->
    if page
      @children.push page
      @slide_node.appendChild page.node
      @current_number = 1
      @length = @children.length

  set_current_number: (value) ->
    @current_number = value
    @current_page_node.innerHTML = value
    if @length isnt 0
      @progress_inner.style.width = "#{@current_number / @length * 100}%"   

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

window.onload = -> new Slide config 
