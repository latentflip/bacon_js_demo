(function() {

  $(document).ready(function() {
    var $bacon, alert, angle, angleRatio, angleRatioSmooth, doc, f, motionStream, position, resizeStream;
    if (!window.DeviceOrientationEvent) {
      alert = $('<h4>').text("Your browser doesn't seem to support DeviceOrientationEvent, try Chrome");
      alert.insertAfter("h3");
    }
    f = {
      sum: function(a, b) {
        return a + b;
      },
      multiply: function(a, b) {
        return a * b;
      },
      average: function(ns) {
        return _.inject(ns, f.sum, 0) / (ns.length || 1);
      },
      floor: function(n) {
        return Math.floor(n);
      }
    };
    doc = {
      getHeight: function() {
        return $(window).height();
      },
      getWidth: function() {
        return $(window).width();
      }
    };
    resizeStream = $(window).asEventStream("resize");
    doc.size = {
      width: resizeStream.map(doc.getWidth).toProperty(doc.getWidth()),
      height: resizeStream.map(doc.getHeight).toProperty(doc.getHeight())
    };
    motionStream = $(window).asEventStream("deviceorientation");
    angle = {
      lr: motionStream.map('.originalEvent.gamma'),
      ud: motionStream.map('.originalEvent.beta')
    };
    angleRatio = {
      lr: angle.lr.map(function(v) {
        return (v + 90) / 180;
      }),
      ud: angle.ud.map(function(v) {
        return (v + 90) / 180;
      })
    };
    angleRatioSmooth = {
      lr: angleRatio.lr.slidingWindow(5).map(f.average),
      ud: angleRatio.ud.slidingWindow(5).map(f.average)
    };
    position = {
      lr: doc.size.width.combine(angleRatioSmooth.lr, f.multiply).map(f.floor),
      ud: doc.size.height.combine(angleRatioSmooth.ud, f.multiply).map(f.floor)
    };
    $bacon = $('.bacon');
    position.ud.assign($bacon, 'css', 'top');
    return position.lr.assign($bacon, 'css', 'left');
  });

}).call(this);
