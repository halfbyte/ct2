# @codekit-prepend "player.coffee"

window.App = {views: {}}

Handlebars.registerHelper 'hiNyb', (obj) ->
  ((obj >> 4) & 0xF).toString(16).toUpperCase()

Handlebars.registerHelper 'loNyb', (obj) ->
  (obj & 0xF).toString(16).toUpperCase()

class window.App.views.CellView extends Backbone.View
  className: 'cell'
  
  initialize: ->
    @template = Handlebars.compile($('#tracker-cell').html())

  render: ->
    @$el.html(@template(@options.cell))
    this

class window.App.views.RowView extends Backbone.View
  className: 'row'
  initialize: ->
    
    @cells = for cell in @options.row
      new window.App.views.CellView({cell: cell})
  render: ->
    cell_elements = for cell in @cells
      cell.render().el
    cell_elements.unshift(this.make('div', {class: 'row-num'}, @options.row_num.toString(10)))
    @$el.html(cell_elements)
    
    this

class window.App.views.PatternView extends Backbone.View
  className: 'pattern',
  initialize: ->
    @current_row = 0
    row_num = 0
    @rows = for row in @options.pattern
      row = new window.App.views.RowView({row: row, row_num: row_num})
      row_num++
      row
      
  change_row_by: (n) ->
    @change_to_row(@current_row + n)
    
  change_to_row: (row) ->
    @current_row = row
    @current_row = 63 if @current_row < 0
    @current_row = 0 if @current_row > 63
    @$('.row').removeClass('active')
    @rows[@current_row].$el.addClass('active')
    this.$el.css('top', (@current_row - 7) * -21)

  render: ->
    row_elements = for row in @rows
      row.render().el
    @$el.html(row_elements)
    @change_to_row(@current_row)
    this

class window.App.views.TrackerView extends Backbone.View
  className: 'tracker'

  current_pos: 0

  initialize: ->
    @current_pos = 0
    @patterns = []
  move_in_tracker: (key) ->
    switch key
      when 40
        @current_pattern().change_row_by(1)
      when 38
        @current_pattern().change_row_by(-1)

  move_to: (pos, row) =>
    if pos != @current_pos
      @change_pattern(pos)
    @current_pattern().change_to_row(row)

  keyup_handler: (e) =>
    switch e.which
      when 37, 38, 39, 40 then @move_in_tracker(e.which)
    e.preventDefault()

  current_pattern: ->
    p = @options.module.pattern_table[@current_pos]
    @patterns[p]

  change_pattern: (pos) =>
    @current_pos = pos
    @render()

  render: ->
    p = @options.module.pattern_table[@current_pos]
    @patterns[p] ?= new window.App.views.PatternView({pattern: @options.module.patterns[p]})
    @$el.html(@patterns[p].render().el)
    this
  

jQuery ->

  $('#playcontrol.active').live 'click', (e) ->    
    button = $(@)
    if button.data('playing')
      window.Player.stop()
      button.html('PLAY').data('playing', false);
    else
      window.Player.play()
      button.html('STOP').data('playing', true);

  $('#modfile').bind 'change', (e) ->
    file = $(this).get(0).files[0]

    $('button #playcontrol.active')

    window.Player.load file, (err)->
      if err
        console.log('failing ...')
        console.log(err)
      else
        window.App.trackerView = new window.App.views.TrackerView({module: window.Player.module})
        $('#trackerpane').append(window.App.trackerView.render().el)
        $('#playcontrol').addClass('active').html('PLAY').data('playing', false);
        $(window).keyup(window.App.trackerView.keyup_handler);
        window.setInterval(
          ->
            window.App.trackerView.move_to(window.Player.cur_pos, window.Player.cur_row)
          40
        )
            
          
        
          

        
