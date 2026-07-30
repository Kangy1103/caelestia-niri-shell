pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import CNS
import CNS.Config
import qs.utils

Singleton {
    id: root

    property string city
    property string loc
    property var cc
    property list<var> forecast
    property list<var> hourlyForecast

    property bool ipApiRequestPending: false
    property double ipApiBlockedUntil: 0
    property bool citiesLoaded: false
    property string pendingCoords

    readonly property string icon: cc ? Icons.getWeatherIcon(cc.weatherCode) : "cloud_alert"
    readonly property string description: cc?.weatherDesc ?? qsTr("No weather")
    readonly property string temp: formatTemp(cc?.tempC)
    readonly property string feelsLike: formatTemp(cc?.feelsLikeC)
    readonly property int humidity: cc?.humidity ?? 0
    readonly property real windSpeed: cc?.windSpeed ?? 0
    readonly property string sunrise: cc ? Qt.formatDateTime(new Date(cc.sunrise), GlobalConfig.services.useTwelveHourClock ? "h:mm A" : "h:mm") : "--:--"
    readonly property string sunset: cc ? Qt.formatDateTime(new Date(cc.sunset), GlobalConfig.services.useTwelveHourClock ? "h:mm A" : "h:mm") : "--:--"

    readonly property var cachedCities: new Map()
    readonly property var cachedWeather: new Map()

    function formatTemp(temp: var): string {
        return GlobalConfig.services.useFahrenheit ? `${temp !== undefined ? Math.round(toFahrenheit(temp)) : "--"}°F` : `${temp !== undefined ? Math.round(temp) : "--"}°C`;
    }

    function toFahrenheit(c: real): real {
        return c * 9 / 5 + 32;
    }

    function reload(): void {
        const configLocation = GlobalConfig.services.weatherLocation;
        const loc = configLocation || root.loc;

        if (loc && loc.length > 0) {
            root.loc = loc;
            fetchWeatherData();
        }
    }

    function fetchWeatherData(): void {
        const loc = root.loc;
        if (!loc || loc.length === 0)
            return;

        const isCoords = /^-?\d+\.?\d*,-?\d+\.?\d*$/.test(loc);

        if (isCoords) {
            const cacheKey = `coords:${loc}`;
            if (cachedWeather.has(cacheKey)) {
                applyWeatherData(cachedWeather.get(cacheKey));
                return;
            }

            const url = buildWeatherUrl(loc);
            // qmllint disable incompatible-type
            Requests.get(url, text => {
                // qmllint enable incompatible-type
                try {
                    const data = JSON.parse(text);
                    cachedWeather.set(cacheKey, data);
                    applyWeatherData(data);
                    if (!city)
                        fetchCityFromCoords(loc);
                } catch (e) {
                    console.warn("Weather: failed to parse weather data:", e);
                }
            });
        } else if (loc.includes(",")) {
            const parts = loc.split(",").map(s => s.trim());
            const query = parts.join(",");
            const url = buildGeocodeUrl(query);
            // qmllint disable incompatible-type
            Requests.get(url, text => {
                // qmllint enable incompatible-type
                try {
                    const data = JSON.parse(text);
                    if (data.results && data.results.length > 0) {
                        const result = data.results[0];
                        root.loc = `${result.latitude},${result.longitude}`;
                        city = result.name;
                        fetchWeatherData();
                    }
                } catch (e) {
                    console.warn("Weather: geocode failed:", e);
                }
            });
        } else {
            // City name — try geocoding
            const url = buildGeocodeUrl(loc);
            // qmllint disable incompatible-type
            Requests.get(url, text => {
                // qmllint enable incompatible-type
                try {
                    const data = JSON.parse(text);
                    if (data.results && data.results.length > 0) {
                        const result = data.results[0];
                        root.loc = `${result.latitude},${result.longitude}`;
                        city = result.name;
                        fetchWeatherData();
                    }
                } catch (e) {
                    console.warn("Weather: geocode failed:", e);
                }
            });
        }
    }

    function fixCityName(cityName: string): string {
        if (!cityName)
            return "";

        const mapping = {
            "New York County": "New York",
            "Kings County": "Brooklyn",
            "Bronx County": "Bronx",
            "Queens County": "Queens",
            "Richmond County": "Staten Island",
            "San Francisco County": "San Francisco",
            "Philadelphia County": "Philadelphia",
            "Suffolk County": "Boston",
            "District of Columbia": "Washington D.C.",
            "Geneve": "Genève"
        };

        return mapping[cityName] || cityName;
    }

    function cacheCity(coords: string, cityName: string): void {
        cachedCities.set(coords, cityName);
    }

    function fetchCityFromCoords(coords: string): void {
        if (cachedCities.has(coords)) {
            city = cachedCities.get(coords);
            return;
        }

        if (!citiesLoaded) {
            pendingCoords = coords;
            return;
        }

        const [lat, lon] = coords.split(",").map(s => s.trim());
        const lang = Qt.locale().name.split("_")[0] || "en";

        const fallbackToBigDataCloud = () => {
            const fallbackUrl = `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${lat}&longitude=${lon}&localityLanguage=${lang}`;
            Requests.get(fallbackUrl, text => {
                try {
                    const geo = JSON.parse(text);
                    const geoCity = geo.city || geo.locality || geo.localityInfo?.principalSubdivision || "";
                    const fixed = fixCityName(geoCity);
                    if (fixed) {
                        city = fixed;
                        root.cacheCity(coords, fixed);
                    }
                } catch (e) {
                    console.warn("Weather: bigdatacloud reverse geocode failed:", e);
                }
            });
        };

        const nominatimUrl = `https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${lat}&lon=${lon}&accept-language=${lang}`;

        Requests.get(nominatimUrl, text => {
            try {
                const geo = JSON.parse(text);
                const geoCity = geo.address?.city || geo.address?.town || geo.address?.village || geo.address?.county || "";
                const fixed = fixCityName(geoCity);
                if (fixed) {
                    city = fixed;
                    root.cacheCity(coords, fixed);
                } else {
                    fallbackToBigDataCloud();
                }
            } catch (e) {
                console.warn("Weather: nominatim reverse geocode failed:", e);
                fallbackToBigDataCloud();
            }
        });
    }

    function applyWeatherData(data: var): void {
        const current = data.current;
        if (!current)
            return;

        cc = {
            weatherCode: current.weather_code,
            tempC: current.temperature_2m,
            feelsLikeC: current.apparent_temperature,
            humidity: current.relative_humidity_2m,
            windSpeed: current.wind_speed_10m,
            sunrise: data.daily?.sunrise?.[0],
            sunset: data.daily?.sunset?.[0]
        };

        if (data.daily) {
            forecast = [];
            for (let i = 0; i < (data.daily.time?.length ?? 0); i++) {
                forecast.push({
                    date: data.daily.time[i],
                    weatherCode: data.daily.weather_code[i],
                    tempMax: data.daily.temperature_2m_max[i],
                    tempMin: data.daily.temperature_2m_min[i],
                    sunrise: data.daily.sunrise?.[i],
                    sunset: data.daily.sunset?.[i]
                });
            }
        }

        if (data.hourly) {
            hourlyForecast = [];
            for (let i = 0; i < (data.hourly.time?.length ?? 0); i++) {
                hourlyForecast.push({
                    time: data.hourly.time[i],
                    weatherCode: data.hourly.weather_code[i],
                    tempC: data.hourly.temperature_2m[i],
                    precipitation: data.hourly.precipitation_probability?.[i] ?? 0
                });
            }
        }
    }

    function buildWeatherUrl(coords: string): string {
        const [lat, lon] = coords.split(",").map(s => s.trim());
        const baseUrl = "https://api.open-meteo.com/v1/forecast";
        const params = [
            `latitude=${lat}`,
            `longitude=${lon}`,
            "hourly=weather_code,temperature_2m,precipitation_probability",
            "daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset",
            "current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m",
            "timezone=auto",
            "forecast_days=7"
        ];
        return baseUrl + "?" + params.join("&");
    }

    function buildGeocodeUrl(query: string): string {
        const lang = Qt.locale().name.split("_")[0] || "en";
        const encoded = encodeURIComponent(query);
        return `https://geocoding-api.open-meteo.com/v1/search?name=${encoded}&count=10&language=${lang}&format=json`;
    }

    function loadCities(): void {
        root.citiesLoaded = true;
        if (root.pendingCoords.length > 0) {
            const coords = root.pendingCoords;
            root.pendingCoords = "";
            fetchCityFromCoords(coords);
        }
    }

    onLocChanged: fetchWeatherData()

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

    Component.onCompleted: {
        root.loadCities();
        root.reload();
    }

    ElapsedTimer {
        id: timer
    }
}
