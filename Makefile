.PHONY: all clean run plugins $(EXE)

OPA ?= opa
OPA-PLUGIN ?= opa-plugin-builder
OPA-OPT ?= --parser js-like
MINIMAL-VERSION = 1046
EXE = mind_chat.exe

all: $(EXE)

plugins: plugins/mindwave/mindwave.js
	$(OPA-PLUGIN) --js-validator-off plugins/mindwave/mindwave.js -o mindwave.opp
	$(OPA) $(OPA-OPT) plugins/mindwave/mindwave.opa mindwave.opp

$(EXE): plugins src/*.opa resources/*
	$(OPA) $(OPA-OPT) --minimal-version $(MINIMAL-VERSION) *.opp src/*.opa -o $(EXE)

run: all
	./$(EXE) $(RUN-OPT) || true ## prevent ugly make error 130 :) ##

clean:
	rm -Rf *.opx* *.opp*
	rm -Rf *.exe _build _tracks *.log **/#*#
