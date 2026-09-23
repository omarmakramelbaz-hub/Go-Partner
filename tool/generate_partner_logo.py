"""Rebuild path-only brand marks from the bundled, licensed Roboto font.
SVG text is intentionally outlined for flutter_svg and native launcher builds.
"""
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

ROOT = Path(__file__).resolve().parent.parent
font = TTFont(ROOT / 'assets/font/Roboto/Roboto-Black.ttf')
glyphs = font.getGlyphSet()
cmap = font.getBestCmap()
units = font['head'].unitsPerEm

def word(text, x, baseline, size, color):
    scale = size / units
    parts = []
    for char in text:
        glyph = glyphs[cmap[ord(char)]]
        pen = SVGPathPen(glyphs)
        glyph.draw(pen)
        parts.append(f'<path d="{pen.getCommands()}" transform="translate({x:.3f} {baseline}) scale({scale:.6f} {-scale:.6f})" fill="{color}"/>')
        x += glyph.width * scale
    return ''.join(parts)

def logo(light=False):
    fg = '#ffffff' if light else '#171a1f'
    return '<svg xmlns="http://www.w3.org/2000/svg" aria-label="GO Partner" viewBox="0 0 300 230">' + word('G', 36, 123, 145, '#fd7201') + '<path d="M202 18c-34 0-60 25-60 58 0 40 60 83 60 83s60-43 60-83c0-33-26-58-60-58Z" fill="#fd7201"/><path d="M202 44c-15 0-27 12-27 27 0 19 27 39 27 39s27-20 27-39c0-15-12-27-27-27Z" fill="white"/><circle cx="202" cy="70" r="11" fill="#171a1f"/>' + word('Partner', 28, 208, 67, fg) + '</svg>'

(ROOT / 'assets/svg/go_partner_logo.svg').write_text(logo())
(ROOT / 'assets/svg/go_partner_logo_light.svg').write_text(logo(True))
icon = '<svg xmlns="http://www.w3.org/2000/svg" aria-label="GO Partner" viewBox="0 0 1024 1024"><rect width="1024" height="1024" fill="#171a1f"/><g transform="translate(96 160) scale(2.77333)">' + logo(True).split('>', 1)[1].removesuffix('</svg>') + '</g></svg>'
(ROOT / 'assets/svg/go_partner_icon.svg').write_text(icon)
