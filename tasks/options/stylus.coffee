module.exports =
  options:
    'include css': true
    'compress': false
  all:
    files: [
      expand: true
      src: [
        'css/**/*.styl'
      ]
      ext: '.css'
    ]
