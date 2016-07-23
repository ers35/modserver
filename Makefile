default:
	cd src && $(MAKE) modserver

run:
	cd src && $(MAKE) run

install:
	cd src && $(MAKE) install

clean:
	cd src && $(MAKE) clean

modserver-git.zip:
	git archive HEAD --output $@

.PHONY: run clean modserver-git.zip
