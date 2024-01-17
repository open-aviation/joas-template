.ONESHELL:

param=$(filter-out $@,$(MAKECMDGOALS))
script_path=$(dirname "$0")
paper_id:=$(notdir $(patsubst %/,%,$(dir $(shell pwd))))


echo "paper id: $(paper_id)"

default:
	@echo "choose a target: pdf or html"


html:
	bash tex2html.sh
	cp ./build/html/main.html ../publish/joas-$(paper_id).html

pdf:
	pdflatex -synctex=1 --shell-escape main.tex 
	biber main
	pdflatex -synctex=1 --shell-escape main.tex
	cp main.pdf ../publish/joas-$(paper_id).pdf
clean:
	rm -f *.aux *.bbl *.blg *.bcf *.fls *.fdb_latexmk *.idx *.ilg *.ind *.log *.out *.run.xml *.toc
	find build/html/ -type f -not -name "empty" -delete
	find build/pdf/ -type f -not -name "empty" -delete
	find tmp/ -type f -delete


%:
	@:
