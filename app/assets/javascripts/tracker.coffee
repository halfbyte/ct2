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
    row_num = 0
    @pattern_html = ""
    for row in @options.pattern
      @pattern_html += "<div class='row'><div class='row-num'>" + @format_dec(row_num) + "</div>"
      for col in row
        @pattern_html += "<div class='cell'><span class='note'>" + col.note_text + @format_byte(col.sample) + @format_nybble(col.command) + @format_byte(col.command_params) + "</span></div>"
      @pattern_html += "</div>"
      row_num++

    @$el.html(@pattern_html)
    @change_to_row(@current_row)
    this

class window.CT2.views.TrackerView extends Backbone.View
  className: 'tracker'

  current_pos: 0

  initialize: ->
    @current_pattern = 0
    @patterns = []
    @mode = 'idle'

  move_to: (pattern, row) =>
    if pattern != @current_pattern
      @change_pattern(pattern)
    @patterns[@current_pattern].change_to_row(row)

  move_to_pos: (pos, row) =>
    pattern = window.CT2.PlayerInstance.module.pattern_table[pos]
    @move_to(pattern, row)

  change_pattern: (pattern) =>
    console.log('change pattern', pattern)
    @current_pattern = pattern
    @render()
  render_current_pattern: ->
    @patterns[@current_pattern].render()

  render: ->
    @patterns[@current_pattern] ?= new window.CT2.views.PatternView({pattern: @options.module.patterns[@current_pattern]})
    @$el.html(@patterns[@current_pattern].render().el)
    this


class window.CT2.views.AppView extends Backbone.View

  keymapping:
    9: 'jump_channel'
    32: 'spacebar'
    39: 'right'
    37: 'left'
    38: 'up'
    40: 'down'
    112: 'lower_octave'
    113: 'upper_octave'
    189: 'delete_note'

  initialize: ->
    @setElement('body');
    console.log("well")
    # TODO: Configure Notemapping for different keyboards
    @notemapping = window.CT2.constants.KEYS_TO_NOTES.de
    @current_channel = 0
    @current_pattern = 0
    @current_row = 0
    @current_col = 0
    @current_sample = 0
    @current_octave = 0
    @current_pos = 0
    @editstep = 1

    @update_cursor()

    window.setInterval(@update_view, 40);

    if @$('#trackerpane').data('url')
      $.getJSON(@$('#trackerpane').data('url'), {}, @json_loaded)



  events:
    'keydown': 'keydown'
    'change #modfile': 'load_mod'
    'click #play': 'play'
    'click #pattern': 'play_pattern'
    'click #stop': 'stop'
    'click #edit': 'edit'
    'click #disk-op': 'save'
    'click .pattern_in_pos': 'pattern_in_pos'
    'click .position.up': 'next_pos'
    'click .position.down': 'prev_pos'
    'click .num_patterns': 'num_patterns'
    'click #insert': 'insert_pattern'
    'click #delete': 'delete_pattern'
    'click #finetune-up': 'finetune_up'
    'click #finetune-down': 'finetune_down'
    'click #sample-up': 'next_sample'
    'click #sample-down': 'prev_sample'
    'click #volume-up': 'volume_up'
    'click #volume-down': 'volume_down'

  json_loaded: (data) =>
    console.log(data.name)
    window.CT2.PlayerInstance.load_from_json(data, @loaded)


  format_num: (w, l, b) ->
    str = w.toString(b).toUpperCase()
    if str.length < l
      str  = "00000000000000000000000000000".substr(0,l - str.length) + str
    str

  pad_with_underscores: (s, l) ->
    str = s
    if str.length < l
      str += "______________________________________________".substr(0,l - str.length)
    str

  display_status: (status) ->
    @$('#status').html(status.toUpperCase())
    window.setTimeout(@display_default_status, 1000)

  display_default_status: =>
    @$('#status').html("ALL RIGHT")

  pattern_in_pos: (e) ->
    if $(e.target).hasClass('up')
      window.CT2.PlayerInstance.module.pattern_table[@current_pos]++
      if window.CT2.PlayerInstance.module.pattern_table[@current_pos] >= window.CT2.PlayerInstance.module.num_patterns
        if window.CT2.PlayerInstance.module.num_patterns < 128
          window.CT2.PlayerInstance.module.add_pattern()
        else
          window.CT2.PlayerInstance.module.pattern_table[@current_pos] = window.CT2.PlayerInstance.module.num_patterns - 1
    else if $(e.target).hasClass('down')
      window.CT2.PlayerInstance.module.pattern_table[@current_pos]--
      if window.CT2.PlayerInstance.module.pattern_table[@current_pos] < 0
        window.CT2.PlayerInstance.module.pattern_table[@current_pos] = 0
    @update_pattern_fields()

  insert_pattern: ->
    if window.CT2.PlayerInstance.module.pattern_table_length < 128
      window.CT2.PlayerInstance.module.pattern_table.splice(@current_pos,0, 0)
      window.CT2.PlayerInstance.module.pattern_table_length++
    @update_pattern_fields()
  delete_pattern: ->
    if window.CT2.PlayerInstance.module.pattern_table_length > 1
      window.CT2.PlayerInstance.module.pattern_table.splice(@current_pos,1)
      window.CT2.PlayerInstance.module.pattern_table_length--
    @update_pattern_fields()

  num_patterns: (e) ->
    console.log(e)
    if $(e.target).hasClass('up')
      window.CT2.PlayerInstance.module.pattern_table_length++
      if window.CT2.PlayerInstance.module.pattern_table_length > 128
        window.CT2.PlayerInstance.module.pattern_table_length = 128
    else if $(e.target).hasClass('down')
      window.CT2.PlayerInstance.module.pattern_table_length--
      if window.CT2.PlayerInstance.module.pattern_table_length < 1
        window.CT2.PlayerInstance.module.pattern_table_length = 1
    @update_pattern_fields()
  edit: ->
    @set_mode('editing')

  spacebar: ->
    if @mode == 'playing'
      @stop()
    else if @mode == 'editing'
      @set_mode('idle')
    else
      @edit()

  play_pattern: ->
    window.CT2.PlayerInstance.play_pattern(@current_pattern)
    @set_mode('playing')
  play: ->
    window.CT2.PlayerInstance.play()
    @set_mode('playing')

  stop: ->
    window.CT2.PlayerInstance.stop()
    @set_mode('idle')

  save: ->
    @stop()
    if @$('#trackerpane').data('url')
      $.ajax({
        url: @$('#trackerpane').data('url'),
        data:
          data: JSON.stringify(window.CT2.PlayerInstance.module.as_json())
        success: @saved,
        type: 'PUT',
      })

  saved: =>
    @display_status("Saved!")

  load_mod: (e) ->
    console.log("load")
    file = $(e.target).get(0).files[0];
    @$('button #playcontrol.active')

    window.CT2.PlayerInstance.load_from_local_file(file, @loaded)

  loaded: (err) =>
    if err
      console.log('failing ...')
      console.log(err)
    else
      console.log("loaded.")
      window.CT2.trackerView = new window.CT2.views.TrackerView({module: window.CT2.PlayerInstance.module})
      @$('#boxes-and-tracker').append(window.CT2.trackerView.render().el)
      @update_song_fields()
      @update_pattern_fields()
      @update_sample_fields()

  update_view: =>
    if window.CT2.trackerView? and @mode == 'playing'
      @current_pos = window.CT2.PlayerInstance.cur_pos
      if not window.CT2.PlayerInstance.pattern_only
        @current_pattern = window.CT2.PlayerInstance.module.pattern_table[@current_pos]
      @update_pattern_fields()
      window.CT2.trackerView.move_to(@current_pattern, window.CT2.PlayerInstance.cur_row)

  update_cursor: ->
    char_width = 30
    box_width = 216
    offset = 84
    channel_step_size = 43
    x = offset + (@current_channel * box_width) + (@current_col * char_width) + (if @current_col > 0 then char_width*2 else 0) + (@current_channel * channel_step_size)
    @$('#cursor').css('left', x)

  update_tracker: ->
    if window.CT2.trackerView?
      window.CT2.trackerView.move_to(@current_pattern, @current_row)
      @update_pattern_fields()

  update_song_fields: ->
    @$('#songname #name').html(@pad_with_underscores(window.CT2.PlayerInstance.module.name, 20))

  update_pattern_fields: ->
    @$('#bpm').html(window.CT2.PlayerInstance.bpm)
    @$('#position_counter').html(@format_num(@current_pos, 4, 10))
    @$('#num_patterns').html(@format_num(window.CT2.PlayerInstance.module.pattern_table_length, 4, 10))
    @$('#current_pattern span').html(@format_num(@current_pattern, 2, 10))
    @$('#pattern_in_pos').html(@format_num(window.CT2.PlayerInstance.module.pattern_table[@current_pos], 4, 10))

  update_sample_fields: ->
    sample = window.CT2.PlayerInstance.module.samples[@current_sample]
    @$('#sample_finetune').html(sample.finetune)
    @$('#sample_number').html(@format_num(@current_sample + 1, 4, 16))
    @$('#sample_volume').html(@format_num(sample.volume, 4, 16))
    @$('#sample_repeat').html(@format_num(sample.repeat, 4, 16))
    @$('#sample_length').html(@format_num(sample.length, 4, 16))
    @$('#sample_replen').html(@format_num(sample.replen, 4, 16))
    @$('#samplename').html(@pad_with_underscores(sample.name, 22))


  upper_octave: ->
    @current_octave = 1
    @display_status('Octave: hi')

  lower_octave: ->
    @current_octave = 0
    @display_status('Octave: lo')

  delete_note: (event) ->
    event.preventDefault()
    if @mode == 'editing'
      CT2.PlayerInstance.module.delete_note(@current_pattern, @current_row, @current_channel)
      window.CT2.trackerView.render_current_pattern();

  up: ->
    @current_row--
    @current_row = 63 if @current_row < 0
    @update_tracker()

  down: ->
    @advance(1)

  advance: (step) ->
    @current_row = (@current_row + step) % 64
    @update_tracker()

  right: (e) ->
    console.log()
    if e.altKey
      @next_pattern()
    else if e.ctrlKey
      @next_sample()
    else if e.shiftKey
      @next_pos()
    else
      @cursor_right()
  left: (e) ->
    if e.altKey
      @prev_pattern()
    else if e.ctrlKey
      @prev_sample()
    else if e.shiftKey
      @prev_pos()
    else
      @cursor_left()


  next_pattern: ->
    @current_pattern++
    if @current_pattern >= window.CT2.PlayerInstance.module.num_patterns
      @current_pattern = window.CT2.PlayerInstance.module.num_patterns - 1
      console.log(@current_pattern)
    @update_tracker()

  next_sample: ->
    @current_sample++
    if @current_sample > 30
      @current_sample = 30
    @update_sample_fields()
  next_pos: ->
    @current_pos++
    if @current_pos >= window.CT2.PlayerInstance.module.pattern_table.length
      @current_pos = window.CT2.PlayerInstance.module.pattern_table.length - 1
    @update_pattern_fields()
    window.CT2.PlayerInstance.cur_pos = @current_pos

  volume_up: (event) ->
    event.preventDefault()
    window.CT2.PlayerInstance.module.volume_up(@current_sample)
    @update_sample_fields()

  volume_down: (event) ->
    event.preventDefault()
    window.CT2.PlayerInstance.module.volume_down(@current_sample)
    @update_sample_fields()

  finetune_up: (event) ->
    event.preventDefault()
    window.CT2.PlayerInstance.module.finetune_up(@current_sample)
    @update_sample_fields()

  finetune_down: (event) ->
    event.preventDefault()
    window.CT2.PlayerInstance.module.finetune_down(@current_sample)
    @update_sample_fields()

  prev_pattern: ->
    @current_pattern--
    if @current_pattern < 0
      @current_pattern = 0
    @update_tracker()
  prev_sample: ->
    @current_sample--
    if @current_sample < 0
      @current_sample = 0
    @update_sample_fields()
  prev_pos: ->
    @current_pos--
    if @current_pos < 0
      @current_pos = 0
    @update_pattern_fields()
    window.CT2.PlayerInstance.cur_pos = @current_pos

  cursor_left: ->
    @current_col--
    if @current_col < 0
      @current_channel--
      @current_channel = 3 if @current_channel < 0
      @current_col = 5
    @update_cursor()

  cursor_right: ->
    @current_col++
    if @current_col > 5
      @current_channel = (@current_channel + 1) % 4
      @current_col = 0
    @update_cursor()

  jump_channel: (e)->
    if e.shiftKey
      @prev_channel()
    else
      @next_channel()

  next_channel: ->
    @current_channel = (@current_channel + 1) % 4
    @current_col = 0
    @update_cursor()

  prev_channel: ->
    @current_channel--
    @current_channel = 3 if @current_channel < 0
    @update_cursor()

  keydown: (e) ->
    console.log(e)
    if @keymapping[e.which]?
      console.log("keymapping")
      @[@keymapping[e.which]](e)
      e.preventDefault()
    else if @current_col == 0 && not e.metaKey and not e.ctrlKey and not e.shiftKey and not e.altKey and e.which != 0 and @notemapping[String.fromCharCode(e.which)]?
      console.log("notemapping")
      @note_input(@notemapping[String.fromCharCode(e.which)])
      e.preventDefault()
    else if @current_col > 0 and @mode == 'editing' and not e.ctrlKey and not e.shiftKey and not e.metaKey and not e.altKey
      console.log("data entry")
      @data_input(e)
    else if e.which >= 49 and e.which <= 57 and e.ctrlKey
      @set_editstep(e.which - 48)
    else
      console.log("Currently Unmapped Key", e.which, e)



  data_input:(e) ->
    num = parseInt(String.fromCharCode(e.which), 16)
    return if _.isNaN(num)

    switch @current_col
      when 1
        if num < 2
          CT2.PlayerInstance.module.set_sample_hi(@current_pattern,@current_row,@current_channel, num)
          @advance(@editstep)
      when 2
        CT2.PlayerInstance.module.set_sample_lo(@current_pattern,@current_row,@current_channel, num)
        @advance(@editstep)
      when 3
        CT2.PlayerInstance.module.set_command(@current_pattern,@current_row,@current_channel, num)
        @advance(@editstep)
      when 4
        CT2.PlayerInstance.module.set_command_param_hi(@current_pattern,@current_row,@current_channel, num)
        @advance(@editstep)
      when 5
        CT2.PlayerInstance.module.set_command_param_lo(@current_pattern,@current_row,@current_channel, num)
        @advance(@editstep)

    window.CT2.trackerView.render_current_pattern();

  set_editstep: (step) ->
    @editstep = step
    @display_status("editstep = " + step)

  note_input:(note_num) ->
    note = note_num + ((@current_octave + 1) * 12)
    window.CT2.PlayerInstance.trig_single_note(@current_channel, @current_sample, note)
    if @mode == 'editing'
      CT2.PlayerInstance.module.set_note(@current_pattern,@current_row,@current_channel, note, @current_sample)
      window.CT2.trackerView.render_current_pattern();

      @advance(@editstep)
      console.log("insert note:", note);

  set_mode: (mode) ->
    @mode = mode
    $('body').setMode(mode, 'mode');


jQuery ->
  window.CT2.App = new window.CT2.views.AppView();








