.PHONY: all clean run plugins $(EXE)

OPA ?= opa
OPA_PLUGIN ?= opa-plugin-builder
OPA_OPT ?= --parser js-like
MINIMAL_VERSION = 1046
EXE = mind_chat.exe

all: $(EXE)

plugins: plugins/mindwave/mindwave.js
	$(OPA_PLUGIN) --js-validator-off plugins/mindwave/mindwave.js -o mindwave.opp
	$(OPA) $(OPA_OPT) plugins/mindwave/mindwave.opa mindwave.opp

$(EXE): plugins src/*.opa resources/*
	$(OPA) $(OPA_OPT) --minimal-version $(MINIMAL_VERSION) *.opp src/*.opa -o $(EXE)

run: all
	./$(EXE) $(RUN_OPT) || true ## prevent ugly make error 130 :) ##

clean:
	rm -Rf *.opx* *.opp*
	rm -Rf *.exe _build _tracks *.log **/#*#
