.ONESHELL:

param=$(filter-out $@,$(MAKECMDGOALS))

default:
	@echo "choose a target: pdf or html"


html:
	bash tex2html.sh

pdf:
	pdflatex -output-directory=build/pdf -synctex=1 main.tex
	biber build/pdf/main
	pdflatex -output-directory=build/pdf -synctex=1 main.tex
	cp build/pdf/main.pdf .
	cp build/pdf/main.synctex.gz .

clean:
	rm -f *.aux *.bbl *.blg *.bcf *.fls *.fdb_latexmk *.idx *.ilg *.ind *.log *.out *.run.xml *.toc
	find build/html/ -type f -not -name ".gitkeep" -delete
	find build/pdf/ -type f -not -name ".gitkeep" -delete

%:
	@:
