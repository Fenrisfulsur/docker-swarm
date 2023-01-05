TARGET=main

all:
	@echo "- Compiling $(notdir $(PWD))/$(TARGET).tex"
	@pdflatex -shell-escape $(TARGET).tex > /dev/null
	@bibtex $(TARGET) > /dev/null
	@pdflatex -shell-escape $(TARGET).tex > /dev/null
	@pdflatex -shell-escape $(TARGET).tex > /dev/null

debug:  # don't silent command for debugging
	pdflatex -shell-escape $(TARGET).tex
	bibtex $(TARGET)
	pdflatex -shell-escape $(TARGET).tex
	pdflatex -shell-escape $(TARGET).tex

run:
	@setsid zathura ${TARGET}.pdf &

clean:
	@rm -rf $(TARGET).{pdf,aux,log,out,toc,snm,bbl,bcf,blg,nav,vrb,run.xml,listing} $(TARGET)-blx.bib _minted-$(TARGET)
	@echo "Done"
