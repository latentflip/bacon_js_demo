$(document).ready ->
  if !window.DeviceOrientationEvent
    alert = $('<h4>').text("Your browser doesn't seem to support DeviceOrientationEvent, try Chrome")
    alert.insertAfter("h3")

  #### Utlity functions
  # These just make the resulting stream code more readable
  f =
    sum: (a,b) -> a + b
    multiply: (a,b) -> a * b
    average: (ns) -> _.inject(ns, f.sum, 0) / (ns.length||1)
    floor: (n) -> Math.floor(n)

  # Get the height/width of the document
  doc =
    getHeight: -> $(window).height()
    getWidth: -> $(window).width()


  #### Streams
  
  # Get window resize events as a stream
  resizeStream = $(window).asEventStream("resize")
    
  # Creates Bacon properties for the current doc width and height
  #
  # - for each resize event, use our getWidth/Height functions to return the current width/height
  # - then convert to a property, starting with the current width/height
  doc.size =
      width: resizeStream.map( doc.getWidth ).toProperty( doc.getWidth() )
      height: resizeStream.map( doc.getHeight ).toProperty( doc.getHeight() )

  # Use the HTML5 "deviceorientation" event as a stream
  motionStream = $(window).asEventStream("deviceorientation")
  
  # Create new streams from the motionStream by pulling out the gamma (left-right angle) and beta (up-down angle) from the original deviceorientation event (see: http://www.html5rocks.com/en/tutorials/device/orientation/)
  angle =
    lr: motionStream.map '.originalEvent.gamma'
    ud: motionStream.map '.originalEvent.beta'

  # Normalize the angle streams from -90 -> 90, to 0 -> 1
  angleRatio = 
    lr: angle.lr.map (v) -> ((v + 90) / 180)
    ud: angle.ud.map (v) -> ((v + 90) / 180)

  # Average the last 5 angles to smooth everything out a bit
  #
  # This uses slidingWindow which creates a stream whose values are an array of the last 5 values of the angleRatio streams, and then averages them back down to a single value (an unweighted moving average)
  angleRatioSmooth = 
    lr: angleRatio.lr.slidingWindow(5).map(f.average)
    ud: angleRatio.ud.slidingWindow(5).map(f.average)

  # Combine the current document size, with the current smoothed and normalized device angle to the ball's position
  #
  # Combine is great. It takes the current value of the doc.width property and the latest value of the angleRationSmooth stream, passing it to our f.multiply function. This creates a new stream of the two multiplied together
  #
  # Then we are flooring them so that we don't get pixel rendering issues
  position = 
    lr: doc.size.width.combine(angleRatioSmooth.lr, f.multiply)
                        .map(f.floor)
    ud: doc.size.height.combine(angleRatioSmooth.ud, f.multiply)
                        .map(f.floor)
  
  # Assign the position to the bacon
  #
  # Every time either of our position streams updates, the bacon's appopriate css value will get updated
  $bacon = $('.bacon')
  position.ud.assign $bacon, 'css', 'top'
  position.lr.assign $bacon, 'css', 'left'
