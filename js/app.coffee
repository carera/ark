class Vector 
  constructor: (@x, @y) ->

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

gravity = new Vector(0, 3)
min_speed =      0.4
max_speed =      0.8
ball_speed =     0.4
paddle_max_size = 250
paddle_min_size = 50
max_angle =      3.14/3
interval =       5
paddle_offset =  30
paddle_width =   100
ball_radius =    6
min_ball_radius = 3
max_ball_radius = 12
drop_chance =    1
text_life =      2000

class Entity
  constructor: (x=0, y=0, dx=0, dy=0) ->
    @handle = $("<div>").appendTo("#canvas")
    @setPosition(new Vector(x,y))
    @velocity = new Vector(dx,dy)
    @birth = new Date().getTime()

  setPosition: (@position) ->
    @handle.css
      left: @position.x
      top: @position.y

  remove: ->
    @handle.remove()

  move: ->
    newPos = @position.plus(@velocity)
    @setPosition(newPos)


class Ball extends Entity 
  constructor: (x,y,dx,dy) ->
    super(x,y,dx,dy)
    @setRadius(ball_radius)
    @handle.addClass("ball")
    @velocity = @velocity.normalize().scale(ball_speed)

  setPosition: (@position) ->
    @handle.css
      top: @position.y-@radius
      left: @position.x-@radius

  setRadius: (@radius) ->
    @handle.css
      width: @radius*2
      height: @radius*2
      "border-radius": @radius

  setSpeed: (speed) ->
    @velocity = @velocity.normalize().scale(speed)

  move: (ms, game, id) ->    
    # collision detection against world
    #top
    if @position.y <= @radius 
      @velocity.y = Math.abs(@velocity.y)
    #bottom
    else if @position.y >= game.world.y2 - @radius
      if game.immune
        @velocity.y = -Math.abs(@velocity.y);
      else
        game.removeBall(id)
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
      else if pt.x < left
        pt.x = left
        change.x = -1
      if pt.y > bottom
        pt.y = bottom
        change.y = -1
      else if pt.y < top
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
    super

class Paddle extends Entity
  constructor: (game) ->
    @size = new Vector(paddle_width,20)
    super(game.world.x2/2-@size.x/2, game.world.y2-paddle_offset)
    @handle.addClass("paddle")
    @handle.css
      width: @size.x
      height: @size.y

  setLength: (x) ->
    x = if x > paddle_max_size then paddle_max_size else x
    x = if x < paddle_min_size then paddle_min_size else x
    @size.x = x
    @handle.css
      width: x

  move: (to) ->
    @handle.css
      left: to-@size.x/2
    @position.x = to

class Brick extends Entity

  constructor: (x,y) ->
    super(x,y)
    @size = new Vector(80,20)
    @handle.addClass("brick")
    @handle.css
      width: @size.x
      height: @size.y
      left: @position.x-@size.x/2
      top: @position.y-@size.y/2

class Bonus extends Entity

  constructor: (x,y) ->
    super(x,y,0,-0.5)
    @handle.addClass("bonus")

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

class Text extends Entity
  constructor: (x,y,@text) ->
    super(x,y,0,-.1)
    @handle.addClass("bonus_text").html(@text).fadeOut(text_life)

class Game
  constructor: ->
    @immune = false
    @running = false
    @canvas = $("#canvas")
    @world =
      x1: 0
      y1: 0
      x2: 740
      y2: 500
    @redraw()
    @lastTime = new Date()
    @balls = []
    @bricks = []
    @bonuses = []
    @bonus_texts = []
    @paddle = new Paddle(this)
    @balls.push new Ball(@paddle.position.x, @paddle.position.y-@paddle.size.y, 2, -5)

    for i in [0..8]
      for j in [0..10]
        @bricks.push new Brick(82*i+42, 22*j+12)

    $(document).mousemove (event) => 
      @paddle.move(event.pageX-@canvas.offset().left)
      if(!@running)
        @balls.forEach (ball) =>
          pos = new Vector(event.pageX+10-@canvas.offset().left, @paddle.position.y-ball_radius)
          ball.setPosition(pos)
          return

    $(window).resize(=>
      @redraw()
      @paddle.setPosition(@paddle.position.x, @world.y2-paddle_offset)
    )

  dropBonus: (x,y) ->
    @bonuses.push new Bonus(x,y)

  removeBonus: (id) ->
    @bonuses[id].remove()
    @bonuses.splice(id,1)

  eatBonus: (id) ->
    @removeBonus(id)
    r = parseInt(Math.random()*8)
    switch r
      when 0 
        @paddle.setLength(@paddle.size.x+10)
        msg = "+ paddle size"
      when 1 
        @paddle.setLength(@paddle.size.x-10)
        msg = "- paddle size"
      when 2 
        ball_speed = if ball_speed < max_speed then ball_speed + 0.1 else ball_speed
        msg = "+ ball speed"
      when 3 
        ball_speed = if ball_speed > min_speed then ball_speed - 0.1 else ball_speed
        msg = "- ball speed"
      when 4
        @balls.forEach (ball) =>
          @balls.push new Ball(ball.position.x, ball.position.y, -ball.velocity.x, -Math.abs(ball.velocity.y))
        msg = "double ball"
      when 5
        ball_radius += 2
        ball_radius = if ball_radius > max_ball_radius then max_ball_radius else ball_radius
        @balls.forEach (ball) =>
          ball.setRadius(ball_radius)
        msg = "+ ball size"
      when 6
        ball_radius -= 2
        ball_radius = if ball_radius < min_ball_radius then min_ball_radius else ball_radius
        @balls.forEach (ball) =>
          ball.setRadius(ball_radius)
        msg = "- ball size"
      when 7
        @immune = true
        @canvas.css
          "border-bottom": "3px solid blue"
        msg = "shield"
        setTimeout (=>
          @immune = false
          @canvas.css
            "border-bottom": "1px solid grey"
        ), 6000
    @bonus_texts.push new Text(@paddle.position.x,@paddle.position.y-30,msg)

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

      curTime = new Date()
      milis = curTime.getTime() - @lastTime.getTime();
      @lastTime = curTime

      @balls.forEach (ball, id) =>
        ball.move(milis, this, id)
      @bonuses.forEach (bonus, id) =>
        bonus.move(milis, this, id)
      @bonus_texts.forEach (text, id) =>
        text.move()
        if(new Date().getTime() - text.birth > text_life)
          text.remove()
          @bonus_texts.splice(id,1)
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

$(document).on("keypress","#canvas", =>
  if(game.running)
    game.stop()
)
