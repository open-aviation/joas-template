import os
import re
import sys

latex_dir = sys.argv[1]

with open(os.path.join(latex_dir, "main.tex"), "r") as file:
    tex_content = file.read()

included_graphics = re.findall(r"\\includegraphics(?:\[.*?\])?\{(.*?)\}", tex_content)

# List all figure files in the project directory
figure_files = [
    f
    for f in os.listdir(latex_dir)
    if f.endswith((".png", ".jpg", ".jpeg", ".pdf", ".eps"))
]

unused_figures = [fig for fig in figure_files if fig not in included_graphics]

print("Unused figures:")
for fig in unused_figures:
    print(fig)
