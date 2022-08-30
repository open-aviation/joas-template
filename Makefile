.ONESHELL:

param=$(filter-out $@,$(MAKECMDGOALS))

default:
	@echo "choose a target: pdf or html"


html:
	bash tex2html.sh

pdf:
	pdflatex -output-directory=tmp -synctex=1 main.tex
	biber tmp/main
	pdflatex -output-directory=tmp -synctex=1 main.tex
	cp tmp/main.pdf build/pdf/
	cp tmp/main.pdf .
	cp tmp/main.synctex.gz build/pdf/
	cp tmp/main.synctex.gz .

clean:
	rm -f *.aux *.bbl *.blg *.bcf *.fls *.fdb_latexmk *.idx *.ilg *.ind *.log *.out *.run.xml *.toc
	find build/html/ -type f -not -name "empty" -delete
	find build/pdf/ -type f -not -name "empty" -delete
	find tmp/ -type f -delete

%:
	@:
