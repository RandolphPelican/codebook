"""Polish-layer shared utilities for CodebookOS V1.0 SHIP.

This package is the polish/showroom layer per D4.1 (polish-vs-credential separation):
the substrate (boot/, surfaces/, tools/) is pure NASM/Python-build-tools and embodies
the credential; polish/ is Python and embodies the presentation. The boundary between
them is auditable on inspection of the repo structure.

Modules:
    tricolor    Pelican III red/gold/green metallic palette + gradient functions
    scaled_font 8x8 bitmap font scaled to 4x/8x for title cards; mirrors substrate aesthetic
    widgets     UI primitives (bordered cell, banner, mythology icon stub, scrolling text frame)
"""
