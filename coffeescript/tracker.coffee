# @codekit-prepend "player.coffee"

window.App = {views: {}}

class window.App.views.TrackerView extends Backbone.View
  tagName: 'table'
  NOTES: ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-', 'B#']

  current_pattern: 0
  attrs:
    cellspacing: 0
    cellpadding: 0

  initialize: () ->
    console.log("initialized")
    @currentRow = 0
    @currentCol = 0

  set_data: (data) ->
    @module = data

  keyup_handler: (e) =>
    console.log(this)
    switch e.which
      when 37, 38, 39, 40 then @moveInTracker(e.which)
    e.preventDefault()

  render: ->
    table_content = ""
    for i in [0..63]
      table_content += "<tr id='row-" + i + "'>"
      table_content += "<td class='row-num'>" + i + "</td>"
      table_content += "<td class='note'>C-3</td><td class='command-1'>A</td><td class='command-2'>0</td><td class='command-3'>1</td>"
      table_content += "<td class='note'>C-3</td><td class='command-1'>A</td><td class='command-2'>0</td><td class='command-3'>1</td>"
      table_content += "<td class='note'>C-3</td><td class='command-1'>A</td><td class='command-2'>0</td><td class='command-3'>1</td>"
      table_content += "<td class='note'>C-3</td><td class='command-1'>A</td><td class='command-2'>0</td><td class='command-3'>1</td>"
      table_content += "</tr>";
    @$el.append(table_content)
    @updateTablePlacement()
    return this

  updateTablePlacement: ->
    console.log(this)
    $('tr,td', @table).removeClass('active')
    row = $('tr:nth-child(' + (@currentRow + 1) + ')', @table)
    row.addClass('active')
    col = $('td:nth-child(' + (@currentCol+2) + ')', row)
    col.addClass('active')

    y = 44 * (@currentRow - 5) * -1
    @$el.css('top', y)

  moveInTracker: (c) ->
    switch c
      when 40 then @currentRow = (@currentRow + 1) % 64
      when 38
        @currentRow--
        @currentRow += 63 if @currentRow < 0
      when 39 then @currentCol = (@currentCol + 1) % 16
      when 37
        @currentCol--;
        @currentCol += 15 if @currentCol < 0

    @updateTablePlacement()


jQuery ->
  window.App.trackerView = new window.App.views.TrackerView()
  $('#trackerpane').append(window.App.trackerView.render().el)
  window.App.trackerView.updateTablePlacement()
  $(window).keyup(window.App.trackerView.keyup_handler)


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

    $('button#playcontrol.active')

    window.Player.load file, (err)->
      if err
        console.log('failing ...')
        console.log(err)
      else
        $('#playcontrol').addClass('active').html('PLAY').data('playing', false);
        
