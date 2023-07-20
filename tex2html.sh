pandoc main.tex -t json | python extra/joas_filter.py | pandoc -f json  \
  --output build/html/main.html \
  --template extra/template.html5 \
  --css bootstrap.min.css \
  --toc \
  --toc-depth=2 \
  --citeproc \
  --bibliography=reference.bib \
  --csl=extra/acm-siggraph.csl \
  --mathjax \
  --variable editat=main \
  --extract-media build/html

sed -i 's/embed.*\/\(.*\)pdf/img src="figures\/\1png/g' build/html/main.html;


find build/html/figures -type f -name '*.pdf' -print0 |
  while IFS= read -r -d '' fpdf; do 
    fpng=${fpdf%.*}.png
    convert -density 200 $fpdf -colorspace RGB -resize 800x800^ ${fpdf%.*}.png
  done
  
find build/html/figures -type f -name '*.svg' -print0 |
  while IFS= read -r -d '' fsvg; do 
    fpng=${fsvg%.*}.png
    convert -density 200 $fsvg -colorspace RGB -resize 800x800^ ${fsvg%.*}.png
  done



# replace all image with base64 encoding
for img_orign in $(sed -n 's/.*<img src="\([^"]*\)".*/\1/p' build/html/main.html)
do
  img_png=$(echo $img_orign | sed 's/\.[^.]*$/.png/')
  # Encode the image in base64
  base64 -w 0 "$img_png" > tmp.b64
  
  echo "s|$img_orign|data:image/png;base64,$(cat tmp.b64)|g" > tmp.sed
  # Run the sed script on the HTML file
  sed -i -f tmp.sed build/html/main.html
done
