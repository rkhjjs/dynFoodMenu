
export PACKVER=current
export GBCPROJECT=gbc-$(PACKVER)
export DISTBIN=$(PWD)/..
export CWD=$(PWD)

ifeq (,$(wildcard $(PWD)/custom.json))
	export NOCFG="missing $(PWD)/custom.json"
else
	export CFG=--configuration=$(PWD)/custom.json
	#export CFG=--configuration=$(PWD)/custom.json --compile-mode=prod --create-zip
endif
