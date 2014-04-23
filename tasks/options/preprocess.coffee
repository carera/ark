module.exports =
  build:
    src: [
      'html/index.html'
    ]
    options:
      inline: true
      context:
        DEBUG: false
        PRODUCTION: true
