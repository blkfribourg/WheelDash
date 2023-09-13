import Toybox.WatchUi;
import Toybox.System;

class BackgroundRenderer extends WatchUi.Drawable {
  private var bg;
  function initialize(params) {
    Drawable.initialize(params);
    bg = Application.loadResource(Rez.Drawables.BackgroundImg);
  }

  function draw(dc) {
    dc.setColor(0x000000, 0x000000);

    // dc.fillRectangle(0, 0, System.getDeviceSettings().screenWidth, System.getDeviceSettings().screenHeight);
    dc.drawBitmap(0, 0, bg);
  }
}
