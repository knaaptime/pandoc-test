.PHONY: create_environment git

#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_NAME = pandoc-test
CONDA_ENVIRONMENT = pandoc-test
PYTHON_VERSION = 3

SRC = paper/draft.md
REVSRC = paper/revision.md

PDFS=$(SRC:.md=.pdf)
HTML=$(SRC:.md=.html)
TEX=$(SRC:.md=.tex)

REVPDFS=$(REVSRC:.md=.pdf)
REVHTML=$(REVSRC:.md=.html)
REVTEX=$(REVSRC:.md=.tex)


#################################################################################
# COMMANDS                                                                      #
#################################################################################

## Set up python interpreter environment
environment:
	conda env create -f environment.yml; source activate $(PROJECT_NAME); python setup.py develop


## Update the environment in case of changes to dependencies
environment-update:
	conda env update --name PROJECT_NAME --file environment.yml

## If you get an error running make notebooks, this will install the kernel manually; 
## must be run from inside the conda environment
kernel:
	python -m ipykernel install --name $(PROJECT_NAME) --user


## Initialize a git repository
git:
	git init

## Compile the current draft into latex, html, and pdf
paper:	$(HTML) $(TEX) $(PDFS) 

## Compile the current draft into pdf
pdf:	clean $(PDFS)

## Compile the current draft into html
html:	clean $(HTML)

## Compile the current draft into latex
tex:	clean $(TEX)

	
%.html:	%.md
	pandoc -r markdown+simple_tables+table_captions+yaml_metadata_block+smart --self-contained -w html --resource-path=.:$(PWD) --template=paper/.pandoc/html.template --css=paper/.pandoc/marked/kultiad-serif.css --filter pandoc-include --filter pandoc-crossref --filter pandoc-latex-admonition --filter pandoc-citeproc -o $@ $<

%.tex:	%.md
	pandoc -r markdown+simple_tables+table_captions+yaml_metadata_block+smart -w latex -s --pdf-engine=xelatex --template=paper/.pandoc/xelatex.template --filter pandoc-include --filter pandoc-crossref --filter pandoc-latex-admonition --filter pandoc-citeproc -o $@ $<


%.pdf:	%.md
	pandoc paper/appendix.md --filter pandoc-include --filter pandoc-crossref --filter pandoc-latex-admonition --filter pandoc-citeproc -o paper/appendix.tex
	pandoc -r markdown+simple_tables+table_captions+yaml_metadata_block+smart -s --pdf-engine=xelatex --template=paper/.pandoc/xelatex.template --filter pandoc-include --filter pandoc-crossref --filter pandoc-latex-admonition --filter pandoc-citeproc  --include-after-body paper/appendix.tex -o $@ $<
	rm -rf paper/draft.aux paper/draft.fdb_latexmk paper/draft.fls paper/draft.log paper/appendix.tex


## Remove old versions of compiled html, pdf, latex 
clean:
	rm -f paper/*.html paper/*.pdf paper/*.tex

## Run notebooks
notebooks:
	jupyter nbconvert --to notebook --execute --inplace --ExecutePreprocessor.timeout=-1 --ExecutePreprocessor.kernel_name=python3 notebooks/*.ipynb;

## Run any necessary scripts
scripts:
	# python example.py 

## Compole revised deaft and texdiff with original
revision: $(REVPDFS) $(REVHTML) $(REVTEX) paper
	latexdiff paper/draft.tex paper/revision.tex > paper/diff.tex
	xelatex -output-directory=paper/ paper/diff
	xelatex -output-directory=paper/ paper/diff
	rm -f paper/*.aux paper/*.bcf paper/*.log paper/*.out paper/*.run.xml paper/*.bbl *paper/*.blg 
	pandoc paper/review_response.md --filter pandoc-include --filter pandoc-crossref --filter pandoc-latex-admonition --filter pandoc-citeproc  -o paper/review_response.pdf



####################################################

#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := show-help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: show-help
show-help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) == Darwin && echo '--no-init --raw-control-chars')
