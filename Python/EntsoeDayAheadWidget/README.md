# ENTSO-E Day-Ahead Prijzen Widget voor WordPress

Een kleine Python-webapp (Flask) die de **dagelijkse uurprijzen elektriciteit**
van de ENTSO-E day-ahead veiling ophaalt en als interactieve grafiek
(Chart.js) toont. De grafiek is eenvoudig te integreren in een
WordPress-website via een iframe of de meegeleverde shortcode-plugin.

> WordPress zelf draait PHP en kan geen Python uitvoeren. Daarom draait de
> Python-app als kleine webservice (op je eigen server, VPS of een gratis
> hosting zoals Render/Railway/PythonAnywhere) en embed je de grafiek in
> WordPress.

## Functies

- Uurprijzen van vandaag (of een andere dag via `?date=YYYY-MM-DD`)
- Biedzones: NL, BE, DE, FR (eenvoudig uit te breiden in `BIDDING_ZONES`)
- Kwartierprijzen (15-minuten-MTU) worden automatisch gemiddeld naar uurprijzen
- Staafgrafiek met kleurcodering goedkoop/gemiddeld/duur, huidig uur gemarkeerd
- Min/gemiddeld/max van de dag, prijzen in ct/kWh én €/MWh
- JSON-API op `/api/prices` voor eigen toepassingen
- Caching (15 min) zodat de ENTSO-E API niet onnodig wordt belast

## 1. ENTSO-E API-token aanvragen (gratis)

1. Maak een account aan op <https://transparency.entsoe.eu>
2. Vraag Web API-toegang aan: stuur een e-mail naar
   `transparency@entsoe.eu` met onderwerp "Restful API access" en het
   e-mailadres van je account
3. Na bevestiging vind je het token onder *My Account Settings → Web API
   Security Token*

## 2. Lokaal draaien

```bash
cd Python/EntsoeDayAheadWidget
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

export ENTSOE_API_TOKEN="jouw-token-hier"
python app.py
```

Open daarna:

- Widget:   <http://localhost:8000/widget?zone=NL>
- JSON-API: <http://localhost:8000/api/prices?zone=NL>

## 3. Productie (server/VPS)

```bash
export ENTSOE_API_TOKEN="jouw-token-hier"
gunicorn -w 2 -b 0.0.0.0:8000 app:app
```

Zet er bij voorkeur een reverse proxy met HTTPS voor (nginx/Caddy), zodat de
widget bereikbaar is op bv. `https://prijzen.jouwdomein.nl/widget`.
HTTPS is verplicht als je WordPress-site ook HTTPS gebruikt (mixed content
wordt anders geblokkeerd door de browser).

## 4. Integreren in WordPress

### Optie A – HTML-blok (snelste manier)

Voeg in de Gutenberg-editor een **Aangepaste HTML**-blok toe met:

```html
<iframe src="https://prijzen.jouwdomein.nl/widget?zone=NL"
        style="width:100%;border:0;" height="430" loading="lazy"
        title="Day-ahead elektriciteitsprijzen"></iframe>
```

### Optie B – Shortcode-plugin

1. Kopieer `wordpress/entsoe-prijzen-widget.php` naar
   `wp-content/plugins/` van je WordPress-installatie
2. Pas de constante `ENTSOE_WIDGET_URL` aan naar jouw widget-URL
   (in het bestand zelf, of via `define('ENTSOE_WIDGET_URL', '...');`
   in `wp-config.php`)
3. Activeer de plugin in het WordPress-dashboard
4. Gebruik in een pagina of bericht:

```
[entsoe_prijzen]
[entsoe_prijzen zone="BE" hoogte="450"]
```

## API-referentie

`GET /api/prices?zone=NL&date=2026-06-10`

```json
{
  "zone": "NL",
  "zone_label": "Nederland",
  "date": "2026-06-10",
  "unit": "EUR/MWh",
  "source": "ENTSO-E Transparency Platform (day-ahead veiling)",
  "prices": [
    {"time": "2026-06-10T00:00:00+02:00", "hour": "00:00",
     "price_eur_mwh": 85.2, "price_ct_kwh": 8.52}
  ]
}
```

`GET /widget?zone=NL[&date=YYYY-MM-DD]` – de embeddebare grafiekpagina.

## Opmerkingen

- De prijzen voor **morgen** worden door ENTSO-E gepubliceerd rond
  13:00–14:00 CET; gebruik dan `?date=` met de datum van morgen.
- De getoonde prijzen zijn kale groothandelsprijzen (day-ahead) en zijn dus
  **exclusief** energiebelasting, btw en de inkoopvergoeding van je
  leverancier.
