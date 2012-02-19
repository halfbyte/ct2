describe 'Player', ->
  beforeEach ->
    window.SoundBridge = -> 'mockSoundBridge'

  it 'loads a file', ->
    expect(Player.load('file.mod')).toEqual('LOADING file.mod')

  it 'works', ->
    expect(Player.play()).toEqual('PLAYING')
