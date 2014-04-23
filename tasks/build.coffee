module.exports = (grunt) ->
  grunt.registerTask 'build', [
    'clean'

    # compile stylus + coffee
    'compile'

    # remove unused css rules
    #'uncss'

    # detect scripts and styles in html file, prepare it for concatenation
    'useminPrepare'

    # minify both css and js
    # these tasks are configured by usemin and cannot be executed standalone
    # i. e. the `grunt cssmin` and `grunt uglify` commands are not available
    'concat'
    'cssmin'
    'uglify'

    # remove dev scripts from html
    'preprocess'

    # rewrite paths in the html file
    'usemin'

    # minify html
    'htmlmin'

    # delete temporary files (optional)
    'clean:temp'
  ]
