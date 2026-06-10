<?php
/**
 * Plugin Name: ENTSO-E Prijzen Widget
 * Description: Toont de dagelijkse day-ahead uurprijzen elektriciteit (ENTSO-E) als grafiek via een shortcode: [entsoe_prijzen]
 * Version: 1.0.0
 * Author: -
 *
 * Gebruik in een bericht of pagina:
 *   [entsoe_prijzen]
 *   [entsoe_prijzen zone="BE" hoogte="450"]
 *
 * Stel hieronder (of via de constante in wp-config.php) de URL in van de
 * draaiende Python-widget, bv. https://prijzen.jouwdomein.nl/widget
 */

if (!defined('ABSPATH')) {
    exit;
}

if (!defined('ENTSOE_WIDGET_URL')) {
    define('ENTSOE_WIDGET_URL', 'https://prijzen.jouwdomein.nl/widget');
}

function entsoe_prijzen_shortcode($atts)
{
    $atts = shortcode_atts(
        array(
            'zone'   => 'NL',
            'hoogte' => '430',
            'url'    => ENTSOE_WIDGET_URL,
        ),
        $atts,
        'entsoe_prijzen'
    );

    $src = add_query_arg(
        array('zone' => strtoupper(sanitize_text_field($atts['zone']))),
        esc_url_raw($atts['url'])
    );

    return sprintf(
        '<iframe src="%s" style="width:100%%;border:0;" height="%d" loading="lazy" title="Day-ahead elektriciteitsprijzen"></iframe>',
        esc_url($src),
        (int) $atts['hoogte']
    );
}
add_shortcode('entsoe_prijzen', 'entsoe_prijzen_shortcode');
