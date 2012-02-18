

window.App = {views: {}}

window.App.views.TrackerView = Backbone.View.extend
  tagName: 'table',
  NOTES: ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-', 'B#']

  current_pattern = 0
  attrs:
    cellspacing: 0
    cellpadding: 0
  initialize: () ->
    console.log("initialized")
    @currentRow = 0
    @currentCol = 0
    _.bindAll(this, 'keyup_handler')

  set_data: (data) ->
    @module = data
  keyup_handler: (e) ->
    console.log(this);
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

class Mod
  # convert array of charcodes to sting
  # seems to magically work.
  atos: (a) ->
    s = String.fromCharCode(a...)
  signed_nybble: (a) ->
    if a >= 8 then a-16 else a


  constructor: (data) ->
    @samples = []
    @patterns = []
    subdata = new Uint8Array(data, 1080, 4);
    if @atos(subdata) == 'M.K.'
      @name = @atos(new Uint8Array(data, 0, 20));
      for i in [0..30]
        sample = {}
        sample.name = @atos(new Uint8Array(data, 20 + (30*i), 22))
        sample_data = new Uint8Array(data, 20 + (30*i) + 22, 8)
        sample.length = ((sample_data[0] << 8) + (sample_data[1])) * 2
        sample.finetune = @signed_nybble(sample_data[2] & 0x0F)
        sample.raw_finetune = sample_data[2] & 0x0F
        sample.volume = sample_data[3]
        sample.repeat = ((sample_data[4] << 8) + (sample_data[5])) * 2
        sample.replen = ((sample_data[6] << 8) + (sample_data[7])) * 2
        @samples.push(sample)

      pattern_data = new Uint8Array(data, 950, 2)
      @pattern_table_length = pattern_data[0]
      @pattern_table = new Uint8Array(data, 952, 128)
      @num_patterns = _.max(@pattern_table)
      #console.log(module)
      for p in [0..@num_patterns]
        pattern = []
        pattern_data = new Uint8Array(data, 1084 + (p * 1024), 1024)
        for s in [0..63]
          step = []
          for c in [0..3]
            note = {}
            note.period = (pattern_data[(s * 16) + (c * 4)] & 0x0F << 8) + (pattern_data[(s * 16) + (c * 4) + 1] & 0xF0) + (pattern_data[(s * 16) + (c * 4) + 1] & 0x0F)
            note.note = find_note(note.period)
            note.sample = (pattern_data[(s * 16) + (c * 4)] & 0xF0) + ((pattern_data[(s * 16) + (c * 4) + 2] & 0xF0) >> 4)
            note.command = (pattern_data[(s * 16) + (c * 4) + 2] & 0x0F)
            note.command_params = (pattern_data[(s * 16) + (c * 4) + 3] & 0xF0) + (pattern_data[(s * 16) + (c * 4) + 3] & 0x0F)

            step.push(note)
          pattern.push(step)
        @patterns.push(pattern)

      offset = 1084 + ((@num_patterns + 1) * 1024)
      for sample in @samples
        sample.data = new Int8Array(data, offset, sample.length)
        offset += sample.length
    else
      raise('Invalid Module Data')

find_note = (period) ->
  note = 0
  bestd = Math.abs(period - Player::BASE_PTABLE[0])
  if (period)
    for i in [1..60]
      d = Math.abs(period-Player::BASE_PTABLE[i])
      if d < bestd
        bestd = d
        note = i
  note



clamp = (x, min, max) ->
  Math.max(min, Math.max(max, x))

lerp = (a, b, f) ->
  a + f * (b - a)

sinc = (x) ->
  if x then Math.sin(x) / x else 1

sqr = (x) ->
  x * x

hamming = (x) ->
  if (x > -1 && x < 1)
    sqr(Math.cos(x * Math.PI / 2.0))
  else
    0

class MixerVoice
  sample_len: 0
  loop_len: 0
  period: 65535
  volume: 0
  pos: 0
  pwm_count: 0
  div_count: 0
  cur: 0
  cur_i: 0
  sample: null

  render: (buffer, offset, samples) ->
    return if !@sample
    
    for i in [0...samples]
      if !@div_count
        @cur = 0.25 * @sample[@pos] / 128.0
          
        @pos++
        @pos -= @loop_len if @pos == @sample_len
        @div_count = @period
      buffer[i + offset] += @cur if (@pwm_count < @volume)
      @pwm_count = (@pwm_count + 1) & 0x3F
      @div_count--

  trigger: (sample, len, loop_len, offset) ->
    @sample = sample
    
    @sample_len = len
    @loop_len = loop_len
    @pos = Math.min(offset, @sample_len - 1)
    console.log("sample trigger", @period)



class Mixer
  
  RBSIZE: 4096
  FIR_WIDTH: 512
  PAULARATE: 3740000
  OUTRATE: 44100
  constructor: ->
    #console.log(@voices)
    @voices = []
    for i in [0..3]
      @voices.push(new MixerVoice())
    @ring_buf = new Float32Array(2 * @RBSIZE)
    @fir_mem = new Float32Array(2 * @FIR_WIDTH + 1)

    # sF32 *FIRTable=FIRMem+FIR_WIDTH;
    yscale = 1.0 * @OUTRATE/ @PAULARATE
    xscale=Math.PI * yscale
    for i in [0..(2*@FIR_WIDTH + 1)]
      @fir_mem[i] = yscale * sinc(1.0 * (i - @FIR_WIDTH) * xscale) * hamming(1.0 * (i - @FIR_WIDTH) / @FIR_WIDTH - 1.0)

    @write_pos = @FIR_WIDTH
    @read_pos = 0
    @read_frac = 0.0
    @master_volume = 0.66
    @master_separation = 0.5

  calc_frag: (buf, offset, samples) ->
    for i in [0..3]
      if i==1 || i==2
        @voices[i].render(buf, offset + @RBSIZE, samples)
      else
        @voices[i].render(buf, offset, samples)

  calc: ->
    real_read_pos = @read_pos - @FIR_WIDTH - 1
    samples = real_read_pos - @write_pos & (@RBSIZE - 1)
    todo = Math.min(samples, @RBSIZE - @write_pos)
    @calc_frag(@ring_buf, @write_pos, todo)
    if todo < samples
      @write_pos = 0
      todo = samples - todo
      @calc_frag(@ring_buf, 0, todo)

  render: (buffer, offset, samples) ->
    step = 1.0 * @PAULARATE / @OUTRATE
    pan = 0.5 * @master_separation
    vm0 = @master_volume * Math.sqrt(pan)
    vm1 = @master_volume * Math.sqrt(1 - pan)

    for s in [0...samples]
      @read_end = @read_pos + @FIR_WIDTH + 1
      @read_end -= @RBSIZE if @write_pos < @read_pos
      @calc() if @read_end > @write_pos
      outl0 = 0.0
      outl1 = 0.0
      outr0 = 0.0
      outr1 = 0.0

      offs = (@read_pos - @FIR_WIDTH - 1) & (@RBSIZE - 1)
      vl = @ring_buf[offs]
      vr = @ring_buf[offs + @RBSIZE]

      for i in [1...(2 * @FIR_WIDTH - 1)]
        w = @fir_mem[i]
        outl0+=vl*w
        outr0+=vr*w
        offs=(offs+1)&(@RBSIZE-1);
        vl=@ring_buf[offs];
        vr=@ring_buf[offs+@RBSIZE];
        outl1+=vl*w
        outr1+=vr*w
      outl = lerp(outl0, outl1, @read_frac)
      outr = lerp(outr0, outr1, @read_frac)
      buffer[(s * 2) + offset] = vm0 * outl + vm1 * outr
      buffer[(s * 2) + offset + 1] = vm1 * outl + vm0 * outr

      @read_frac += step
      rfi = Math.floor(@read_frac)
      @read_pos = (@read_pos + rfi) & (@RBSIZE - 1)
      @read_frac -= rfi


class Player

  constructor: (@module) ->
    #console.log(@module)
    @channels = []
    for i in [0..3]
      @channels.push(new Channel(this))
      
    @mixer = new Mixer()
    @calc_ptable()
    @calc_vibtable()
    @reset()


  BASE_PTABLE: [
    0, 1712,1616,1525,1440,1357,1281,1209,1141,1077,1017, 961, 907,
    856, 808, 762, 720, 678, 640, 604, 570, 538, 508, 480, 453,
    428, 404, 381, 360, 339, 320, 302, 285, 269, 254, 240, 226,
    214, 202, 190, 180, 170, 160, 151, 143, 135, 127, 120, 113,
    107, 101,  95,  90,  85,  80,  76,  71,  67,  64,  60,  57]
  OUTRATE: 44100
  OUTFPS: 50

  channels: []
  
  speed: 0
  tick_rate: 0
  tr_counter: 0
  cur_tick: 0
  cur_row: 0
  cur_pos: 0
  delay: 0


  play: ->
    @soundbridge = SoundBridge(2, 44100, '/javascripts/vendor/');
    window.setTimeout(
      =>
        @soundbridge.setCallback(@soundbridge_render)
        @soundbridge.play()
      1000
    )

  stop: ->
    @soundbridge.stop()

  soundbridge_render: (bridge, length, channels) =>
    
    buffer = new Float32Array(length * 2);
    @render(buffer, length);
    for i in [0...length]
      bridge.addToBuffer(buffer[i*2], buffer[i*2 + 1]);

  calc_ptable: ->
    @PTABLE = []
    for ft in [0..16]
      rft = -(if ft >= 8 then ft - 16 else ft)
      
      #console.log rft 
      fac = Math.pow(2.0, rft / (12.0 * 16.0))
      console.log(fac)
      periods = []
      for i in [0..59]
        periods.push(Math.round(@BASE_PTABLE[i] * fac * 0.5))
      @PTABLE.push(periods)
    console.log(@PTABLE)  
  
  calc_vibtable: ->
    @VIB_TABLE = []
    for i in [0..2]
      @VIB_TABLE.push([])
    
    for ampl in [0..14]
      scale = ampl + 1.5
      shift = 0
      @VIB_TABLE[0][ampl] = []
      @VIB_TABLE[1][ampl] = []
      @VIB_TABLE[2][ampl] = []
      for x in [0..63]
        @VIB_TABLE[0][ampl].push(Math.floor(scale * Math.sin(x * Math.PI / 32.0) + shift))
        @VIB_TABLE[1][ampl].push(Math.floor(scale * ((63-x)/31.5-1.0) + shift))
        @VIB_TABLE[2][ampl].push(Math.floor(scale * (if (x<32) then 1 else -1) + shift))

  calc_tick_rate: (bpm) ->
    @tick_rate = (125 * @OUTRATE) / (bpm * @OUTFPS)
    #console.log("TICK RATE", @tick_rate)

  trig_note: (ch, note) ->
    channel = @channels[ch]
    voice = @mixer.voices[ch]
    sample = @module.samples[channel.sample - 1]
    offset = 0
    offset = channel.fxbuf[9] << 8 if note.command == 9      
    if note.command != 3 && note.command != 5
      channel.set_period()
      if sample.replen > 2
        voice.trigger(sample.data, sample.repeat + sample.replen, sample.replen, offset)
      else
        voice.trigger(sample.data, sample.length, 1, offset)
        
      channel.vib_pos = 0 if !channel.vib_retr   
      channel.trem_pos = 0 if !channel.trem_retr

  reset: ->
    @calc_tick_rate(125)
    @speed = 6
    @tr_counter = 0
    @cur_tick = 0
    @cur_row = 0
    @cur_pos = 0
    @delay = 0

  tick: ->
    line = @module.patterns[@cur_pos][@cur_row]
    ch = 0
    for note in line
      voice = @mixer.voices[ch]
      channel = @channels[ch]
      fxpl = note.command_params & 0x0F
      trem_vol = 0
      if (!@cur_tick)
        if note.sample
          channel.sample = note.sample
          channel.finetune = @module.samples[note.sample - 1].finetune
          channel.volume = @module.samples[note.sample - 1].volume
        if note.command_params
          channel.fxbuf[note.command] = note.command_params

        if note.note && (note.command != 14 || ((note.command_params >> 4) != 13))
          
          channel.note = note.note
          @trig_note(ch, note)
        
        switch(note.command)
          when 4, 6
            channel.vib_ampl = channel.fxbuf[4] & 0x0f if channel.fxbuf[4] & 0x0f 
            channel.vib_speed = channel.fxbuf[4] >> 4 if channel.fxbuf[4] & 0xf0
            channel.set_period(0, @VIB_TABLE[channel.vib_wave][channel.vib_ampl - 1][channel.vib_pos])
          when 7
            channel.trem_ampl = channel.fxbuf[7] & 0x0f if channel.fxbuf[7] & 0x0f 
            channel.trem_speed = channel.fxbuf[7] >> 4 if channel.fxbuf[7] & 0xf0
            trem_vol = @VIB_TABLE[channel.trem_wave][channel.trem_ampl - 1][channel.trem_pos]
          when 12
            channel.volume = clamp(note.command_params, 0, 64)
          when 14
            channel.fxbuf_14[note.command_params >> 4] = fxpl if fxpl
            switch (note.command_params >> 4)
              when 1
                channel.period = Math.max(113, channel.period - channel.fxbuf_14[1])
              when 2
                channel.period = Math.min(856, channel.period + channel.fxbuf_14[1])
              when 4
                channel.vib_wave = fxpl & 3
                channel.vib_wave = 0 if channel.vib_wave == 3
                channel.vib_retr = fxpl & 4
              when 5
                channel.finetune = fxpl
                channel.finetune -= 16 if channel.finetune >= 8
              when 7
                channel.trem_wave = fxpl & 3
                channel.trem_wave = 0 if channel.trem_wave == 3
                channel.trem_retr = fxpl & 4
              when 9
                if channel.fxbuf_14[9] && !note.note
                  @trig_note(ch, note)
                  channel.retrig_count = 0
              when 10
                channel.volume = Math.min(channel.volume + channel.fxbuf_14[10], 64)
              when 11
                channel.volume = Math.max(channel.volume - channel.fxbuf_14[11], 0)
              when 14
                @delay = channel.fxbuf_14[14]
          when 15
            if note.command_params
              if note.command_params <= 32
                @speed = note.command_params
              else
                @calc_tick_rate(note.command_params)

      else
        switch(note.command)
          when 0
            if note.command_params
              arp_no = 0
              switch(@cur_tick % 3)
                when 1
                  arp_no = note.command_params >> 4
                when 2
                  arp_no = note.command_params & 0x0F
              channel.set_period(arp_no)
          when 1
            channel.period = Math.max(113, channel.period - channel.fxbuf[1])
          when 2
            channel.period = Math.min(856, channel.period + channel.fxbuf[2])
          when 5
            if channel.fxbuf[5] & 0xF0
              channel.volume = Math.min(channel.volume + (channel.fxbuf[5] >> 4), 64)
            else
              channel.volume = Math.max(channel.volume - (channel.fxbuf[5] & 0x0f), 0)
          when 5, 3
            np = channel.get_period
            if channel.period > np
              channel.period = Math.max(channel.period - channel.fxbuf[3], np)
            else if channel.period < np
              channel.period = Math.min(channel.period + channel.fxbuf[3], np)

          when 6
            if channel.fxbuf[6] & 0xF0
              channel.volume = Math.min(channel.volume + (channel.fxbuf[6] >> 4), 64)
            else
              channel.volume = Math.max(channel.volume - (channel.fxbuf[6] & 0x0F), 0)
          when 4, 6
            channel.set_period(0, @VIB_TABLE[channel.vib_wave][channel.vib_ampl - 1][channel.vib_pos])
            channel.vib_pos = (channel.vib_pos + channel.vib_speed) & 0x3f
          when 7
            @trem_vol = @VIB_TABLE[channel.trem_wave][channel.trem_ampl][channel.trem_pos]
            channel.trem_pos = (channel.trem_pos + c.trem_speed) & 0x3f
          when 10
            if channel.fxbuf[10] & 0xF0
              channel.volume = Math.min(channel.volume + (channel.fxbuf[10] >> 4), 64)
            else
              channel.volume = Math.max(channel.volume - (channel.fxbuf[10] & 0x0f), 0)
          when 11
            if @cur_tick == @speed - 1
              @cur_row -= 1
              @cur_pos = note.command_params
          when 13
            if @cur_tick = @speed - 1
              @cur_pos++
              @cur_row = (10 * (note.command_params >> 4) + (note.command_params & 0x0f)) - 1
          when 14
            switch (note.command_params >> 4)
              when 6
                if !fxpl
                  channel.loopstart = @cur_row
                else if (@cur_tick == @speed - 1)
                  if (channel.loopcount < fxpl)
                    @cur_row = channel.loopstart -1
                    channel.loopcount++
                  else
                    channel.loopcount = 0
              when 9
                channel.retrig_count++
                if (channel.retrig_count == channel.fxbuf_14[9])
                  channel.retrig_count = 0
                  @trig_note(ch, note)
              when 12
                if @cur_tick == channel.fxbuf_14[12]
                  channel.volume = 0
              when 13
                @trig_note(ch, note) if @cur_tick == channel.fxbuf_14[13]

      voice.volume = clamp(channel.volume + trem_vol, 0, 64)
      voice.period = channel.period

      ch++

    @cur_tick++
    if @cur_tick >= @speed * (@delay + 1)
      @cur_tick = 0
      @cur_row++
      @delay = 0

    if @cur_row >= 64
      @cur_row = 0
      @cur_pos++

    @cur_pos = 0 if @cur_pos >= @module.pattern_table_length

  render: (buffer, len) ->
    offset = 0
    #console.log("player.render", buffer, len)
    while (len > 0)      
      todo = Math.min(len, @tr_counter)      
      if todo
        @mixer.render(buffer, offset, todo)
        offset += todo * 2
        len -= todo
        @tr_counter -= todo
      else
        @tick()
        @tr_counter = @tick_rate
    #console.log("player.render.done")



class Channel
  note: 0
  period: 0
  sample: 0
  finetune: 0
  volume: 0
  fxbuf: new Int16Array(16)
  fxbuf_14: new Int16Array(16)
  loopstart: 0
  loopcount: 0
  retrig_count: 0
  vib_wave: 0
  vib_retr: 0
  vib_pos: 0
  vib_ampl: 0
  vib_speed: 0
  trem_wave: 0
  trem_retr: 0
  trem_pos: 0
  trem_ampl: 0
  trem_speed: 0

  constructor: (@player) ->

  get_period: (offs = 0, fineoffs = 0) ->
    ft = @finetune + fineoffs
    while ft > 7
      offs++
      ft -= 16
    while ft < -8
      offs--
      ft += 16
    if @note
      @player.PTABLE[ ft & 0x0f ][clamp(@note+offs-1,0,59)]
    else
      0
  set_period: (offs = 0, fineoffs = 0) ->
    if @note
      @period = @get_period(offs, fineoffs)






jQuery ->
  window.App.trackerView = new window.App.views.TrackerView()
  $('#trackerpane').append(window.App.trackerView.render().el)
  # window.App.trackerView.updateTablePlacement()
  $(window).keyup(window.App.trackerView.keyup_handler)

  $('#modfile').bind 'change', (e) -> 
    console.log(e, this);
    file = $(this).get(0).files[0]
    fr = new FileReader()
    fr.onerror = (e) -> 
      console.log(fr.error)
    fr.onloadend = (e) ->
      console.log(e)
      module = new Mod(fr.result);
      console.log(module)
      window.Player = new Player(module);
      # App.trackerView.set_data(modLoader(fr.result))
      # App.trackerView.update()

    fr.readAsArrayBuffer(file);



