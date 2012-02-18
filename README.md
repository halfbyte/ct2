# What this is

You know if you know. 

# Setup

This currently needs two things to properly work (exept that it doesn't really work at all):

* CodeKit as a means of compilation. If you add the project to CodeKit, everything should work accordingly, apart from a LOT of jshint errors, I guess.
* A webserver to serve that stuff. I currently use the follwing line in my shrc and start it with $ webserver in the current dir
  
  alias webserver="python -m SimpleHTTPServer"

You can find the original C++ code of Tammos player in c-src

The best description of the MOD file format is here: http://www.mediatel.lu/workshop/audio/fileformat/h_mod.html
