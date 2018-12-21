using Toybox.System;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Time;
using Toybox.Activity;
using Toybox.ActivityMonitor;
using Toybox.System;
using Toybox.Timer;
using Toybox.Time;
using Toybox.Application;
using Toybox.Time.Gregorian;

class SundialView extends WatchUi.WatchFace {
	
	// display properties
	var centerX, centerY, radius;
	var suntime;
	var lat, lon;
	
	var hooge55, hooge20, hooge15, hooge10;
	
    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
    	hooge55 = WatchUi.loadResource(Rez.Fonts.hooge55);
    	hooge20 = WatchUi.loadResource(Rez.Fonts.hooge20);
    	hooge15 = WatchUi.loadResource(Rez.Fonts.hooge15);
    	hooge10 = WatchUi.loadResource(Rez.Fonts.hooge10);
        self.centerX = dc.getWidth() / 2;
    	self.centerY = dc.getHeight() / 2;
    	self.radius = self.centerX < self.centerY ? self.centerX : self.centerY;
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        
        // clear the display
 		dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
		dc.clear();
        
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
        dc.setPenWidth(5);
        //dc.drawArc(self.centerX, self.centerY, 120, dc.ARC_CLOCKWISE, 0, 90);
        

		var info = Activity.getActivityInfo();
		if (info.currentLocation != null) {
			Application.getApp().setProperty("location", [info.currentLocation.toDegrees()[0], info.currentLocation.toDegrees()[1]]);
		}
		drawSun(dc, self.centerX, self.centerY, 120, Time.now(), Application.getApp().getProperty("location"), 0);
		
		// draw the watch components
        drawTicks(dc, self.centerX, self.centerY, self.radius, hooge20, hooge10);

		var fontHeight = Graphics.getFontHeight(hooge55);	
		var fontHeight20 = Graphics.getFontHeight(hooge20);	
		var today = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
		
		//System.println("Moontimes" + getMoonTimes(Time.now(),28.474388, 77.503990));

		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.drawText(self.centerX, self.centerY - (fontHeight / 2) - fontHeight20, hooge20,
				Lang.format("$1$ $2$", [today.day_of_week.substring(0,3), today.day]), Graphics.TEXT_JUSTIFY_CENTER);
		
		dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
		dc.drawText(self.centerX + 2, self.centerY - (fontHeight / 2) + 2, hooge55,
				Lang.format("$1$:$2$", [today.hour.format("%02i"), today.min.format("%02i")]), Graphics.TEXT_JUSTIFY_CENTER);
		
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.drawText(self.centerX, self.centerY - (fontHeight / 2), hooge55,
				Lang.format("$1$:$2$", [today.hour.format("%02i"), today.min.format("%02i")]), Graphics.TEXT_JUSTIFY_CENTER);
		
		var infoText = "";
		infoText = infoText + "HR";
		if (info.currentHeartRate != null) {
			infoText = infoText + info.currentHeartRate + " ";
		}
		
		infoText = infoText + "   AL";
		if (info.altitude != null) {
			infoText = infoText + info.altitude.toLong() + " ";
		}
		
		dc.drawText(self.centerX, self.centerY + (fontHeight / 2) - 5, hooge15,
				Lang.format("$1$", [infoText]), Graphics.TEXT_JUSTIFY_CENTER);
				
		dc.drawLine(self.centerX - 50, self.centerY + (fontHeight / 2) + 10 + 5, self.centerX + 50, self.centerY + (fontHeight / 2) + 10 + 5);
		dc.drawLine(self.centerX - 30, self.centerY + (fontHeight / 2) + 15 + 5, self.centerX + 30, self.centerY + (fontHeight / 2) + 15 + 5);
		dc.drawLine(self.centerX - 15, self.centerY + (fontHeight / 2) + 20 + 5, self.centerX + 15, self.centerY + (fontHeight / 2) + 20 + 5);
		
		drawTriangle (dc, self.centerX, self.centerY, self.radius);	

    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    	WatchUi.requestUpdate();
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    	WatchUi.requestUpdate();
    }

}
