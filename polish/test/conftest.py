"""pytest configuration — add repo root to sys.path so `from polish.common ...` works."""
import os
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

# Headless-friendly PyGame default for CI
os.environ.setdefault('SDL_VIDEODRIVER', 'dummy')
