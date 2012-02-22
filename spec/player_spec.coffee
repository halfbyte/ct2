# @codekit-prepend "../coffeescript/player.coffee"

describe 'Player', ->
  beforeEach ->
    window.SoundBridge = -> 'mockSoundBridge'
    window.Player = new Player();

  it 'loads a file', ->
    expect(window.Player.load('file.mod')).toEqual('LOADING file.mod')

  it 'works', ->
    expect(window.Player.play()).toEqual('PLAYING')
