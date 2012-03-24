# helpers for 
Handlebars.registerHelper 'hiNyb', (obj) ->
  ((obj >> 4) & 0xF).toString(16).toUpperCase()

Handlebars.registerHelper 'loNyb', (obj) ->
  (obj & 0xF).toString(16).toUpperCase()
