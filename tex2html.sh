pandoc main.tex -t json | python extra/joas_filter.py | pandoc -f json  \
  --output build/html/main.html \
  --template extra/template.html5 \
  --css bootstrap.min.css \
  --toc \
  --toc-depth=2 \
  --citeproc \
  --bibliography=reference.bib \
  --csl=extra/acm-siggraph.csl \
  --mathml \
  --variable editat=main \
  --extract-media build/html

# remove line break between embed and src
sed -i ':a;N;$!ba;s/embed\n\s*/embed /g' build/html/main.html

# replace embed pdf figure with png
sed -i 's/embed.*\/\(.*\)pdf/img src="build\/html\/figures\/\1png/g' build/html/main.html;


find build/html/figures -type f -name '*.pdf' -print0 |
  while IFS= read -r -d '' fpdf; do 
    fpng=${fpdf%.*}.png
    convert $fpdf  -resize "800x800>^" ${fpdf%.*}.png
  done
  
find build/html/figures -type f -name '*.svg' -print0 |
  while IFS= read -r -d '' fsvg; do 
    fpng=${fsvg%.*}.png
    convert $fsvg  -resize "800x800>^" ${fsvg%.*}.png
  done

find build/html/figures -type f -name '*.jpg' -print0 |
  while IFS= read -r -d '' fjpg; do 
    fpng=${fjpg%.*}.png
    convert $fjpg  -resize "800x800>^" ${fjpg%.*}.png
  done

find build/html/figures -type f -name '*.png' -print0 |
  while IFS= read -r -d '' fpng; do 
    fpng=${fpng%.*}.png
    convert $fpng  -resize "800x800>^" ${fpng%.*}.png
  done


# Replace newline characters with space after "<img" and space before "style="
sed -i -z 's/<img\n/<img /g' build/html/main.html

# replace all image with base64 encoding
for img_orign in $(sed -n 's/.*<img\s*src="\([^"]*\)".*/\1/p' build/html/main.html)
do
  img_png=$(echo $img_orign | sed 's/\.[^.]*$/.png/')
  # Encode the image in base64
  echo $img_png
  base64 -w 0 "$img_png" > tmp.b64
  
  echo "s|$img_orign|data:image/png;base64,$(cat tmp.b64)|g" > tmp.sed
  # Run the sed script on the HTML file
  sed -i -f tmp.sed build/html/main.html
  
  rm tmp.sed
  rm tmp.b64
done
