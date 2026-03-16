#!/usr/bin/env python3
"""
Extract algorithm environments from a LaTeX file, compile each as a
standalone cropped PDF, convert to PNG, and replace the broken
<div class="algorithm"> blocks in the generated HTML with <img> tags.

Usage:
    python3 extra/render_algorithms.py main.tex build/html/main.html
"""

import re
import os
import sys
import subprocess
import tempfile
import shutil


def extract_preamble(tex_src):
    """Extract everything between \\documentclass and \\begin{document}."""
    m = re.search(
        r"(\\documentclass.*?)(\\begin\{document\})", tex_src, re.DOTALL
    )
    if not m:
        return ""
    return m.group(1)


def extract_algorithms(tex_src):
    """Return a list of algorithm environment strings, skipping commented-out ones."""
    # Remove comment lines before matching
    lines = tex_src.split("\n")
    cleaned = "\n".join(l for l in lines if not l.lstrip().startswith("%"))
    pattern = r"(\\begin\{algorithm\}(?:\[.*?\])?.*?\\end\{algorithm\})"
    return re.findall(pattern, cleaned, re.DOTALL)


def compile_algorithm(preamble, algo_tex, output_png, idx):
    """Compile a single algorithm block to a cropped PNG."""
    tmpdir = tempfile.mkdtemp(prefix=f"algo{idx}_")
    try:
        # Copy extra/ folder for cls files
        src_extra = os.path.join(os.path.dirname(__file__))
        dst_extra = os.path.join(tmpdir, "extra")
        shutil.copytree(src_extra, dst_extra)

        standalone_tex = (
            preamble
            + "\n\\begin{document}\n"
            + algo_tex
            + "\n\\end{document}\n"
        )

        tex_path = os.path.join(tmpdir, "algo.tex")
        with open(tex_path, "w") as f:
            f.write(standalone_tex)

        # Compile with pdflatex
        for _ in range(2):
            subprocess.run(
                [
                    "pdflatex",
                    "-interaction=nonstopmode",
                    "-shell-escape",
                    "algo.tex",
                ],
                cwd=tmpdir,
                capture_output=True,
                timeout=60,
            )

        pdf_path = os.path.join(tmpdir, "algo.pdf")
        if not os.path.exists(pdf_path):
            print(f"  WARNING: Failed to compile algorithm {idx}", file=sys.stderr)
            return False

        # Crop the PDF
        cropped_path = os.path.join(tmpdir, "algo-crop.pdf")
        subprocess.run(
            ["pdfcrop", pdf_path, cropped_path],
            capture_output=True,
            timeout=30,
        )
        if not os.path.exists(cropped_path):
            cropped_path = pdf_path

        # Convert to PNG at good resolution
        os.makedirs(os.path.dirname(output_png), exist_ok=True)
        subprocess.run(
            [
                "magick",
                "-density",
                "200",
                cropped_path,
                "-quality",
                "95",
                output_png,
            ],
            capture_output=True,
            timeout=30,
        )

        if not os.path.exists(output_png):
            # Fallback to convert command
            subprocess.run(
                [
                    "convert",
                    "-density",
                    "200",
                    cropped_path,
                    "-quality",
                    "95",
                    output_png,
                ],
                capture_output=True,
                timeout=30,
            )

        return os.path.exists(output_png)
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


def replace_algorithm_divs(html_path, png_paths):
    """Replace <div class="algorithm">...</div> blocks with <img> tags."""
    with open(html_path, "r") as f:
        html = f.read()

    # Match each <div class="algorithm">...</div> block
    pattern = r'<div class="algorithm">\s*<div class="algorithmic">.*?</div>\s*</div>'
    matches = list(re.finditer(pattern, html, re.DOTALL))

    if len(matches) != len(png_paths):
        print(
            f"  WARNING: Found {len(matches)} algorithm divs but {len(png_paths)} PNGs",
            file=sys.stderr,
        )

    # Replace from last to first to preserve positions
    for i in range(min(len(matches), len(png_paths)) - 1, -1, -1):
        if png_paths[i] is None:
            continue  # skip failed renders
        m = matches[i]
        img_tag = (
            f'<div class="algorithm" style="text-align:center; padding:1em;">'
            f'<img src="{png_paths[i]}" style="max-width:100%;" '
            f'alt="Algorithm {i+1}">'
            f"</div>"
        )
        html = html[: m.start()] + img_tag + html[m.end() :]

    with open(html_path, "w") as f:
        f.write(html)


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <main.tex> <output.html>", file=sys.stderr)
        sys.exit(1)

    tex_file = sys.argv[1]
    html_file = sys.argv[2]
    figures_dir = "build/html/figures"

    with open(tex_file, "r") as f:
        tex_src = f.read()

    preamble = extract_preamble(tex_src)
    algorithms = extract_algorithms(tex_src)

    if not algorithms:
        print("  No algorithm environments found, skipping.")
        return

    print(f"  Found {len(algorithms)} algorithm environment(s)")

    png_paths = []
    for i, algo in enumerate(algorithms):
        png_rel = f"{figures_dir}/algorithm_{i+1}.png"
        print(f"  Rendering algorithm {i+1}...")
        success = compile_algorithm(preamble, algo, png_rel, i + 1)
        if success:
            png_paths.append(png_rel)
            print(f"    -> {png_rel}")
        else:
            print(f"    -> FAILED, keeping original HTML")
            png_paths.append(None)

    # Only replace divs where we have a valid PNG
    valid_pngs = [p for p in png_paths if p is not None]
    if valid_pngs:
        replace_algorithm_divs(html_file, png_paths)
        print(f"  Replaced {len(valid_pngs)} algorithm block(s) in HTML")


if __name__ == "__main__":
    main()
