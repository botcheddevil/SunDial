using Toybox.Time.Gregorian as Gregorian;
using Toybox.Math as Math;
using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;
using Toybox.System as Sys;
using Toybox.Time;

function drawMoon(dc, centerX, centerY, radius, time, location, altitude) {

	var fontHeight = Gfx.getFontHeight(Gfx.FONT_XTINY);
	var deg2rad = Math.PI / 180.0;
	if (altitude < 0) {
		altitude = 0;
	}
	var sunTimes = sunRiseSet(time, location, altitude);
	if (sunTimes == null) {
	  return(null);
	}

	var sunRise = Gregorian.info(sunTimes[0], Gregorian.FORMAT_SHORT);
    var sunSet = Gregorian.info(sunTimes[1], Gregorian.FORMAT_SHORT);
    
    var length = 0;
	var angle  = 0;
	var innerX = 0;
	var outerX = 0;
	var innerY = 0;
	var outerY = 0;
	var fontX  = 0;
	var fontY  = 0;
	dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_BLACK);
	for (var i = 1; i <= 240; i++) {
		angle = Math.PI * i / 120;
		// skip hours 12 and 3
		if (i == 0) {
			continue;
		} else if ((i >= ((sunRise.hour * 10) + Math.ceil(sunRise.min/6))) and (i <= (sunSet.hour * 10) + Math.ceil(sunSet.min/6))) {
			dc.setPenWidth(4);
			length = 6;
			innerX = centerX + Math.sin(angle) * (radius - length);
			innerY = centerY - Math.cos(angle) * (radius - length);
			fontX = centerX + Math.sin(angle) * (radius - 3*length);
			fontY = centerY - 2 * length - Math.cos(angle) * (radius - 3 * length);
		} else {
			continue;
		}
		outerX = centerX + Math.sin(angle) * (radius);
		outerY = centerY - Math.cos(angle) * (radius);
	    dc.drawLine(innerX, innerY, outerX, outerY);
	}

	return(null);
}

// moon calculations, based on http://aa.quae.nl/en/reken/hemelpositie.html formulas

var dayMs = (1000 * 60 * 60 * 24) ,
    J1970 = 2440588,
    J2000 = 2451545,
    rad  = Math.PI / 180.0;

var e = rad * 23.4397; // obliquity of the Earth

function rightAscension(l, b) { return Math.atan2(Math.sin(l) * Math.cos(e) - Math.tan(b) * Math.sin(e), Math.cos(l)); }
function declination(l, b)    { return Math.asin(Math.sin(b) * Math.cos(e) + Math.cos(b) * Math.sin(e) * Math.sin(l)); }

function azimuth(H, phi, dec)  { return Math.atan2(Math.sin(H), Math.cos(H) * Math.sin(phi) - Math.tan(dec) * Math.cos(phi)); }
function altitude(H, phi, dec) { return Math.asin(Math.sin(phi) * Math.sin(dec) + Math.cos(phi) * Math.cos(dec) * Math.cos(H)); }

function siderealTime(d, lw) { return rad * (280.16 + 360.9856235 * d) - lw; }

function toJulian(date) { return date.value() / (1000 * 60 * 60 * 24) - 0.5 + 2440588; }
function fromJulian(j)  { return new Time.Moment((j + 0.5 - 2440588) * (1000 * 60 * 60 * 24)); }
function toDays(date)   { return toJulian(date) - 2451545; }

function astroRefraction(h) {
    if (h < 0) { // the following formula works for positive altitudes only.
        h = 0; // if h = -0.08901179 a div/0 would occur.
        }

    // formula 16.4 of "Astronomical Algorithms" 2nd edition by Jean Meeus (Willmann-Bell, Richmond) 1998.
    // 1.02 / tan(h + 10.26 / (h + 5.10)) h in degrees, result in arc minutes -> converted to rad:
    return 0.0002967 / Math.tan(h + 0.00312536 / (h + 0.08901179));
}

// general sun calculations

function solarMeanAnomaly(d) { return rad * (357.5291 + 0.98560028 * d); }

function eclipticLongitude(M) {

    var C = rad * (1.9148 * sin(M) + 0.02 * sin(2 * M) + 0.0003 * sin(3 * M)), // equation of center
        P = rad * 102.9372; // perihelion of the Earth

    return M + C + P + PI;
}

function sunCoords(d) {

    var M = solarMeanAnomaly(d),
        L = eclipticLongitude(M);

    return {
        "dec" => declination(L, 0),
        "ra" => rightAscension(L, 0)
    };
}

function moonCoords(d) { // geocentric ecliptic coordinates of the moon

	var rad  = Math.PI / 180.0;
    var L = rad * (218.316 + 13.176396 * d), // ecliptic longitude
        M = rad * (134.963 + 13.064993 * d), // mean anomaly
        F = rad * (93.272 + 13.229350 * d),  // mean distance

        l  = L + rad * 6.289 * Math.sin(M), // longitude
        b  = rad * 5.128 * Math.sin(F),     // latitude
        dt = 385001 - 20905 * Math.cos(M);  // distance to the moon in km

    return {
        "ra" => rightAscension(l, b),
        "dec" => declination(l, b),
        "dist" => dt
    };
}

function getMoonPosition (date, lat, lng) {

	var lw  = rad * lng * -1,
        phi = rad * lat,
        d   = toDays(date),
        c = moonCoords(d),
        H = siderealTime(d, lw) - c.get("ra"),
        h = altitude(H, phi, c.get("dec")),
        // formula 14.1 of "Astronomical Algorithms" 2nd edition by Jean Meeus (Willmann-Bell, Richmond) 1998.
        pa = Math.atan2(Math.sin(H), Math.tan(phi) * Math.cos(c.get("dec")) - Math.sin(c.get("dec")) * Math.cos(H));

    h = h + astroRefraction(h); // altitude correction for refraction

    return {
        "azimuth" => azimuth(H, phi, c.get("dec")),
        "altitude" => h,
        "distance" => c.get("dist"),
        "parallacticAngle" => pa
    };
}


// calculations for illumination parameters of the moon,
// based on http://idlastro.gsfc.nasa.gov/ftp/pro/astro/mphase.pro formulas and
// Chapter 48 of "Astronomical Algorithms" 2nd edition by Jean Meeus (Willmann-Bell, Richmond) 1998.

function getMoonIllumination (date) {

    var d = toDays(date),
        s = sunCoords(d),
        m = moonCoords(d),

        sdist = 149598000, // distance from Earth to Sun in km

        phi = Math.acos(sin(s.get("dec")) * Math.sin(m.get("dec")) + Math.cos(s.get("dec")) * Math.cos(m.get("dec")) * Math.cos(s.get("ra") - m.get("ra"))),
        inc = Math.atan(sdist * sin(phi), m.get("dist") - sdist * Math.cos(phi)),
        angle = Math.atan(Math.cos(s.get("dec")) * Math.sin(s.get("ra") - m.get("ra")), Math.sin(s.get("dec")) * Math.cos(m.get("dec")) -
                Math.cos(s.get("dec")) * Math.sin(m.get("dec")) * Math.cos(s.get("ra") - m.get("ra")));

    return {
        "fraction" => (1 + cos(inc)) / 2,
        "phase" => 0.5 + 0.5 * inc * (angle < 0 ? -1 : 1) / Math.PI,
        "angle" => angle
    };
}


function hoursLater(date, h) {    
    var today = new Time.Moment(date.value());
	var hours = new Time.Duration(Gregorian.SECONDS_PER_HOUR * h);
	return today.add(hours);
}

// calculations for moon rise/set times are based on http://www.stargazing.net/kepler/moonrise.html article

function getMoonTimes (t, lat, lng) {
	var hc = 0.133 * rad,
        h0 = getMoonPosition(t, lat, lng).get("altitude") - hc,
        h1, h2, rise = 0, set = 0, a, b = 0, xe, ye, d, roots, x1 = 0, x2 = 0, dx;

    // go in 2-hour chunks, each time seeing if a 3-point quadratic curve crosses zero (which means rise or set)
    for (var i = 1; i <= 24; i += 2) {
        h1 = getMoonPosition(hoursLater(t, i), lat, lng).get("altitude") - hc;
        h2 = getMoonPosition(hoursLater(t, i + 1), lat, lng).get("altitude") - hc;
		Sys.println(h1.toString() + ' ' + h2.toString());
        a = (h0 + h2) / 2 - h1;
        b = (h2 - h0) / 2;
        Sys.println("Value of b " + b.toString());
        xe = (b * -1) / (2 * a);
        ye = (a * xe + b) * xe + h1;
        d = b * b - 4 * a * h1;
        roots = 0;

        if (d >= 0) {
            dx = Math.sqrt(d) / (a.abs() * 2);
            x1 = xe - dx;
            x2 = xe + dx;
            if (x1.abs() <= 1) {
            	roots++;
            }
            if (x2.abs() <= 1) {
            	roots++;
        	}
            if (x1 < -1) {
            	x1 = x2;
        	}
        }

        if (roots == 1) {
            if (h0 < 0) {
            	rise = i + x1;
            } else {
            	set = i + x1;
            }

        } else if (roots == 2) {
            rise = i + (ye < 0 ? x2 : x1);
            set = i + (ye < 0 ? x1 : x2);
        }

        if (rise && set) {
        	break;
    	}

        h0 = h2;
    }

    var result = {};

    if (rise) {
    	result.put("rise", hoursLater(t, rise));
    }
    if (set) {
    	result.put("set", hoursLater(t, set));
    }

    if (!rise && !set) {
    	if (ye > 0) {
    		result.put("alwaysUp", true);
    	} else {
    		result.put("alwaysDown", true);
    	}
    }

    return result;
}