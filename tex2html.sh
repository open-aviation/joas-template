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

cd build/html/

find figures -type f -name '*.pdf' -print0 |
  while IFS= read -r -d '' fpdf; do 
    fpng=${fpdf%.*}.png
    convert -density 300 $fpdf -colorspace RGB -resize 500x\> ${fpdf%.*}.png
    rm $fpdf
  done


for img0 in `sed -n '/<img/s/.*src="\([^"]*\)".*/\1/p' main.html`
do
  img="data:image/png;base64, $(base64 -w 0 "$img0")"

  echo "s|$img0|$img|" > tmp.sed 
  sed -f tmp.sed main.html > tmp.html
  
  mv tmp.html main.html
  rm tmp.sed
done;