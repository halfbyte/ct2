class window.CT2.views.PatternView extends Backbone.View
  className: 'pattern',

  format_byte:(byte) ->
    str = (byte & 0xff).toString(16)
    str = "0" + str if str.length == 1
    str.toUpperCase()
  format_nybble: (nyb) ->
    nyb.toString(16).toUpperCase()

  format_dec: (dec) ->
    str = dec.toString(10)
    str = "0" + str if str.length == 1
    str

  initialize: ->
    @current_row = 0

    row_num = 0
    @pattern_html = ""
    for row in @options.pattern
      @pattern_html += "<div class='row'><div class='row-num'>" + @format_dec(row_num) + "</div>"
      for col in row
        @pattern_html += "<div class='cell'><span class='note'>" + col.note_text + @format_byte(col.sample) + @format_nybble(col.command) + @format_byte(col.command_params) + "</span></div>"
      @pattern_html += "</div>"
      row_num++

  change_row_by: (n) ->
    @change_to_row(@current_row + n)

  change_to_row: (row) ->
    row_to_start = 4
    line_height = -36
    @current_row = row
    @current_row = 63 if @current_row < 0
    @current_row = 0 if @current_row > 63
    @$('.row').removeClass('active')
    @$('.row:nth-child(' + (@current_row + 1) + ')').addClass('active');
    this.$el.css('top', (@current_row - row_to_start) * line_height)

  render: ->
    @$el.html(@pattern_html)
    @change_to_row(@current_row)
    this

class window.CT2.views.AppView extends Backbone.View

  keymapping:
    32: 'spacebar'
    39: 'right'
    37: 'left'
    38: 'up'
    40: 'down'

  initialize: ->
    @setElement('body');
    console.log("well")
    # TODO: Configure Notemapping for different keyboards
    @notemapping = window.CT2.constants.KEYS_TO_NOTES.de
    @current_channel = 0
    @current_row = 0
    @current_col = 0
    @current_sample = 0
    window.setInterval(@update_view, 40);

  events:
    'keydown': 'keydown'
    'change #modfile': 'load_mod'
    'click #play': 'play'
    'click #stop': 'stop'
    'click #edit': 'edit'

  edit: ->
    @set_mode('editing')

  spacebar: ->
    if @mode == 'playing'
      @stop()
    else if @mode == 'editing'
      @set_mode('idle')
    else
      @edit()

  play: ->
    window.CT2.PlayerInstance.play()
    @set_mode('playing')

  stop: ->
    window.CT2.PlayerInstance.stop()
    @set_mode('idle')

  load_mod: (e) ->
    console.log("load")
    file = $(e.target).get(0).files[0];
    @$('button #playcontrol.active')

    window.CT2.PlayerInstance.load file, (err) ->
      if err
        console.log('failing ...')
        console.log(err)
      else
        console.log("loaded.")
        window.CT2.trackerView = new window.CT2.views.TrackerView({module: window.CT2.PlayerInstance.module})
        $('#boxes-and-tracker').append(window.CT2.trackerView.render().el)
  update_view: =>
    if window.CT2.trackerView? and @mode == 'playing'
      window.CT2.trackerView.move_to(window.CT2.PlayerInstance.cur_pos, window.CT2.PlayerInstance.cur_row)

  update_cursor: ->
    x = 88 + (@current_channel * 216) + (@current_col * 23) + (if @current_col > 0 then 23*2 else 0)
    console.log(x)
    $('#cursor').css(left: x)
  update_tracker: ->
    if window.CT2.trackerView?
      window.CT2.trackerView.move_to(window.CT2.trackerView.current_pos, @current_row)

  up: ->
    @current_row--
    @current_row = 63 if @current_row < 0
    @update_tracker()
  down: ->
    @current_row = (@current_row + 1) % 64
    @update_tracker()
  right: ->
    @current_col++
    if @current_col > 5
      @current_channel = (@current_channel + 1) % 4
      @current_col = 0
    @update_cursor()
  left: ->
    @current_col--
    if @current_col < 0
      @current_channel--
      @current_channel = 3 if @current_channel < 0
      @current_col = 5
    @update_cursor()


  keydown: (e) ->
    if @keymapping[e.which]?
      @[@keymapping[e.which]]()
      e.preventDefault()
    else if not e.metaKey and not e.ctrlKey and not e.shiftKey and e.which != 0 and @notemapping[String.fromCharCode(e.which).toLowerCase()]?
      @note_input(@notemapping[String.fromCharCode(e.which).toLowerCase()])
      e.preventDefault()
    else
      console.log("Currently Unmapped Key", e.which, e.metaKey)


  note_input:(note) ->
    console.log("play note:", note);
    window.CT2.PlayerInstance.trig_single_note(@current_channel, @current_sample, note + 1)

  set_mode: (mode) ->
    @mode = mode
    $('body').setMode(mode, 'mode');


class window.CT2.views.TrackerView extends Backbone.View
  className: 'tracker'

  current_pos: 0

  initialize: ->
    @current_pos = 0
    @patterns = []
    @mode = 'idle'

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
    @patterns[p] ?= new window.CT2.views.PatternView({pattern: @options.module.patterns[p]})
    @$el.html(@patterns[p].render().el)
    this


jQuery ->
  window.CT2.App = new window.CT2.views.AppView();








