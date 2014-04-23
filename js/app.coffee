class Vector 
  constructor: (x, y) ->
    @x = x
    @y = y
    return

  plus: (other) ->
    new Vector(@x + other.x, @y + other.y)
  minus: (other) ->
    new Vector(@x - other.x, @y - other.y)
  mult: (other) ->
    new Vector(@x*other.x, @y*other.y)
  dot: (other) ->
    return @x*other.x+@y*other.y
  scale: (by_) ->
    new Vector(@x * by_, @y * by_)
  length: ->
    return Math.sqrt(@x*@x+@y*@y)
  normalize: ->
    length = @length()
    new Vector(@x/length, @y/length)

gravity = new Vector(0, 9.81)
ball_speed = 0.4
max_angle = 3.14/3
interval = 10
paddle_offset = 30
paddle_width = 100
ball_radius = 5
drop_chance = 0.2

class Ball 
  constructor: (x,y,dx,dy) ->
    @handle = $("<div>").addClass("ball").appendTo("#canvas")
    @setPosition(x,y)
    @setRadius(ball_radius)
    @velocity = new Vector(dx,dy)
    @velocity = @velocity.normalize().scale(ball_speed)
    return

  remove: ->
    @handle.remove()
    return

  setPosition: (x,y) ->
    @position = new Vector(x,y)
    @handle.css
      top: y-@radius
      left: x-@radius

  setRadius: (radius) ->
    @radius = radius
    @handle.css
      width: @radius*2
      height: @radius*2
      "border-radius": @radius

  setSpeed: (speed) ->
    @velocity = @velocity.normalize().scale(speed)

  remove: ->
    @handle.remove()

  move: (ms, game, id) ->
    # update position
    @position = @position.plus(@velocity)

    # collision detection against world
    #top
    if @position.y <= @radius 
      @velocity.y = Math.abs(@velocity.y)
    #bottom
    else if @position.y >= game.world.y2 - @radius
      game.removeBall(id)
      @velocity.y = -Math.abs(@velocity.y);
    #left
    if @position.x <= @radius 
      @velocity.x = Math.abs(@velocity.x);
    #right
    else if @position.x >= game.world.x2 - @radius
      @velocity.x = -Math.abs(@velocity.x);

    #collision detection against bricks
    game.bricks.forEach (brick, bid) =>
      left = brick.position.x - brick.size.x/2
      right = brick.position.x + brick.size.x/2
      top = brick.position.y - brick.size.y/2
      bottom = brick.position.y + brick.size.y/2
      pt = new Vector(@position.x, @position.y)
      change = new Vector(1,1)
      if pt.x > right 
        pt.x = right
        change.x = -1
      if pt.x < left
        pt.x = left
        change.x = -1
      if pt.y > bottom
        pt.y = bottom
        change.y = -1
      if pt.y < top
        pt.y = top
        change.y = -1
      pt = @position.minus(pt)
      if pt.length() < @radius
        @velocity = @velocity.mult(change)
        @position = @position.plus(@velocity)
        game.removeBrick(bid)

    #collision detection against paddle
    if @position.y+@radius >= game.paddle.position.y# - game.paddle.size.y / 2
      paddle_left = game.paddle.position.x - game.paddle.size.x / 2
      paddle_right = game.paddle.position.x + game.paddle.size.x / 2
      if @position.x >= paddle_left and @position.x <= paddle_right
        
        hit = @position.x - paddle_left - game.paddle.size.x / 2
        hit = hit / (game.paddle.size.x / 2) * max_angle
        
        @velocity.y = ball_speed*Math.cos(hit)
        @velocity.x = ball_speed*Math.sin(hit)
        if @velocity.y > 0
          @velocity.y = -@velocity.y
        #balls.push new Ball()

    @velocity = @velocity.normalize().scale(ball_speed*ms)
    # render
    @handle.css
      left: @position.x-@radius
      top: @position.y-@radius
    return

class Paddle
  constructor: (game) ->
    @size = new Vector(paddle_width,20)
    @handle = $("<div>").addClass("paddle").appendTo("#canvas")
    @setPosition(game.world.x2/2-@size.x/2, game.world.y2-paddle_offset)
    @handle.css
      width: @size.x
      height: @size.y
    return
  setPosition: (x,y) ->
    @position = new Vector(x,y)
    @handle.css
      left: @position.x
      top: @position.y

  setLength: (x) ->
    @size.x = x
    @handle.css
      width: x

  move: (to) ->
    @handle.css
      left: to-@size.x/2
    @position.x = to

class Brick
  constructor: (x,y,id) ->
    @id = id
    @position = new Vector(x,y)
    @size = new Vector(80,20)
    @handle = $("<div>").addClass("brick").appendTo("#canvas")
    @handle.css
      width: @size.x
      height: @size.y
      left: @position.x-@size.x/2
      top: @position.y-@size.y/2

  remove: ->
    @handle.remove()

class Bonus
  constructor: (x,y) ->
    @position = new Vector(x,y)
    @velocity = new Vector(0, -1.0)
    @handle = $("<div>").addClass("bonus").appendTo("#canvas")
    @handle.css
      left: @position.x
      top: @position.y

  move: (ms, game, id) ->
    @velocity = @velocity.plus(gravity.scale(0.01))
    @position = @position.plus(@velocity)
    @handle.css
      top: @position.y

    if @position.y >= game.paddle.position.y
      if @position.x >= game.paddle.position.x - game.paddle.size.x / 2 and @position.x <= game.paddle.position.x + game.paddle.size.x / 2
        game.eatBonus(id)
      else
        game.removeBonus(id)

    return
  remove: ->
    @handle.remove()

class Game
  constructor: ->
    @running = false
    @canvas = $("#canvas")
    @world =
      x1: 0
      y1: 0
      x2: 500
      y2: 300
    @redraw()
    @lastTime = new Date()
    @balls = []
    @bricks = []
    @bonuses = []
    @paddle = new Paddle(this)
    @balls.push new Ball(@paddle.position.x, @paddle.position.y-@paddle.size.y, 2, -5)

    for i in [0..5]
      for j in [0..5]
        @bricks.push new Brick(83*i+42, 22*j+24)

    $(document).mousemove (event) => 
      @paddle.move(event.pageX-@canvas.offset().left)
      if(!@running)
        @balls.forEach (ball) =>
          ball.setPosition(event.pageX+10-@canvas.offset().left, @paddle.position.y-@paddle.size.y/2+ball_radius)
          return

    $(window).resize(=>
      @redraw()
      @paddle.setPosition(@paddle.position.x, @world.y2-paddle_offset)
      return
    )

  dropBonus: (x,y) ->
    @bonuses.push new Bonus(x,y)

  removeBonus: (id) ->
    @bonuses[id].remove()
    @bonuses.splice(id,1)

  eatBonus: (id) ->
    @removeBonus(id)
    r = parseInt(Math.random()*5)
    switch r
      when 0 then @paddle.setLength(@paddle.size.x+10)
      when 1 then @paddle.setLength(@paddle.size.x-10)
      when 2 then ball_speed += .1
      when 3 then ball_speed -= .1
      when 4
        @balls.forEach (ball) =>
          @balls.push new Ball(ball.position.x, ball.position.y, -ball.velocity.x, ball.velocity.y)
    return

  removeBrick: (id) ->
    if Math.random() < drop_chance
      @dropBonus(@bricks[id].position.x, @bricks[id].position.y)
    @bricks[id].remove()
    @bricks.splice(id,1)
    if(@bricks.length == 0)
      game.stop()
      alert("YOU WIN")

  removeBall: (id) ->
    @balls[id].remove()
    @balls.splice(id,1)
    
  redraw: ->
    @canvas.css
      width: @world.x2
      height: @world.y2
      left: $(document).width()/2-@world.x2/2

  start: ->
    @running = true

    @lastTime = new Date()
    @loop = setInterval (=>

      currTime = new Date()
      milis = currTime.getTime() - @lastTime.getTime();
      @lastTime = currTime

      @balls.forEach (ball, id) =>
        ball.move(milis, this, id)
        return
      @bonuses.forEach (bonus, id) =>
        bonus.move(milis, this, id)
        return
      if @balls.length == 0
        @stop()
        alert("YOU LOSE")

      return
    ), interval

  stop: ->
    @running = false
    window.clearInterval(@loop)
    return

game = new Game()

$(document).on("click","#canvas", =>
  if(!game.running)
    game.start()
)
