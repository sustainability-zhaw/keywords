library (plumber)

#* @get /hello
function() {
    return("Hello World")
}

#* @get /config
function() {
  return("config")
}

#* @get /wd
function(wd = wd) {
  return(wd)
}