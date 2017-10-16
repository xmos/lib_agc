.SUFFIXES: .pdf .svg

%.pdf: %.svg
	inkscape -z -f `pwd`/$*.svg -A `pwd`/$*.pdf

SPHINX_PROJECT_NAME=VocalFusion Classic
VERSION=0.5
DOXYGEN_DIRS=
SOURCE_INCLUDE_DIRS=.

IMAGES=diagram.pdf diagram-beamformer.pdf diagram-aec.pdf \
	diagram-agc.pdf diagram-agc-states.pdf diagram-agc-graph.pdf \


xmospdf: $(IMAGES)
	xdoc xmospdf
