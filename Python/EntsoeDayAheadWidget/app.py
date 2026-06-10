"""
ENTSO-E Day-Ahead prijzen widget.

Een kleine Flask-applicatie die de dagelijkse uurprijzen elektriciteit
(day-ahead veiling) ophaalt van het ENTSO-E Transparency Platform en
serveert als:

  * /api/prices  -> JSON met uurprijzen (EUR/MWh en ct/kWh)
  * /widget      -> kant-en-klare HTML-pagina met grafiek (Chart.js),
                    te embedden in WordPress via een iframe of shortcode.

Vereist een (gratis) API-token van het ENTSO-E Transparency Platform,
aan te leveren via de omgevingsvariabele ENTSOE_API_TOKEN.
Zie README.md voor installatie- en WordPress-instructies.
"""

import os
import threading
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import requests
from flask import Flask, jsonify, render_template, request

app = Flask(__name__)

ENTSOE_API_URL = "https://web-api.tp.entsoe.eu/api"
ENTSOE_API_TOKEN = os.environ.get("ENTSOE_API_TOKEN", "")

LOCAL_TZ = ZoneInfo("Europe/Amsterdam")

# EIC-codes van enkele biedzones. Uit te breiden naar behoefte:
# https://www.entsoe.eu/data/energy-identification-codes-eic/
BIDDING_ZONES = {
    "NL": ("10YNL----------L", "Nederland"),
    "BE": ("10YBE----------2", "België"),
    "DE": ("10Y1001A1001A82H", "Duitsland-Luxemburg"),
    "FR": ("10YFR-RTE------C", "Frankrijk"),
}

CACHE_TTL = timedelta(minutes=15)
_cache = {}
_cache_lock = threading.Lock()


def _strip_ns(tag):
    """Verwijder de XML-namespace van een tag, bv. '{ns}Point' -> 'Point'."""
    return tag.rsplit("}", 1)[-1]


def _iter_children(element, name):
    for child in element:
        if _strip_ns(child.tag) == name:
            yield child


def _find_text(element, *path):
    """Zoek namespace-onafhankelijk een geneste tekstwaarde."""
    current = element
    for name in path:
        current = next(_iter_children(current, name), None)
        if current is None:
            return None
    return (current.text or "").strip()


def _resolution_minutes(resolution):
    return {"PT15M": 15, "PT30M": 30, "PT60M": 60, "P1D": 1440}.get(resolution)


def _parse_document(xml_text):
    """
    Parseer een Publication_MarketDocument naar een dict
    {utc_datetime: prijs_eur_mwh} op de resolutie van het document.

    Houdt rekening met curve type A03: ontbrekende posities betekenen
    'zelfde prijs als vorige punt' en worden vooruit gevuld.
    """
    root = ET.fromstring(xml_text)
    if _strip_ns(root.tag) == "Acknowledgement_MarketDocument":
        reason = _find_text(root, "Reason", "text") or "Geen data beschikbaar"
        raise LookupError(reason)

    prices = {}
    for series in _iter_children(root, "TimeSeries"):
        for period in _iter_children(series, "Period"):
            start_text = _find_text(period, "timeInterval", "start")
            end_text = _find_text(period, "timeInterval", "end")
            resolution = _find_text(period, "resolution")
            minutes = _resolution_minutes(resolution)
            if not (start_text and end_text and minutes):
                continue

            start = datetime.fromisoformat(start_text.replace("Z", "+00:00"))
            end = datetime.fromisoformat(end_text.replace("Z", "+00:00"))
            total_points = int((end - start) / timedelta(minutes=minutes))

            by_position = {}
            for point in _iter_children(period, "Point"):
                position = _find_text(point, "position")
                amount = _find_text(point, "price.amount")
                if position and amount:
                    by_position[int(position)] = float(amount)

            last_price = None
            for position in range(1, total_points + 1):
                last_price = by_position.get(position, last_price)
                if last_price is None:
                    continue
                moment = start + timedelta(minutes=minutes * (position - 1))
                prices[moment] = (last_price, minutes)
    return prices


def _to_hourly(prices):
    """
    Aggregeer naar uurprijzen. Sinds de overgang van de day-ahead markt
    naar 15-minuten-MTU levert ENTSO-E kwartierwaarden; het gemiddelde
    per uur komt overeen met de uurprijs zoals leveranciers die tonen.
    """
    buckets = {}
    for moment, (price, _minutes) in prices.items():
        hour = moment.replace(minute=0, second=0, microsecond=0)
        buckets.setdefault(hour, []).append(price)
    return {hour: sum(values) / len(values) for hour, values in buckets.items()}


def fetch_day_ahead_prices(zone_code, day):
    """
    Haal de day-ahead uurprijzen op voor 'day' (een date in lokale tijd)
    en geef een gesorteerde lijst dicts terug.
    """
    if not ENTSOE_API_TOKEN:
        raise RuntimeError(
            "Geen ENTSOE_API_TOKEN gezet. Vraag een gratis Web API token aan "
            "op https://transparency.entsoe.eu en zet de omgevingsvariabele."
        )

    eic, _label = BIDDING_ZONES[zone_code]
    local_start = datetime.combine(day, datetime.min.time(), tzinfo=LOCAL_TZ)
    local_end = local_start + timedelta(days=1)
    fmt = "%Y%m%d%H%M"

    response = requests.get(
        ENTSOE_API_URL,
        params={
            "securityToken": ENTSOE_API_TOKEN,
            "documentType": "A44",  # Price Document (day-ahead prijzen)
            "in_Domain": eic,
            "out_Domain": eic,
            "periodStart": local_start.astimezone(timezone.utc).strftime(fmt),
            "periodEnd": local_end.astimezone(timezone.utc).strftime(fmt),
        },
        timeout=30,
    )
    response.raise_for_status()

    hourly = _to_hourly(_parse_document(response.text))
    rows = []
    for hour_utc in sorted(hourly):
        hour_local = hour_utc.astimezone(LOCAL_TZ)
        if not local_start <= hour_local < local_end:
            continue
        price = round(hourly[hour_utc], 2)
        rows.append(
            {
                "time": hour_local.isoformat(),
                "hour": hour_local.strftime("%H:%M"),
                "price_eur_mwh": price,
                "price_ct_kwh": round(price / 10.0, 2),
            }
        )
    if not rows:
        raise LookupError("Geen prijzen gevonden voor deze dag.")
    return rows


def get_prices_cached(zone_code, day):
    key = (zone_code, day)
    now = datetime.now(timezone.utc)
    with _cache_lock:
        cached = _cache.get(key)
        if cached and now - cached[0] < CACHE_TTL:
            return cached[1]
    rows = fetch_day_ahead_prices(zone_code, day)
    with _cache_lock:
        _cache[key] = (now, rows)
    return rows


def _request_zone_and_day():
    zone = request.args.get("zone", "NL").upper()
    if zone not in BIDDING_ZONES:
        raise LookupError(f"Onbekende zone '{zone}'. Kies uit: {', '.join(BIDDING_ZONES)}")
    date_arg = request.args.get("date")
    day = (
        datetime.strptime(date_arg, "%Y-%m-%d").date()
        if date_arg
        else datetime.now(LOCAL_TZ).date()
    )
    return zone, day


@app.after_request
def allow_embedding(response):
    # Nodig zodat WordPress (ander domein) het widget mag embedden/fetchen.
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Content-Security-Policy"] = "frame-ancestors *"
    return response


@app.route("/api/prices")
def api_prices():
    try:
        zone, day = _request_zone_and_day()
        rows = get_prices_cached(zone, day)
    except LookupError as exc:
        return jsonify({"error": str(exc)}), 404
    except (requests.RequestException, RuntimeError) as exc:
        return jsonify({"error": str(exc)}), 502
    return jsonify(
        {
            "zone": zone,
            "zone_label": BIDDING_ZONES[zone][1],
            "date": day.isoformat(),
            "currency": "EUR",
            "unit": "EUR/MWh",
            "source": "ENTSO-E Transparency Platform (day-ahead veiling)",
            "prices": rows,
        }
    )


@app.route("/widget")
def widget():
    zone = request.args.get("zone", "NL").upper()
    if zone not in BIDDING_ZONES:
        zone = "NL"
    return render_template("widget.html", zone=zone, zone_label=BIDDING_ZONES[zone][1])


@app.route("/")
def index():
    return widget()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8000)))
