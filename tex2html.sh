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

# remove line break between <embed and src using perl for cross-platform compatibility
perl -0777 -pe 's/<embed\s*\n\s*/<embed /g' build/html/main.html > build/html/main.tmp && mv build/html/main.tmp build/html/main.html


# replace embed pdf figure with png
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' 's/embed.*\/\(.*\)pdf/img src="build\/html\/figures\/\1png/g' build/html/main.html;
else
  sed -i 's/embed.*\/\(.*\)pdf/img src="build\/html\/figures\/\1png/g' build/html/main.html;
fi


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


# Replace newline characters with space after "<img" using perl for cross-platform compatibility
perl -0777 -pe 's/<img\s*\n\s*/<img /g' build/html/main.html > build/html/main.tmp && mv build/html/main.tmp build/html/main.html

# replace all image with base64 encoding
# Process images in smaller batches to avoid argument list too long error
for img_origin in $(grep -o '<img[^>]*src="[^"]*"' build/html/main.html | sed -n 's/.*src="\([^"]*\)".*/\1/p')
do
  img_png=$(echo $img_origin | sed 's/\.[^.]*$/.png/')
  # Encode the image in base64
  echo $img_png
  base64 "$img_png" | tr -d '\n' > tmp.b64

  echo "s|$img_origin|data:image/png;base64,$(cat tmp.b64)|g" > tmp.sed

  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' -f tmp.sed build/html/main.html
  else
    sed -i -f tmp.sed build/html/main.html
  fi

  rm tmp.sed
  rm tmp.b64
done
