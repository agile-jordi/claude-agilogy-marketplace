"""render.py <chrome binary> [page.html ...]: renders each page (all *.html here by default) to a PNG beside it,
cropped to the window and its shadow."""
import pathlib
import subprocess
import sys

from PIL import Image

chrome, *pages = sys.argv[1:]
here = pathlib.Path(__file__).resolve().parent
for page in [pathlib.Path(p).resolve() for p in pages] or sorted(here.glob('*.html')):
    png = page.with_suffix('.png')
    subprocess.run([chrome, '--headless', '--hide-scrollbars', '--force-device-scale-factor=2',
                    '--default-background-color=00000000', '--window-size=1400,1400',
                    f'--screenshot={png}', page.as_uri()], check=True, capture_output=True)
    image = Image.open(png)
    image.crop(image.getbbox()).save(png, optimize=True)
    print(png)
