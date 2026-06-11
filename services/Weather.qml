pragma Singleton

import Caelestia.Config
import qs.utils
import Caelestia
import Quickshell
import QtQuick

Singleton {
    id: root

    property string city
    property string loc
    property var cc
    property list<var> forecast
    property list<var> hourlyForecast
    property string error: ""
    property string _cachedLoc: ""
    property string _cachedCity: ""
    property real _lastLocationFetchMs: 0
    property bool _locationFetchInProgress: false
    property bool _geocodingInProgress: false
    property string _lastGeocodedCity: ""

    readonly property var cachedCities: new Map()

    readonly property string icon: cc ? Icons.getWeatherIcon(cc.weatherCode) : "cloud_alert"
    readonly property string description: cc?.weatherDesc ?? qsTr("No weather")
    readonly property string temp: cc ? `${cc.temp_C ?? "--"}°C` : "--"
    readonly property string feelsLike: cc ? `${cc.FeelsLikeC ?? "--"}°C` : "--"
    readonly property int humidity: cc?.humidity ?? 0
    readonly property real windSpeed: cc?.windSpeed ?? 0.0
    readonly property string sunrise: cc ? Qt.formatDateTime(new Date(cc.sunrise), GlobalConfig.services.useTwelveHourClock ? "h:mm A" : "h:mm") : "--:--"
    readonly property string sunset: cc ? Qt.formatDateTime(new Date(cc.sunset), GlobalConfig.services.useTwelveHourClock ? "h:mm A" : "h:mm") : "--:--"

    function formatTemp(temp: var): string {
        return GlobalConfig.services.useFahrenheit ? `${temp !== undefined ? Math.round(toFahrenheit(temp)) : "--"}°F` : `${temp !== undefined ? Math.round(temp) : "--"}°C`;
    }

    function toFahrenheit(celcius: real): real {
        return celcius * 9 / 5 + 32;
    }

    function reload(): void {
        let configLocation = GlobalConfig.services.weatherLocation;

        if (configLocation && configLocation !== "") {
            if (configLocation.indexOf(",") !== -1 && !isNaN(parseFloat(configLocation.split(",")[0]))) {
                loc = configLocation;
                fetchCityFromCoords(configLocation);
            } else {
                fetchCoordsFromCity(configLocation);
            }
        }
        else {
            const now = Date.now();
            const twentyFourHours = 86400000;
            if (_cachedLoc && (now - _lastLocationFetchMs) < twentyFourHours) {
                if (loc !== _cachedLoc) {
                    loc = _cachedLoc;
                    city = _cachedCity;
                } else {
                    fetchWeatherData();
                }
                return;
            }

            if (!loc && !_locationFetchInProgress) {
                _locationFetchInProgress = true;
                Requests.get("https://ipinfo.io/json", text => {
                    _locationFetchInProgress = false;
                    try {
                        const response = JSON.parse(text);
                        if (response.loc) {
                            loc = response.loc;
                            city = response.city ?? "";
                            _cachedLoc = loc;
                            _cachedCity = city;
                            _lastLocationFetchMs = Date.now();
                            error = "";
                        }
                    } catch (e) {
                        console.warn("Weather: Failed to parse location response:", e);
                        error = qsTr("Location unavailable");
                    }
                }, err => {
                    _locationFetchInProgress = false;
                    console.warn("Weather: Location fetch failed:", err);
                    error = qsTr("Location unavailable");
                });
            }
        }
    }

    function fetchCityFromCoords(coords: string): void {
        if (cachedCities.has(coords)) {
            city = cachedCities.get(coords);
            return;
        }

        const [lat, lon] = coords.split(",").map(s => s.trim());

        const fallbackToBigDataCloud = () => {
            const fallbackUrl = `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${lat}&longitude=${lon}&localityLanguage=en`;
            Requests.get(fallbackUrl, text => {
                const geo = JSON.parse(text);
                const geoCity = geo.city || geo.locality;
                if (geoCity) {
                    city = geoCity;
                    cachedCities.set(coords, geoCity);
                } else {
                    city = "Unknown City";
                }
            });
        };

        const nominatimUrl = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=geocodejson`;
        Requests.get(nominatimUrl, text => {
            const geo = JSON.parse(text).features?.[0]?.properties.geocoding;
            if (geo) {
                const geoCity = geo.type === "city" ? geo.name : geo.city;
                if (geoCity) {
                    city = geoCity;
                    cachedCities.set(coords, geoCity);
                    return;
                }
            }
            fallbackToBigDataCloud();
        }, fallbackToBigDataCloud);
    }

    function fetchCoordsFromCity(cityName) {
        if (_geocodingInProgress) return;
        if (_lastGeocodedCity === cityName && loc) {
            fetchWeatherData();
            return;
        }

        _geocodingInProgress = true;
        const url = "https://geocoding-api.open-meteo.com/v1/search?name=" 
            + encodeURIComponent(cityName) 
            + "&count=1&language=en&format=json";

        Requests.get(url, text => {
            _geocodingInProgress = false;
            try {
                const json = JSON.parse(text);
                if (!json.results || json.results.length === 0) {
                    console.error("Geocoding failed for: " + cityName);
                    error = qsTr("City not found");
                    return;
                }
                const result = json.results[0];
                const newLoc = result.latitude + "," + result.longitude;
                _lastGeocodedCity = cityName;
                city = result.name;
                error = "";
                if (loc === newLoc) {
                    fetchWeatherData();
                } else {
                    loc = newLoc;
                }
            } catch (e) {
                console.warn("Weather: Failed to parse geocoding response:", e);
                error = qsTr("City not found");
            }
        }, err => {
            _geocodingInProgress = false;
            console.warn("Weather: Geocoding fetch failed:", err);
            error = qsTr("Location unavailable");
        });
    }

    onLocChanged: fetchWeatherData()

    function fetchWeatherData() {
        let url = getWeatherUrl();
        if (url === "") return;

        Requests.get(url, text => {
            try {
                const json = JSON.parse(text);
                if (!json.current || !json.daily) return;

                error = "";
                cc = {
                    "weatherCode": String(json.current.weather_code),
                    "weatherDesc": getWeatherCondition(String(json.current.weather_code)),
                    "temp_C": Math.round(json.current.temperature_2m),
                    "FeelsLikeC": Math.round(json.current.apparent_temperature),
                    "humidity": json.current.relative_humidity_2m,
                    "windSpeed": json.current.wind_speed_10m,
                    "isDay": json.current.is_day,
                    "sunrise": json.daily.sunrise[0],
                    "sunset": json.daily.sunset[0]
                };

                let forecastList = [];
                for (let i = 0; i < json.daily.time.length; i++) {
                    forecastList.push({
                        "date": json.daily.time[i],
                        "maxTempC": Math.round(json.daily.temperature_2m_max[i]),
                        "minTempC": Math.round(json.daily.temperature_2m_min[i]),
                        "weatherCode": String(json.daily.weather_code[i]),
                        "icon": Icons.getWeatherIcon(String(json.daily.weather_code[i]))
                    });
                }
                forecast = forecastList;

                const hourlyList = [];
                const now = new Date();
                for (let i = 0; i < json.hourly.time.length; i++) {
                    const time = new Date(json.hourly.time[i].replace("T", " "));

                    if (time < now)
                        continue;

                    hourlyList.push({
                        timestamp: json.hourly.time[i],
                        hour: time.getHours(),
                        tempC: Math.round(json.hourly.temperature_2m[i]),
                        precipChance: json.hourly.precipitation_probability[i],
                        weatherCode: json.hourly.weather_code[i],
                        icon: Icons.getWeatherIcon(json.hourly.weather_code[i])
                    });
                }
                hourlyForecast = hourlyList;
            } catch (e) {
                console.warn("Weather: Failed to parse weather data:", e);
                error = qsTr("Weather data unavailable");
            }
        }, err => {
            console.warn("Weather: Data fetch failed:", err);
            error = qsTr("Weather data unavailable");
        });
    }

    function getWeatherUrl() {
        if (!loc || loc.indexOf(",") === -1) return "";

        const [lat, lon] = loc.split(",").map(s => s.trim());
        const baseUrl = "https://api.open-meteo.com/v1/forecast";
        const params = [
            "latitude=" + lat,
            "longitude=" + lon,
            "hourly=weather_code,temperature_2m,precipitation_probability",
            "daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset",
            "current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m",
            "timezone=auto",
            "forecast_days=7"
        ];

        return baseUrl + "?" + params.join("&");
    }

    function getWeatherCondition(code: string): string {
        const conditions = {
            "0": "Clear",
            "1": "Clear",
            "2": "Partly cloudy",
            "3": "Overcast",
            "45": "Fog",
            "48": "Fog",
            "51": "Drizzle",
            "53": "Drizzle",
            "55": "Drizzle",
            "56": "Freezing drizzle",
            "57": "Freezing drizzle",
            "61": "Light rain",
            "63": "Rain",
            "65": "Heavy rain",
            "66": "Light rain",
            "67": "Heavy rain",
            "71": "Light snow",
            "73": "Snow",
            "75": "Heavy snow",
            "77": "Snow",
            "80": "Light rain",
            "81": "Rain",
            "82": "Heavy rain",
            "85": "Light snow showers",
            "86": "Heavy snow showers",
            "95": "Thunderstorm",
            "96": "Thunderstorm with hail",
            "99": "Thunderstorm with hail"
        };
        return conditions[code] || "Unknown";
    }

    Connections {
        function onWeatherLocationChanged(): void {
            root.reload();
        }

        target: GlobalConfig.services
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: fetchWeatherData()
    }
}
