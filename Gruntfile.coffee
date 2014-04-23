# inspired by http://www.thomasboyt.com/2013/09/01/maintainable-grunt.html

fs = require('fs')
loadConfig = (path, grunt) ->
  object = {}
  fs.readdirSync(path).forEach (option) ->
    key = option.replace(/\.coffee$/,'')
    config = require(path + option)
    if 'function' is typeof config
      object[key] = config grunt
    else
      object[key] = config
  return object

module.exports = (grunt) ->

  baseConfig =
    pkg: grunt.file.readJSON 'package.json'
    env: process.env

  config = grunt.util._.extend baseConfig, loadConfig './tasks/options/', grunt

  grunt.initConfig config
  
  require('load-grunt-tasks')(grunt)
  grunt.loadTasks('tasks')
