// draw the minute ticks and labels
using Toybox.Graphics as Gfx;
using Toybox.Math as Math;
using Toybox.Time;

function drawTicks(dc, centerX, centerY, radius, fontL, fontS) {
 	var length = 0;
	var angle  = 0;
	var innerX = 0;
	var outerX = 0;
	var innerY = 0;
	var outerY = 0;
	var fontX  = 0;
	var fontY  = 0;
	dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
	for (var i = 1; i <= 120; i++) {
		angle = Math.PI * i / 60;
		// skip hours 12 and 3
		if (i == 0) {
			continue;
		} else if (i % 5 == 0) {
			dc.setPenWidth(2);
			length = 8;
			innerX = centerX + Math.sin(angle) * (radius - length);
			innerY = centerY - Math.cos(angle) * (radius - length);
			fontX = centerX + Math.sin(angle) * (radius - 3 * 9);
			fontY = centerY - 2 * 5 - Math.cos(angle) * (radius - 3 * 9);
			if (i % 30 == 0) {
    			dc.drawText(fontX, fontY, fontL, i / 5, Gfx.TEXT_JUSTIFY_CENTER);
    		} else {
    			dc.drawText(fontX, fontY, fontS, i / 5, Gfx.TEXT_JUSTIFY_CENTER);
    		}
		} else {
			continue;
		}
		outerX = centerX + Math.sin(angle) * (radius);
		outerY = centerY - Math.cos(angle) * (radius);
	    dc.drawLine(innerX, innerY, outerX, outerY);
	}
}

function drawTriangle (dc, centerX, centerY, radius) {
 	var length = 0;
	var angle  = 0;
	var innerX = 0;
	var outerXNext = 0;
	var outerXPrev = 0;
	var innerY = 0;
	var outerYNext = 0;
	var outerYPrev = 0;
	var fontX  = 0;
	var fontY  = 0;
	dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);

	var today = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
	var gap = new Time.Duration(Time.Gregorian.SECONDS_PER_MINUTE * 15);
	var todayAfter5Mins = Time.Gregorian.info(Time.now().add(gap), Time.FORMAT_MEDIUM);
	var todayBefore5Mins = Time.Gregorian.info(Time.now().subtract(gap), Time.FORMAT_MEDIUM);

	angle = Math.PI * (today.hour.toDouble() + (today.min.toDouble()/60)) / 12;
	
	var angleNext = Math.PI * (todayAfter5Mins.hour.toDouble() + (todayAfter5Mins.min.toDouble()/60)) / 12;
	var anglePrev = Math.PI * (todayBefore5Mins.hour.toDouble() + (todayBefore5Mins.min.toDouble()/60)) / 12;
	
	dc.setPenWidth(2);
	length = 12;
	innerX = centerX + Math.sin(angle) * (radius - length);
	innerY = centerY - Math.cos(angle) * (radius - length);
	
	outerXNext = centerX + Math.sin(angleNext) * (radius);
	outerYNext = centerY - Math.cos(angleNext) * (radius);
	
	outerXPrev = centerX + Math.sin(anglePrev) * (radius);
	outerYPrev = centerY - Math.cos(anglePrev) * (radius);
	
    dc.drawLine(innerX, innerY, outerXNext, outerYNext);
    dc.drawLine(outerXPrev, outerYPrev, outerXNext, outerYNext);
    dc.drawLine(outerXPrev, outerYPrev, innerX, innerY);

}